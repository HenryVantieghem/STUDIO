//
//  RealtimeService.swift
//  STUDIO
//
//  Created by Claude on 12/17/25.
//

import Foundation
import Supabase
import Realtime

// MARK: - Realtime Service

/// Manages Supabase Realtime subscriptions for live updates
/// Supports all 5 realtime-enabled tables: party_comments, party_statuses, poll_votes, party_guests, notifications
@Observable
@MainActor
final class RealtimeService {
    static let shared = RealtimeService()

    // MARK: - Properties

    private var channels: [String: RealtimeChannelV2] = [:]
    private var subscriptionTasks: [String: Task<Void, Never>] = [:]

    var isConnected = false
    var connectionError: Error?

    private init() {}

    // MARK: - Party Subscriptions

    /// Subscribe to all party activity (comments, statuses, polls, guests)
    func subscribeToParty(
        _ partyId: UUID,
        onComment: @escaping (PartyComment, ChangeAction) -> Void,
        onStatus: @escaping (PartyStatus, ChangeAction) -> Void,
        onPollVote: @escaping (PollVote, ChangeAction) -> Void,
        onGuestUpdate: @escaping (PartyGuest, ChangeAction) -> Void
    ) async {
        let channelKey = "party:\(partyId.uuidString)"

        // Unsubscribe if already subscribed
        await unsubscribeFromParty(partyId)

        do {
            let channel = supabase.realtimeV2.channel(channelKey)
            channels[channelKey] = channel

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
            let commentsTask = Task {
                for await change in commentsChanges {
                    await processChange(change, handler: onComment)
                }
            }

            // Process status stream
            let statusTask = Task {
                for await change in statusChanges {
                    await processChange(change, handler: onStatus)
                }
            }

            // Process poll votes stream
            let pollVotesTask = Task {
                for await change in pollVoteChanges {
                    await processChange(change, handler: onPollVote)
                }
            }

            // Process guest updates stream
            let guestsTask = Task {
                for await change in guestChanges {
                    await processChange(change, handler: onGuestUpdate)
                }
            }

            // Store tasks for cleanup
            subscriptionTasks["\(channelKey):comments"] = commentsTask
            subscriptionTasks["\(channelKey):statuses"] = statusTask
            subscriptionTasks["\(channelKey):votes"] = pollVotesTask
            subscriptionTasks["\(channelKey):guests"] = guestsTask

        } catch {
            connectionError = error
            isConnected = false
        }
    }

    /// Unsubscribe from party activity
    func unsubscribeFromParty(_ partyId: UUID) async {
        let channelKey = "party:\(partyId.uuidString)"

        // Cancel all subscription tasks
        subscriptionTasks["\(channelKey):comments"]?.cancel()
        subscriptionTasks["\(channelKey):statuses"]?.cancel()
        subscriptionTasks["\(channelKey):votes"]?.cancel()
        subscriptionTasks["\(channelKey):guests"]?.cancel()

        subscriptionTasks.removeValue(forKey: "\(channelKey):comments")
        subscriptionTasks.removeValue(forKey: "\(channelKey):statuses")
        subscriptionTasks.removeValue(forKey: "\(channelKey):votes")
        subscriptionTasks.removeValue(forKey: "\(channelKey):guests")

        // Unsubscribe and remove channel
        if let channel = channels[channelKey] {
            await channel.unsubscribe()
            channels.removeValue(forKey: channelKey)
        }
    }

    // MARK: - Notifications Subscription

    /// Subscribe to user notifications
    func subscribeToNotifications(
        _ userId: UUID,
        onNotification: @escaping (AppNotification, ChangeAction) -> Void
    ) async {
        let channelKey = "notifications:\(userId.uuidString)"

        // Unsubscribe if already subscribed
        await unsubscribeFromNotifications(userId)

        do {
            let channel = supabase.realtimeV2.channel(channelKey)
            channels[channelKey] = channel

            let notificationChanges = await channel.postgresChange(
                AnyAction.self,
                schema: "public",
                table: "notifications",
                filter: "user_id=eq.\(userId.uuidString)"
            )

            await channel.subscribe()

            let task = Task {
                for await change in notificationChanges {
                    await processChange(change, handler: onNotification)
                }
            }

            subscriptionTasks[channelKey] = task

        } catch {
            connectionError = error
        }
    }

    /// Unsubscribe from user notifications
    func unsubscribeFromNotifications(_ userId: UUID) async {
        let channelKey = "notifications:\(userId.uuidString)"

        subscriptionTasks[channelKey]?.cancel()
        subscriptionTasks.removeValue(forKey: channelKey)

        if let channel = channels[channelKey] {
            await channel.unsubscribe()
            channels.removeValue(forKey: channelKey)
        }
    }

    // MARK: - Cleanup

    /// Unsubscribe from all channels
    func unsubscribeAll() async {
        for task in subscriptionTasks.values {
            task.cancel()
        }
        subscriptionTasks.removeAll()

        for channel in channels.values {
            await channel.unsubscribe()
        }
        channels.removeAll()

        isConnected = false
    }

    // MARK: - Private Helpers

    /// Process a change event and decode the record
    private func processChange<T: Decodable & Sendable>(
        _ change: AnyAction,
        handler: @escaping (T, ChangeAction) -> Void
    ) async {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        do {
            switch change {
            case .insert(let action):
                if let data = try? JSONSerialization.data(withJSONObject: action.record),
                   let record = try? decoder.decode(T.self, from: data) {
                    handler(record, .insert)
                }

            case .update(let action):
                if let data = try? JSONSerialization.data(withJSONObject: action.record),
                   let record = try? decoder.decode(T.self, from: data) {
                    handler(record, .update)
                }

            case .delete(let action):
                if let data = try? JSONSerialization.data(withJSONObject: action.oldRecord),
                   let record = try? decoder.decode(T.self, from: data) {
                    handler(record, .delete)
                }

            case .select:
                // Initial data load - typically not used
                break
            }
        }
    }
}

// MARK: - Change Action

/// Type of database change
enum ChangeAction: String, Sendable {
    case insert
    case update
    case delete
}

// MARK: - App Notification Model

/// Notification model for realtime updates
struct AppNotification: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let userId: UUID
    let type: NotificationType
    let title: String
    let body: String?
    let data: NotificationData?
    let isRead: Bool
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case type
        case title
        case body
        case data
        case isRead = "is_read"
        case createdAt = "created_at"
    }
}

/// Notification types
enum NotificationType: String, Codable, Sendable {
    case partyInvite = "party_invite"
    case partyUpdate = "party_update"
    case partyReminder = "party_reminder"
    case newComment = "new_comment"
    case newPoll = "new_poll"
    case pollEnded = "poll_ended"
    case newFollower = "new_follower"
    case mention = "mention"
    case system = "system"
}

/// Notification data payload
struct NotificationData: Codable, Hashable, Sendable {
    let partyId: UUID?
    let commentId: UUID?
    let pollId: UUID?
    let fromUserId: UUID?

    enum CodingKeys: String, CodingKey {
        case partyId = "party_id"
        case commentId = "comment_id"
        case pollId = "poll_id"
        case fromUserId = "from_user_id"
    }
}

// MARK: - Convenience Extensions

extension RealtimeService {
    /// Check if subscribed to a specific party
    func isSubscribedToParty(_ partyId: UUID) -> Bool {
        channels["party:\(partyId.uuidString)"] != nil
    }

    /// Check if subscribed to user notifications
    func isSubscribedToNotifications(_ userId: UUID) -> Bool {
        channels["notifications:\(userId.uuidString)"] != nil
    }

    /// Get count of active subscriptions
    var activeSubscriptionCount: Int {
        channels.count
    }
}
