//
//  FollowService.swift
//  STUDIO
//
//  Service for follow operations and activity notifications
//

import Foundation
import Supabase

// MARK: - Follow Service

/// Service for follow-related operations and activity notifications
final class FollowService: Sendable {

    // MARK: - Follow Operations

    /// Follow a user
    func followUser(userId: UUID) async throws {
        let currentUserId = try await supabase.auth.session.user.id

        guard userId != currentUserId else {
            throw FollowError.cannotFollowSelf
        }

        struct FollowPayload: Encodable, Sendable {
            let follower_id: String
            let following_id: String
        }

        let payload = FollowPayload(
            follower_id: currentUserId.uuidString,
            following_id: userId.uuidString
        )

        try await supabase
            .from("follows")
            .insert(payload)
            .execute()
    }

    /// Unfollow a user
    func unfollowUser(userId: UUID) async throws {
        let currentUserId = try await supabase.auth.session.user.id

        try await supabase
            .from("follows")
            .delete()
            .eq("follower_id", value: currentUserId.uuidString)
            .eq("following_id", value: userId.uuidString)
            .execute()
    }

    /// Check if current user is following a user
    func isFollowing(userId: UUID) async throws -> Bool {
        let currentUserId = try await supabase.auth.session.user.id

        let follows: [Follow] = try await supabase
            .from("follows")
            .select()
            .eq("follower_id", value: currentUserId.uuidString)
            .eq("following_id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value

        return !follows.isEmpty
    }

    /// Check if a user is following the current user
    func isFollowedBy(userId: UUID) async throws -> Bool {
        let currentUserId = try await supabase.auth.session.user.id

        let follows: [Follow] = try await supabase
            .from("follows")
            .select()
            .eq("follower_id", value: userId.uuidString)
            .eq("following_id", value: currentUserId.uuidString)
            .limit(1)
            .execute()
            .value

        return !follows.isEmpty
    }

    // MARK: - Activity Notifications

    /// Get follow notifications for the current user
    func getFollowNotifications(limit: Int = 50, offset: Int = 0) async throws -> [AppNotification] {
        let userId = try await supabase.auth.session.user.id

        let notifications: [AppNotification] = try await supabase
            .from("notifications")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("type", value: "follow")
            .order("created_at", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()
            .value

        return notifications
    }

    /// Get all activity notifications for the current user
    func getAllNotifications(limit: Int = 50, offset: Int = 0) async throws -> [AppNotification] {
        let userId = try await supabase.auth.session.user.id

        let notifications: [AppNotification] = try await supabase
            .from("notifications")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()
            .value

        return notifications
    }

    /// Get unread notifications count
    func getUnreadCount() async throws -> Int {
        let userId = try await supabase.auth.session.user.id

        let notifications: [AppNotification] = try await supabase
            .from("notifications")
            .select("id")
            .eq("user_id", value: userId.uuidString)
            .eq("read", value: false)
            .execute()
            .value

        return notifications.count
    }

    /// Mark notification as read
    func markAsRead(notificationId: UUID) async throws {
        try await supabase
            .from("notifications")
            .update(["read": true])
            .eq("id", value: notificationId.uuidString)
            .execute()
    }

    /// Mark all notifications as read
    func markAllAsRead() async throws {
        let userId = try await supabase.auth.session.user.id

        try await supabase
            .from("notifications")
            .update(["read": true])
            .eq("user_id", value: userId.uuidString)
            .eq("read", value: false)
            .execute()
    }

    // MARK: - Search Users

    /// Search users by username or display name
    func searchUsers(query: String, limit: Int = 30) async throws -> [UserSearchResult] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }

        let currentUserId = try await supabase.auth.session.user.id
        let searchTerm = query.lowercased()

        let users: [User] = try await supabase
            .from("profiles")
            .select()
            .or("username.ilike.%\(searchTerm)%,display_name.ilike.%\(searchTerm)%")
            .neq("id", value: currentUserId.uuidString)
            .limit(limit)
            .execute()
            .value

        // Get follow status for each user
        var results: [UserSearchResult] = []
        for user in users {
            let isFollowing = try await isFollowing(userId: user.id)
            results.append(UserSearchResult(user: user, isFollowing: isFollowing))
        }

        return results
    }

    /// Get suggested users to follow
    func getSuggestedUsers(limit: Int = 10) async throws -> [UserSearchResult] {
        let currentUserId = try await supabase.auth.session.user.id

        // Get users the current user is already following
        let following: [Follow] = try await supabase
            .from("follows")
            .select("following_id")
            .eq("follower_id", value: currentUserId.uuidString)
            .execute()
            .value

        let followingIds = following.map { $0.followingId.uuidString }

        // Get users not already followed, ordered by follower count (popularity)
        let users: [User] = try await supabase
            .from("profiles")
            .select()
            .neq("id", value: currentUserId.uuidString)
            .limit(limit + followingIds.count) // Get extra to filter
            .execute()
            .value

        // Filter out already followed users and map to results
        let filteredUsers = users.filter { !followingIds.contains($0.id.uuidString) }.prefix(limit)
        return filteredUsers.map { UserSearchResult(user: $0, isFollowing: false) }
    }

    // MARK: - Privacy

    /// Update profile privacy setting
    func updatePrivacy(isPrivate: Bool) async throws {
        let userId = try await supabase.auth.session.user.id

        try await supabase
            .from("profiles")
            .update(["is_private": isPrivate])
            .eq("id", value: userId.uuidString)
            .execute()
    }
}

// MARK: - Follow Error

enum FollowError: LocalizedError {
    case cannotFollowSelf
    case alreadyFollowing
    case notFollowing
    case userNotFound

    var errorDescription: String? {
        switch self {
        case .cannotFollowSelf:
            return "You cannot follow yourself"
        case .alreadyFollowing:
            return "You are already following this user"
        case .notFollowing:
            return "You are not following this user"
        case .userNotFound:
            return "User not found"
        }
    }
}

// MARK: - User Search Result

struct UserSearchResult: Identifiable, Sendable, Hashable {
    let user: User
    var isFollowing: Bool

    var id: UUID { user.id }
}
