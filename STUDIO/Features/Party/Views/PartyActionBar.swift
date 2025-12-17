//
//  PartyActionBar.swift
//  STUDIO
//
//  Instagram-style action bar for party posts
//  Basel Afterdark Design System
//

import SwiftUI

// MARK: - Party Action Bar

/// Action bar with buttons for media, comments, polls, and status
struct PartyActionBar: View {
    // Counts
    var mediaCount: Int = 0
    var commentCount: Int = 0
    var pollCount: Int = 0
    var statusCount: Int = 0

    // Actions
    var onAddMedia: (() -> Void)?
    var onComments: (() -> Void)?
    var onPolls: (() -> Void)?
    var onStatus: (() -> Void)?

    var body: some View {
        HStack(spacing: 0) {
            // Add Media button (camera/gallery)
            ActionButton(
                icon: "camera.fill",
                label: "ADD",
                count: mediaCount > 0 ? "\(mediaCount)" : nil,
                isPrimary: true,
                action: { onAddMedia?() }
            )

            // Comments button
            ActionButton(
                icon: "bubble.left",
                label: "CHAT",
                count: commentCount > 0 ? formatCount(commentCount) : nil,
                action: { onComments?() }
            )

            // Polls button
            ActionButton(
                icon: "chart.bar",
                label: "VOTE",
                count: pollCount > 0 ? "\(pollCount)" : nil,
                action: { onPolls?() }
            )

            // Status button
            ActionButton(
                icon: "sparkles",
                label: "VIBE",
                count: statusCount > 0 ? "\(statusCount)" : nil,
                action: { onStatus?() }
            )

            Spacer()

            // Save/Bookmark button
            Button {
                // Save action
            } label: {
                Image(systemName: "bookmark")
                    .font(.system(size: 18, weight: .light))
                    .foregroundStyle(Color.studioMuted)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.studioSurface)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.studioLine)
                .frame(height: 0.5)
        }
    }

    private func formatCount(_ count: Int) -> String {
        if count >= 1000 {
            return String(format: "%.1fK", Double(count) / 1000)
        }
        return "\(count)"
    }
}

// MARK: - Action Button

/// Individual action button with icon, label, and optional count
struct ActionButton: View {
    let icon: String
    let label: String
    var count: String?
    var isPrimary: Bool = false
    var action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button {
            action()
        } label: {
            VStack(spacing: 2) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: icon)
                        .font(.system(size: isPrimary ? 20 : 18, weight: isPrimary ? .regular : .light))
                        .foregroundStyle(isPrimary ? Color.studioChrome : Color.studioMuted)
                        .frame(width: 44, height: 32)

                    // Count badge
                    if let count = count {
                        Text(count)
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundStyle(Color.studioBlack)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(isPrimary ? Color.studioChrome : Color.studioMuted)
                            .offset(x: 4, y: -2)
                    }
                }

                Text(label)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .tracking(StudioTypography.trackingNormal)
                    .foregroundStyle(isPrimary ? Color.studioChrome : Color.studioMuted.opacity(0.7))
            }
            .frame(width: 64, height: 52)
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Extended Action Bar

/// Extended action bar with more options (for party detail view)
struct PartyActionBarExtended: View {
    var mediaCount: Int = 0
    var commentCount: Int = 0
    var pollCount: Int = 0
    var statusCount: Int = 0
    var guestCount: Int = 0

    var onAddMedia: (() -> Void)?
    var onComments: (() -> Void)?
    var onPolls: (() -> Void)?
    var onStatus: (() -> Void)?
    var onGuests: (() -> Void)?
    var onShare: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            // Primary actions row
            HStack(spacing: 0) {
                // Camera button (prominent)
                Button {
                    onAddMedia?()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 16, weight: .regular))
                        Text("CAPTURE")
                            .font(StudioTypography.labelSmall)
                            .tracking(StudioTypography.trackingWide)
                    }
                    .foregroundStyle(Color.studioBlack)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.studioChrome)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())

                // Secondary actions
                HStack(spacing: 0) {
                    SmallActionButton(
                        icon: "bubble.left",
                        count: commentCount,
                        action: { onComments?() }
                    )

                    SmallActionButton(
                        icon: "chart.bar",
                        count: pollCount,
                        action: { onPolls?() }
                    )

                    SmallActionButton(
                        icon: "sparkles",
                        count: statusCount,
                        action: { onStatus?() }
                    )

                    SmallActionButton(
                        icon: "person.2",
                        count: guestCount,
                        action: { onGuests?() }
                    )
                }
            }

            // Share row
            Button {
                onShare?()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 12, weight: .light))
                    Text("SHARE PARTY")
                        .font(StudioTypography.labelSmall)
                        .tracking(StudioTypography.trackingNormal)
                }
                .foregroundStyle(Color.studioMuted)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(Color.studioSurface)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Color.studioLine)
                        .frame(height: 0.5)
                }
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
        }
    }
}

// MARK: - Small Action Button

/// Compact action button for extended bar
struct SmallActionButton: View {
    let icon: String
    var count: Int = 0
    var action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .light))
                    .foregroundStyle(Color.studioMuted)
                    .frame(width: 44, height: 44)

                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color.studioBlack)
                        .padding(.horizontal, 3)
                        .padding(.vertical, 1)
                        .background(Color.studioChrome)
                        .offset(x: -2, y: 6)
                }
            }
            .frame(height: 44)
            .background(Color.studioSurface)
            .overlay {
                Rectangle()
                    .stroke(Color.studioLine, lineWidth: 0.5)
            }
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
}

// MARK: - Floating Action Button

/// Floating camera button for feed view
struct FloatingCameraButton: View {
    var onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button {
            onTap()
        } label: {
            ZStack {
                Rectangle()
                    .fill(LinearGradient.studioMetallic)
                    .frame(width: 56, height: 56)

                Image(systemName: "camera.fill")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(Color.studioBlack)
            }
            .overlay {
                Rectangle()
                    .stroke(Color.studioLine, lineWidth: 0.5)
            }
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .shadow(color: Color.studioBlack.opacity(0.5), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
        )
    }
}

// MARK: - Preview

#Preview("Action Bar") {
    VStack(spacing: 32) {
        Text("STANDARD")
            .studioLabelSmall()

        PartyActionBar(
            mediaCount: 24,
            commentCount: 156,
            pollCount: 3,
            statusCount: 8
        )

        Text("EXTENDED")
            .studioLabelSmall()

        PartyActionBarExtended(
            mediaCount: 24,
            commentCount: 156,
            pollCount: 3,
            statusCount: 8,
            guestCount: 12
        )

        Text("FLOATING")
            .studioLabelSmall()

        FloatingCameraButton { }
    }
    .padding()
    .background(Color.studioBlack)
}
