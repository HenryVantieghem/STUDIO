//
//  HapticManager.swift
//  STUDIO
//
//  Created by Claude on 12/16/25.
//

import UIKit
import SwiftUI

// MARK: - Haptic Manager

/// Centralized haptic feedback manager for consistent tactile responses
@MainActor
final class HapticManager {
    static let shared = HapticManager()

    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let softImpact = UIImpactFeedbackGenerator(style: .soft)
    private let rigidImpact = UIImpactFeedbackGenerator(style: .rigid)
    private let selection = UISelectionFeedbackGenerator()
    private let notification = UINotificationFeedbackGenerator()

    @AppStorage("hapticsEnabled") private var hapticsEnabled = true

    private init() {
        prepareGenerators()
    }

    // MARK: - Prepare

    func prepareGenerators() {
        lightImpact.prepare()
        mediumImpact.prepare()
        heavyImpact.prepare()
        selection.prepare()
        notification.prepare()
    }

    // MARK: - Impact Feedback

    /// Light tap - for subtle interactions like toggles
    func lightTap() {
        guard hapticsEnabled else { return }
        lightImpact.impactOccurred()
    }

    /// Medium tap - for button presses
    func mediumTap() {
        guard hapticsEnabled else { return }
        mediumImpact.impactOccurred()
    }

    /// Heavy tap - for significant actions
    func heavyTap() {
        guard hapticsEnabled else { return }
        heavyImpact.impactOccurred()
    }

    /// Soft tap - for gentle feedback
    func softTap() {
        guard hapticsEnabled else { return }
        softImpact.impactOccurred()
    }

    /// Rigid tap - for firm feedback
    func rigidTap() {
        guard hapticsEnabled else { return }
        rigidImpact.impactOccurred()
    }

    // MARK: - Selection Feedback

    /// Selection changed - for pickers, sliders, segments
    func selectionChanged() {
        guard hapticsEnabled else { return }
        selection.selectionChanged()
    }

    // MARK: - Notification Feedback

    /// Success - action completed successfully
    func success() {
        guard hapticsEnabled else { return }
        notification.notificationOccurred(.success)
    }

    /// Warning - something needs attention
    func warning() {
        guard hapticsEnabled else { return }
        notification.notificationOccurred(.warning)
    }

    /// Error - something went wrong
    func error() {
        guard hapticsEnabled else { return }
        notification.notificationOccurred(.error)
    }

    // MARK: - Custom Patterns

    /// Double tap pattern
    func doubleTap() {
        guard hapticsEnabled else { return }
        lightImpact.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.lightImpact.impactOccurred()
        }
    }

    /// Party vibe pattern - celebratory haptic
    func partyVibe() {
        guard hapticsEnabled else { return }
        mediumImpact.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.lightImpact.impactOccurred()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            self?.heavyImpact.impactOccurred()
        }
    }
}

// MARK: - View Extension for Haptics

extension View {
    /// Add haptic feedback on tap
    func hapticOnTap(_ style: HapticStyle = .medium) -> some View {
        self.onTapGesture {
            switch style {
            case .light:
                HapticManager.shared.lightTap()
            case .medium:
                HapticManager.shared.mediumTap()
            case .heavy:
                HapticManager.shared.heavyTap()
            case .soft:
                HapticManager.shared.softTap()
            case .rigid:
                HapticManager.shared.rigidTap()
            case .selection:
                HapticManager.shared.selectionChanged()
            case .success:
                HapticManager.shared.success()
            case .warning:
                HapticManager.shared.warning()
            case .error:
                HapticManager.shared.error()
            }
        }
    }
}

enum HapticStyle {
    case light
    case medium
    case heavy
    case soft
    case rigid
    case selection
    case success
    case warning
    case error
}
