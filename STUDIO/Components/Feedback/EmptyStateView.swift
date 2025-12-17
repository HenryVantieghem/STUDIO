//
//  EmptyStateView.swift
//  STUDIO
//
//  Pixel Afterdark Empty States
//  8-bit retro messaging with pixel icons
//  ✨ With entrance animations and Dynamic Type
//

import SwiftUI

// MARK: - Pixel Font Reference

private let pixelFontName = "VT323"

// MARK: - Scaled Sizes for Empty States

@MainActor
private enum EmptyStateSizes {
    @ScaledMetric(relativeTo: .title3) static var iconSize: CGFloat = 40
    @ScaledMetric(relativeTo: .title3) static var titleSize: CGFloat = 20
    @ScaledMetric(relativeTo: .body) static var messageSize: CGFloat = 14
}

// MARK: - Empty State View

/// Reusable empty state component with pixel aesthetic
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    // Animation states
    @State private var iconVisible = false
    @State private var textVisible = false
    @State private var buttonVisible = false
    @State private var iconPulse = false

    var body: some View {
        VStack(spacing: 24) {
            // Icon - thin, minimal with entrance animation
            Image(systemName: icon)
                .font(.system(size: EmptyStateSizes.iconSize, weight: .ultraLight))
                .foregroundStyle(Color.studioMuted)
                .opacity(iconVisible ? 1 : 0)
                .scaleEffect(iconVisible ? 1 : 0.8)
                .scaleEffect(iconPulse ? 1.05 : 1.0)

            // Text - centered, pixel font
            VStack(spacing: 14) {
                Text(title.uppercased())
                    .font(.custom(pixelFontName, size: EmptyStateSizes.titleSize))
                    .tracking(StudioTypography.trackingWide)
                    .foregroundStyle(Color.studioPrimary)

                Text(message)
                    .font(.custom(pixelFontName, size: EmptyStateSizes.messageSize))
                    .tracking(StudioTypography.trackingNormal)
                    .foregroundStyle(Color.studioMuted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .opacity(textVisible ? 1 : 0)
            .offset(y: textVisible ? 0 : 10)

            // Action Button
            if let actionTitle, let action {
                Button(actionTitle.uppercased(), action: action)
                    .buttonStyle(.studioSecondary)
                    .frame(width: 180)
                    .opacity(buttonVisible ? 1 : 0)
                    .offset(y: buttonVisible ? 0 : 10)
            }
        }
        .padding(32)
        .onAppear {
            // Staggered entrance animation
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                iconVisible = true
            }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.1)) {
                textVisible = true
            }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.2)) {
                buttonVisible = true
            }
            // Subtle breathing animation on icon
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true).delay(0.5)) {
                iconPulse = true
            }
        }
    }
}

// MARK: - Preset Empty States

extension EmptyStateView {
    /// Empty feed state
    static var emptyFeed: EmptyStateView {
        EmptyStateView(
            icon: "sparkles",
            title: "NO EVENTS",
            message: "Create an event or wait for an invitation",
            actionTitle: "CREATE EVENT"
        )
    }

    /// Empty search results
    static var noSearchResults: EmptyStateView {
        EmptyStateView(
            icon: "magnifyingglass",
            title: "NO RESULTS",
            message: "Try adjusting your search or filters"
        )
    }

    /// Empty notifications
    static var emptyNotifications: EmptyStateView {
        EmptyStateView(
            icon: "bell",
            title: "NO NOTIFICATIONS",
            message: "You're all caught up"
        )
    }

    /// Empty media gallery
    static var emptyMedia: EmptyStateView {
        EmptyStateView(
            icon: "camera",
            title: "NO MEDIA",
            message: "Be the first to capture the moment",
            actionTitle: "ADD PHOTO"
        )
    }

    /// Empty comments
    static var emptyComments: EmptyStateView {
        EmptyStateView(
            icon: "bubble.left",
            title: "NO COMMENTS",
            message: "Start the conversation"
        )
    }

    /// Empty guest list
    static var emptyGuests: EmptyStateView {
        EmptyStateView(
            icon: "person.2",
            title: "NO GUESTS",
            message: "Invite your people to join",
            actionTitle: "INVITE"
        )
    }

    /// No internet connection
    static var noConnection: EmptyStateView {
        EmptyStateView(
            icon: "wifi.slash",
            title: "OFFLINE",
            message: "Check your connection and try again",
            actionTitle: "RETRY"
        )
    }

    /// Generic error state
    static var errorState: EmptyStateView {
        EmptyStateView(
            icon: "exclamationmark.triangle",
            title: "ERROR",
            message: "Something went wrong. Please try again.",
            actionTitle: "RETRY"
        )
    }
}

// MARK: - Error View

/// Error state with retry action
struct ErrorView: View {
    let error: Error
    var retryAction: (() async -> Void)?

    @State private var isRetrying = false
    @State private var isVisible = false
    @State private var iconShake = false

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: EmptyStateSizes.iconSize, weight: .ultraLight))
                .foregroundStyle(Color.studioError)
                .rotationEffect(.degrees(iconShake ? -5 : 5))
                .opacity(isVisible ? 1 : 0)
                .scaleEffect(isVisible ? 1 : 0.8)

            VStack(spacing: 14) {
                Text("ERROR")
                    .font(.custom(pixelFontName, size: EmptyStateSizes.titleSize))
                    .tracking(StudioTypography.trackingWide)
                    .foregroundStyle(Color.studioPrimary)

                Text(error.localizedDescription)
                    .font(.custom(pixelFontName, size: EmptyStateSizes.messageSize))
                    .tracking(StudioTypography.trackingNormal)
                    .foregroundStyle(Color.studioMuted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .opacity(isVisible ? 1 : 0)

            if let retry = retryAction {
                Button {
                    HapticManager.shared.mediumTap()
                    isRetrying = true
                    Task {
                        await retry()
                        isRetrying = false
                    }
                } label: {
                    HStack(spacing: 8) {
                        if isRetrying {
                            PixelLoadingIndicator()
                        } else {
                            Text("RETRY")
                        }
                    }
                    .frame(width: 140, height: 44)
                }
                .buttonStyle(.studioSecondary)
                .disabled(isRetrying)
                .opacity(isVisible ? 1 : 0)
            }
        }
        .padding(32)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                isVisible = true
            }
            // Subtle shake animation on error icon
            withAnimation(.easeInOut(duration: 0.15).repeatCount(3, autoreverses: true).delay(0.3)) {
                iconShake = true
            }
            // Haptic feedback for error
            HapticManager.shared.error()
        }
    }
}

// MARK: - Preview

#Preview("Pixel Empty States") {
    ScrollView {
        VStack(spacing: 40) {
            Text("EMPTY STATES")
                .studioLabelSmall()

            EmptyStateView.emptyFeed

            Rectangle()
                .fill(Color.studioLine)
                .frame(height: 1)

            EmptyStateView.noSearchResults

            Rectangle()
                .fill(Color.studioLine)
                .frame(height: 1)

            EmptyStateView.emptyNotifications

            Rectangle()
                .fill(Color.studioLine)
                .frame(height: 1)

            ErrorView(error: NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to load data"]))
        }
        .padding(20)
    }
    .background(Color.studioBlack)
}
