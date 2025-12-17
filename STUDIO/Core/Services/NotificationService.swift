//
//  NotificationService.swift
//  STUDIO
//
//  Created by Claude on 12/16/25.
//

import Foundation
import UserNotifications
import UIKit
import Supabase

// MARK: - Notification Service

/// Service for managing push notifications
@MainActor
@Observable
final class NotificationService {
    static let shared = NotificationService()

    private let center = UNUserNotificationCenter.current()

    private(set) var isAuthorized = false
    private(set) var deviceToken: String?

    private init() { }

    // MARK: - Authorization

    /// Request notification permissions
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            isAuthorized = granted

            if granted {
                await registerForRemoteNotifications()
            }

            return granted
        } catch {
            log.error(error, category: .auth, context: ["operation": "notification_authorization"])
            return false
        }
    }

    /// Check current authorization status
    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
        return settings.authorizationStatus
    }

    /// Register for remote notifications
    func registerForRemoteNotifications() async {
        await MainActor.run {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }

    // MARK: - Device Token

    /// Handle device token registration
    func handleDeviceToken(_ deviceToken: Data) async {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        self.deviceToken = token

        // Save token to Supabase
        await saveDeviceToken(token)
    }

    /// Save device token to Supabase for push notifications
    private func saveDeviceToken(_ token: String) async {
        do {
            let userId = try await supabase.auth.session.user.id

            // Upsert device token
            try await supabase
                .from("device_tokens")
                .upsert([
                    "user_id": AnyEncodable(userId),
                    "token": AnyEncodable(token),
                    "platform": AnyEncodable("ios"),
                    "updated_at": AnyEncodable(ISO8601DateFormatter().string(from: Date()))
                ])
                .execute()
        } catch {
            log.error(error, category: .network, context: ["operation": "save_device_token"])
        }
    }

    // MARK: - Local Notifications

    /// Schedule a local notification
    func scheduleLocalNotification(
        id: String,
        title: String,
        body: String,
        subtitle: String? = nil,
        badge: Int? = nil,
        sound: UNNotificationSound = .default,
        trigger: UNNotificationTrigger
    ) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = sound

        if let subtitle {
            content.subtitle = subtitle
        }

        if let badge {
            content.badge = NSNumber(value: badge)
        }

        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        do {
            try await center.add(request)
        } catch {
            log.error(error, category: .lifecycle, context: ["operation": "schedule_notification", "id": id])
        }
    }

    /// Schedule a party reminder
    func schedulePartyReminder(partyId: UUID, title: String, partyDate: Date) async {
        // Remind 1 hour before
        let triggerDate = partyDate.addingTimeInterval(-3600)
        guard triggerDate > Date() else { return }

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        await scheduleLocalNotification(
            id: "party-reminder-\(partyId.uuidString)",
            title: "Party Starting Soon! 🎉",
            body: "\(title) starts in 1 hour",
            trigger: trigger
        )
    }

    /// Cancel a scheduled notification
    func cancelNotification(id: String) {
        center.removePendingNotificationRequests(withIdentifiers: [id])
    }

    /// Cancel all party reminders
    func cancelPartyReminder(partyId: UUID) {
        cancelNotification(id: "party-reminder-\(partyId.uuidString)")
    }

    // MARK: - Badge Management

    /// Clear notification badge
    func clearBadge() async {
        do {
            try await center.setBadgeCount(0)
        } catch {
            log.error(error, category: .ui, context: ["operation": "clear_badge"])
        }
    }

    /// Set notification badge
    func setBadge(_ count: Int) async {
        do {
            try await center.setBadgeCount(count)
        } catch {
            log.error(error, category: .ui, context: ["operation": "set_badge", "count": count])
        }
    }

    // MARK: - Notification Categories

    /// Setup notification categories for interactive notifications
    func setupNotificationCategories() {
        // Party invitation actions
        let acceptAction = UNNotificationAction(
            identifier: "ACCEPT_INVITE",
            title: "Accept",
            options: [.foreground]
        )
        let declineAction = UNNotificationAction(
            identifier: "DECLINE_INVITE",
            title: "Decline",
            options: [.destructive]
        )
        let inviteCategory = UNNotificationCategory(
            identifier: "PARTY_INVITE",
            actions: [acceptAction, declineAction],
            intentIdentifiers: []
        )

        // Poll actions
        let voteAction = UNNotificationAction(
            identifier: "VOTE_NOW",
            title: "Vote Now",
            options: [.foreground]
        )
        let pollCategory = UNNotificationCategory(
            identifier: "NEW_POLL",
            actions: [voteAction],
            intentIdentifiers: []
        )

        // Status update actions
        let viewStatusAction = UNNotificationAction(
            identifier: "VIEW_STATUS",
            title: "View",
            options: [.foreground]
        )
        let statusCategory = UNNotificationCategory(
            identifier: "STATUS_UPDATE",
            actions: [viewStatusAction],
            intentIdentifiers: []
        )

        center.setNotificationCategories([inviteCategory, pollCategory, statusCategory])
    }
}

// MARK: - Notification Types

enum NotificationType: String, Codable {
    case partyInvite = "party_invite"
    case partyReminder = "party_reminder"
    case newPoll = "new_poll"
    case pollEnded = "poll_ended"
    case statusUpdate = "status_update"
    case newComment = "new_comment"
    case newMedia = "new_media"
    case guestJoined = "guest_joined"
}

// MARK: - Push Notification Payload

struct PushNotificationPayload: Codable {
    let type: NotificationType
    let title: String
    let body: String
    let partyId: UUID?
    let userId: UUID?
    let data: [String: String]?

    enum CodingKeys: String, CodingKey {
        case type
        case title
        case body
        case partyId = "party_id"
        case userId = "user_id"
        case data
    }
}
