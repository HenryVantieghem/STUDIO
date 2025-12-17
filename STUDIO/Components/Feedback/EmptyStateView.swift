//
//  EmptyStateView.swift
//  STUDIO
//
//  Pixel Afterdark Empty States
//  8-bit retro messaging with pixel icons
//

import SwiftUI

// MARK: - Pixel Font Reference

private let pixelFontName = "VT323"

// MARK: - Empty State View

/// Reusable empty state component with pixel aesthetic
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 24) {
            // Icon - thin, minimal
            Image(systemName: icon)
                .font(.system(size: 40, weight: .ultraLight))
                .foregroundStyle(Color.studioMuted)

            // Text - centered, pixel font
            VStack(spacing: 14) {
                Text(title.uppercased())
                    .font(.custom(pixelFontName, size: 20))
                    .tracking(StudioTypography.trackingWide)
                    .foregroundStyle(Color.studioPrimary)

                Text(message)
                    .font(.custom(pixelFontName, size: 14))
                    .tracking(StudioTypography.trackingNormal)
                    .foregroundStyle(Color.studioMuted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            // Action Button
            if let actionTitle, let action {
                Button(actionTitle.uppercased(), action: action)
                    .buttonStyle(.studioSecondary)
                    .frame(width: 180)
            }
        }
        .padding(32)
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

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 36, weight: .ultraLight))
                .foregroundStyle(Color.studioError)

            VStack(spacing: 14) {
                Text("ERROR")
                    .font(.custom(pixelFontName, size: 20))
                    .tracking(StudioTypography.trackingWide)
                    .foregroundStyle(Color.studioPrimary)

                Text(error.localizedDescription)
                    .font(.custom(pixelFontName, size: 14))
                    .tracking(StudioTypography.trackingNormal)
                    .foregroundStyle(Color.studioMuted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            if let retry = retryAction {
                Button {
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
                                .font(.custom(pixelFontName, size: 18))
                                .tracking(StudioTypography.trackingStandard)
                        }
                    }
                    .frame(width: 140, height: 44)
                }
                .buttonStyle(.studioSecondary)
                .disabled(isRetrying)
            }
        }
        .padding(32)
    }
}

// MARK: - Loading Button Content

/// Button content with loading state
struct LoadingButtonContent: View {
    let title: String
    var isLoading: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            if isLoading {
                PixelLoadingIndicator()
            } else {
                Text(title)
                    .font(.custom(pixelFontName, size: 18))
                    .tracking(StudioTypography.trackingStandard)
                    .textCase(.uppercase)
            }
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
