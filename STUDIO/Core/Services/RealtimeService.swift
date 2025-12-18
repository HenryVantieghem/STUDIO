//
//  RealtimeService.swift
//  STUDIO
//
//  Created by Claude on 12/17/25.
//

import Foundation
@preconcurrency import Supabase
@preconcurrency import Realtime

// MARK: - Thread-Safe Box

/// A thread-safe box for Sendable conformance
final class SendableBox<T>: @unchecked Sendable {
    private let lock = NSLock()
    private var _value: T

    init(_ value: T) {
        self._value = value
    }

    var value: T {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _value
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _value = newValue
        }
    }

    func withLock<R>(_ body: (inout T) -> R) -> R {
        lock.lock()
        defer { lock.unlock() }
        return body(&_value)
    }
}

// MARK: - Realtime Service

/// Manages Supabase Realtime subscriptions for live updates
/// Supports all 5 realtime-enabled tables: party_comments, party_statuses, poll_votes, party_guests, notifications
final class RealtimeService: Sendable {
    static let shared = RealtimeService()

    // MARK: - Properties

    private let channels = SendableBox<[String: RealtimeChannelV2]>([:])
    private let subscriptionTasks = SendableBox<[String: Task<Void, Never>]>([:])
    private let _isConnected = SendableBox<Bool>(false)
    private let _connectionError = SendableBox<Error?>(nil)

    var isConnected: Bool {
        get { _isConnected.value }
        set { _isConnected.value = newValue }
    }

    var connectionError: Error? {
        get { _connectionError.value }
        set { _connectionError.value = newValue }
    }

    private init() {}

    // MARK: - Party Subscriptions

    /// Subscribe to all party activity (comments, statuses, polls, guests)
    func subscribeToParty(
        _ partyId: UUID,
        onComment: @escaping @Sendable (PartyComment, ChangeAction) -> Void,
        onStatus: @escaping @Sendable (PartyStatus, ChangeAction) -> Void,
        onPollVote: @escaping @Sendable (PollVote, ChangeAction) -> Void,
        onGuestUpdate: @escaping @Sendable (PartyGuest, ChangeAction) -> Void
    ) async {
        let channelKey = "party:\(partyId.uuidString)"

        // Unsubscribe if already subscribed
        await unsubscribeFromParty(partyId)

        do {
            let channel = supabase.realtimeV2.channel(channelKey)
            channels.withLock { $0[channelKey] = channel }

            // Subscribe to party_comments
            let commentsChanges = await channel.postgresChange(
                AnyAction.self,
                schema: "public",
                table: "party_comments",
                filter: "party_id=eq.\(partyId.uuidString)"
            )

            // Subscribe to party_statuses
            let statusChanges = await channel.postgresChange(
                AnyAction.self,
                schema: "public",
                table: "party_statuses",
                filter: "party_id=eq.\(partyId.uuidString)"
            )

            // Subscribe to poll_votes (need to join through polls for this party)
            let pollVoteChanges = await channel.postgresChange(
                AnyAction.self,
                schema: "public",
                table: "poll_votes"
            )

            // Subscribe to party_guests
            let guestChanges = await channel.postgresChange(
                AnyAction.self,
                schema: "public",
                table: "party_guests",
                filter: "party_id=eq.\(partyId.uuidString)"
            )

            await channel.subscribe()
            isConnected = true
            connectionError = nil

            // Process comments stream
            let commentsTask = Task { @Sendable in
                for await change in commentsChanges {
                    if let (record, action) = Self.decodeChange(change, as: PartyComment.self) {
                        onComment(record, action)
                    }
                }
            }

            // Process status stream
            let statusTask = Task { @Sendable in
                for await change in statusChanges {
                    if let (record, action) = Self.decodeChange(change, as: PartyStatus.self) {
                        onStatus(record, action)
                    }
                }
            }

            // Process poll votes stream
            let pollVotesTask = Task { @Sendable in
                for await change in pollVoteChanges {
                    if let (record, action) = Self.decodeChange(change, as: PollVote.self) {
                        onPollVote(record, action)
                    }
                }
            }

            // Process guest updates stream
            let guestsTask = Task { @Sendable in
                for await change in guestChanges {
                    if let (record, action) = Self.decodeChange(change, as: PartyGuest.self) {
                        onGuestUpdate(record, action)
                    }
                }
            }

            // Store tasks for cleanup
            subscriptionTasks.withLock {
                $0["\(channelKey):comments"] = commentsTask
                $0["\(channelKey):statuses"] = statusTask
                $0["\(channelKey):votes"] = pollVotesTask
                $0["\(channelKey):guests"] = guestsTask
            }

        } catch {
            connectionError = error
            isConnected = false
        }
    }

    /// Unsubscribe from party activity
    func unsubscribeFromParty(_ partyId: UUID) async {
        let channelKey = "party:\(partyId.uuidString)"

        // Cancel all subscription tasks
        subscriptionTasks.withLock {
            $0["\(channelKey):comments"]?.cancel()
            $0["\(channelKey):statuses"]?.cancel()
            $0["\(channelKey):votes"]?.cancel()
            $0["\(channelKey):guests"]?.cancel()
            $0.removeValue(forKey: "\(channelKey):comments")
            $0.removeValue(forKey: "\(channelKey):statuses")
            $0.removeValue(forKey: "\(channelKey):votes")
            $0.removeValue(forKey: "\(channelKey):guests")
        }

        // Unsubscribe and remove channel
        let channel = channels.withLock { $0.removeValue(forKey: channelKey) }
        if let channel = channel {
            await channel.unsubscribe()
        }
    }

    // MARK: - Notifications Subscription

    /// Subscribe to user notifications
    func subscribeToNotifications(
        _ userId: UUID,
        onNotification: @escaping @Sendable (AppNotification, ChangeAction) -> Void
    ) async {
        let channelKey = "notifications:\(userId.uuidString)"

        // Unsubscribe if already subscribed
        await unsubscribeFromNotifications(userId)

        do {
            let channel = supabase.realtimeV2.channel(channelKey)
            channels.withLock { $0[channelKey] = channel }

            let notificationChanges = await channel.postgresChange(
                AnyAction.self,
                schema: "public",
                table: "notifications",
                filter: "user_id=eq.\(userId.uuidString)"
            )

            await channel.subscribe()

            let task = Task { @Sendable in
                for await change in notificationChanges {
                    if let (record, action) = Self.decodeChange(change, as: AppNotification.self) {
                        onNotification(record, action)
                    }
                }
            }

            subscriptionTasks.withLock { $0[channelKey] = task }

        } catch {
            connectionError = error
        }
    }

    /// Unsubscribe from user notifications
    func unsubscribeFromNotifications(_ userId: UUID) async {
        let channelKey = "notifications:\(userId.uuidString)"

        subscriptionTasks.withLock {
            $0[channelKey]?.cancel()
            $0.removeValue(forKey: channelKey)
        }

        let channel = channels.withLock { $0.removeValue(forKey: channelKey) }
        if let channel = channel {
            await channel.unsubscribe()
        }
    }

    // MARK: - Cleanup

    /// Unsubscribe from all channels
    func unsubscribeAll() async {
        let tasks = subscriptionTasks.withLock { tasks in
            let values = Array(tasks.values)
            tasks.removeAll()
            return values
        }
        for task in tasks {
            task.cancel()
        }

        let allChannels = channels.withLock { chs in
            let values = Array(chs.values)
            chs.removeAll()
            return values
        }
        for channel in allChannels {
            await channel.unsubscribe()
        }

        isConnected = false
    }

    // MARK: - Private Helpers

    /// Decode a change event and return the record with action type
    private static func decodeChange<T: Decodable>(
        _ change: AnyAction,
        as type: T.Type
    ) -> (T, ChangeAction)? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        switch change {
        case .insert(let action):
            if let data = try? JSONSerialization.data(withJSONObject: action.record),
               let record = try? decoder.decode(T.self, from: data) {
                return (record, .insert)
            }

        case .update(let action):
            if let data = try? JSONSerialization.data(withJSONObject: action.record),
               let record = try? decoder.decode(T.self, from: data) {
                return (record, .update)
            }

        case .delete(let action):
            if let data = try? JSONSerialization.data(withJSONObject: action.oldRecord),
               let record = try? decoder.decode(T.self, from: data) {
                return (record, .delete)
            }
        }
        return nil
    }
}

// MARK: - Change Action

/// Type of database change
enum ChangeAction: String, Sendable {
    case insert
    case update
    case delete
}

// MARK: - Note: AppNotification and NotificationData models are defined in User.swift

// MARK: - Convenience Extensions

extension RealtimeService {
    /// Check if subscribed to a specific party
    func isSubscribedToParty(_ partyId: UUID) -> Bool {
        channels.value["party:\(partyId.uuidString)"] != nil
    }

    /// Check if subscribed to user notifications
    func isSubscribedToNotifications(_ userId: UUID) -> Bool {
        channels.value["notifications:\(userId.uuidString)"] != nil
    }

    /// Get count of active subscriptions
    var activeSubscriptionCount: Int {
        channels.value.count
    }
}
