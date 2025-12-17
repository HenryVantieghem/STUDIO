//
//  RealtimeManager.swift
//  STUDIO
//
//  Real-time updates using Supabase Realtime
//  Basel Afterdark Design System
//

import Foundation
import Supabase
import Combine

// MARK: - Realtime Manager

/// Manages real-time subscriptions for live party updates
@Observable
@MainActor
final class RealtimeManager {

    // MARK: - Singleton

    static let shared = RealtimeManager()

    // MARK: - State

    private(set) var isConnected = false
    private var activeChannels: [String: RealtimeChannelV2] = [:]
    private var partySubscriptions: Set<UUID> = []

    // MARK: - Callbacks

    var onNewComment: ((PartyComment) -> Void)?
    var onNewStatus: ((PartyStatus) -> Void)?
    var onNewMedia: ((PartyMedia) -> Void)?
    var onGuestUpdate: ((PartyGuest) -> Void)?
    var onPollVote: ((PollVote) -> Void)?
    var onNewNotification: ((AppNotification) -> Void)?

    // MARK: - Initialization

    private init() {}

    // MARK: - Party Subscription

    /// Subscribe to real-time updates for a party
    func subscribeToParty(_ partyId: UUID) async {
        guard !partySubscriptions.contains(partyId) else { return }

        let channelName = "party:\(partyId.uuidString)"

        // Create channel
        let channel = await supabase.realtimeV2.channel(channelName)

        // Subscribe to comments
        let commentsStream = await channel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "party_comments",
            filter: "party_id=eq.\(partyId.uuidString)"
        )

        // Subscribe to statuses
        let statusesStream = await channel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "party_statuses",
            filter: "party_id=eq.\(partyId.uuidString)"
        )

        // Subscribe to media
        let mediaStream = await channel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "party_media",
            filter: "party_id=eq.\(partyId.uuidString)"
        )

        // Subscribe to guest updates
        let guestsStream = await channel.postgresChange(
            AnyAction.self,
            schema: "public",
            table: "party_guests",
            filter: "party_id=eq.\(partyId.uuidString)"
        )

        // Subscribe to poll votes
        let votesStream = await channel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "poll_votes"
        )

        // Handle streams
        Task {
            for await action in commentsStream {
                if let comment = try? action.decodeRecord(as: PartyComment.self, decoder: JSONDecoder()) {
                    await MainActor.run {
                        self.onNewComment?(comment)
                        CacheManager.shared.appendComment(comment, for: partyId)
                        HapticManager.shared.impact(.light)
                    }
                }
            }
        }

        Task {
            for await action in statusesStream {
                if let status = try? action.decodeRecord(as: PartyStatus.self, decoder: JSONDecoder()) {
                    await MainActor.run {
                        self.onNewStatus?(status)
                    }
                }
            }
        }

        Task {
            for await action in mediaStream {
                if let media = try? action.decodeRecord(as: PartyMedia.self, decoder: JSONDecoder()) {
                    await MainActor.run {
                        self.onNewMedia?(media)
                        CacheManager.shared.appendMedia(media, for: partyId)
                    }
                }
            }
        }

        Task {
            for await action in guestsStream {
                if let guest = try? action.decodeRecord(as: PartyGuest.self, decoder: JSONDecoder()) {
                    await MainActor.run {
                        self.onGuestUpdate?(guest)
                    }
                }
            }
        }

        Task {
            for await action in votesStream {
                if let vote = try? action.decodeRecord(as: PollVote.self, decoder: JSONDecoder()) {
                    await MainActor.run {
                        self.onPollVote?(vote)
                    }
                }
            }
        }

        // Subscribe to channel
        await channel.subscribe()

        activeChannels[channelName] = channel
        partySubscriptions.insert(partyId)
        isConnected = true

        print("📡 Subscribed to party: \(partyId)")
    }

    /// Unsubscribe from party updates
    func unsubscribeFromParty(_ partyId: UUID) async {
        let channelName = "party:\(partyId.uuidString)"

        if let channel = activeChannels[channelName] {
            await channel.unsubscribe()
            activeChannels[channelName] = nil
        }

        partySubscriptions.remove(partyId)

        if activeChannels.isEmpty {
            isConnected = false
        }

        print("📡 Unsubscribed from party: \(partyId)")
    }

    // MARK: - Notifications Subscription

    /// Subscribe to user notifications
    func subscribeToNotifications(userId: UUID) async {
        let channelName = "notifications:\(userId.uuidString)"

        let channel = await supabase.realtimeV2.channel(channelName)

        let notificationsStream = await channel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "notifications",
            filter: "user_id=eq.\(userId.uuidString)"
        )

        Task {
            for await action in notificationsStream {
                if let notification = try? action.decodeRecord(as: AppNotification.self, decoder: JSONDecoder()) {
                    await MainActor.run {
                        self.onNewNotification?(notification)
                        HapticManager.shared.notification(.success)
                    }
                }
            }
        }

        await channel.subscribe()
        activeChannels[channelName] = channel

        print("📡 Subscribed to notifications for user: \(userId)")
    }

    // MARK: - Cleanup

    /// Unsubscribe from all channels
    func unsubscribeAll() async {
        for (name, channel) in activeChannels {
            await channel.unsubscribe()
            print("📡 Unsubscribed from: \(name)")
        }

        activeChannels.removeAll()
        partySubscriptions.removeAll()
        isConnected = false
    }

    /// Check if subscribed to a party
    func isSubscribed(to partyId: UUID) -> Bool {
        partySubscriptions.contains(partyId)
    }
}

// MARK: - Presence Manager

/// Tracks who's currently online/active at a party
@Observable
@MainActor
final class PresenceManager {

    static let shared = PresenceManager()

    private(set) var onlineUsers: [UUID: [PresenceUser]] = [:]  // partyId -> users
    private var presenceChannels: [UUID: RealtimeChannelV2] = [:]

    private init() {}

    struct PresenceUser: Codable, Hashable {
        let id: UUID
        let username: String
        let avatarUrl: String?
        let joinedAt: Date
    }

    /// Join party presence
    func joinParty(_ partyId: UUID, user: User) async {
        let channelName = "presence:\(partyId.uuidString)"

        let channel = await supabase.realtimeV2.channel(channelName)

        // Track presence
        await channel.track([
            "user_id": user.id.uuidString,
            "username": user.username,
            "avatar_url": user.avatarUrl ?? "",
            "joined_at": ISO8601DateFormatter().string(from: Date())
        ])

        await channel.subscribe()
        presenceChannels[partyId] = channel

        // Initialize online users
        onlineUsers[partyId] = []

        print("👋 Joined presence for party: \(partyId)")
    }

    /// Leave party presence
    func leaveParty(_ partyId: UUID) async {
        if let channel = presenceChannels[partyId] {
            await channel.untrack()
            await channel.unsubscribe()
            presenceChannels[partyId] = nil
        }

        onlineUsers[partyId] = nil

        print("👋 Left presence for party: \(partyId)")
    }

    /// Get online count for a party
    func onlineCount(for partyId: UUID) -> Int {
        onlineUsers[partyId]?.count ?? 0
    }
}

// MARK: - Typing Indicator Manager

/// Shows who's typing in party chat
@Observable
@MainActor
final class TypingIndicatorManager {

    static let shared = TypingIndicatorManager()

    private(set) var typingUsers: [UUID: [TypingUser]] = [:]  // partyId -> users
    private var broadcastChannels: [UUID: RealtimeChannelV2] = [:]

    private init() {}

    struct TypingUser: Codable, Hashable {
        let id: UUID
        let username: String
        let startedAt: Date
    }

    /// Start typing indicator
    func startTyping(partyId: UUID, user: User) async {
        let channelName = "typing:\(partyId.uuidString)"

        var channel = broadcastChannels[partyId]

        if channel == nil {
            channel = await supabase.realtimeV2.channel(channelName)
            await channel?.subscribe()
            broadcastChannels[partyId] = channel
        }

        await channel?.broadcast(
            event: "typing",
            message: [
                "user_id": user.id.uuidString,
                "username": user.username,
                "started_at": ISO8601DateFormatter().string(from: Date())
            ]
        )
    }

    /// Stop typing indicator
    func stopTyping(partyId: UUID, userId: UUID) async {
        if let channel = broadcastChannels[partyId] {
            await channel.broadcast(
                event: "stopped_typing",
                message: ["user_id": userId.uuidString]
            )
        }
    }
}

// MARK: - Connection Status View

/// Shows real-time connection status
struct ConnectionStatusView: View {
    @State private var realtimeManager = RealtimeManager.shared

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(realtimeManager.isConnected ? Color.green : Color.studioMuted)
                .frame(width: 8, height: 8)

            Text(realtimeManager.isConnected ? "LIVE" : "OFFLINE")
                .font(StudioTypography.labelSmall)
                .tracking(StudioTypography.trackingNormal)
                .foregroundStyle(realtimeManager.isConnected ? Color.studioPrimary : Color.studioMuted)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.studioSurface)
        .overlay {
            Rectangle()
                .stroke(realtimeManager.isConnected ? Color.green.opacity(0.5) : Color.studioLine, lineWidth: 1)
        }
    }
}

// MARK: - Online Users Badge

struct OnlineUsersBadge: View {
    let partyId: UUID
    @State private var presenceManager = PresenceManager.shared

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color.green)
                .frame(width: 6, height: 6)

            Text("\(presenceManager.onlineCount(for: partyId)) ONLINE")
                .font(StudioTypography.labelSmall)
                .foregroundStyle(Color.studioMuted)
        }
    }
}

// MARK: - Preview

#Preview("Connection Status") {
    ConnectionStatusView()
        .padding()
        .background(Color.studioBlack)
}
