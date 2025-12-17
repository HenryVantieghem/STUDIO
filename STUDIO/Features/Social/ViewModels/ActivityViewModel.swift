//
//  ActivityViewModel.swift
//  STUDIO
//
//  Activity/notifications state management with @Observable
//

import Foundation
import SwiftUI

// MARK: - Activity View Model

@Observable
@MainActor
final class ActivityViewModel {
    // MARK: - State

    var notifications: [AppNotification] = []
    var isLoading = false
    var isRefreshing = false
    var error: Error?
    var showError = false
    var unreadCount = 0

    // MARK: - Services

    private let followService = FollowService()
    private let profileService = ProfileService()

    // MARK: - Cache for follow states

    private var followStates: [UUID: Bool] = [:]
    private var loadingFollowStates: Set<UUID> = []

    // MARK: - Load Notifications

    func loadNotifications() async {
        guard !isLoading else { return }
        isLoading = true
        error = nil

        do {
            notifications = try await followService.getAllNotifications(limit: 50)
            unreadCount = try await followService.getUnreadCount()
        } catch {
            self.error = error
            showError = true
        }

        isLoading = false
    }

    func refresh() async {
        isRefreshing = true
        await loadNotifications()
        isRefreshing = false
    }

    // MARK: - Mark as Read

    func markAsRead(_ notification: AppNotification) async {
        guard !notification.read else { return }

        do {
            try await followService.markAsRead(notificationId: notification.id)

            // Update local state
            if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
                var updated = notifications[index]
                updated.read = true
                notifications[index] = updated
            }
            unreadCount = max(0, unreadCount - 1)
        } catch {
            // Silently fail
        }
    }

    func markAllAsRead() async {
        do {
            try await followService.markAllAsRead()

            // Update local state
            notifications = notifications.map { notification in
                var updated = notification
                updated.read = true
                return updated
            }
            unreadCount = 0
        } catch {
            self.error = error
            showError = true
        }
    }

    // MARK: - Follow Actions

    func isFollowing(userId: UUID) -> Bool {
        followStates[userId] ?? false
    }

    func isLoadingFollow(userId: UUID) -> Bool {
        loadingFollowStates.contains(userId)
    }

    func checkFollowStatus(userId: UUID) async {
        do {
            let isFollowing = try await followService.isFollowing(userId: userId)
            followStates[userId] = isFollowing
        } catch {
            // Silently fail
        }
    }

    func toggleFollow(userId: UUID) async {
        guard !loadingFollowStates.contains(userId) else { return }
        loadingFollowStates.insert(userId)

        do {
            let currentlyFollowing = followStates[userId] ?? false

            if currentlyFollowing {
                try await followService.unfollowUser(userId: userId)
                followStates[userId] = false
            } else {
                try await followService.followUser(userId: userId)
                followStates[userId] = true
            }
        } catch {
            self.error = error
            showError = true
        }

        loadingFollowStates.remove(userId)
    }

    // MARK: - Computed

    var followNotifications: [AppNotification] {
        notifications.filter { $0.type == .follow }
    }

    var hasUnread: Bool {
        unreadCount > 0
    }
}
