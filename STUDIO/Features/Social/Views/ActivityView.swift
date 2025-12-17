//
//  ActivityView.swift
//  STUDIO
//
//  Pixel Afterdark Activity/Notifications
//  Shows follow notifications with follow-back functionality
//

import SwiftUI

// MARK: - Activity View

struct ActivityView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var vm = ActivityViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.studioBlack.ignoresSafeArea()

                if vm.isLoading && vm.notifications.isEmpty {
                    loadingView
                } else if vm.notifications.isEmpty {
                    emptyView
                } else {
                    notificationsList
                }
            }
            .navigationTitle("ACTIVITY")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .light))
                            .foregroundStyle(Color.studioSecondary)
                    }
                }

                if vm.hasUnread {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            Task {
                                await vm.markAllAsRead()
                            }
                        } label: {
                            Text("READ ALL")
                                .font(StudioTypography.labelSmall)
                                .tracking(StudioTypography.trackingStandard)
                                .foregroundStyle(Color.studioChrome)
                        }
                    }
                }
            }
            .refreshable {
                await vm.refresh()
            }
            .task {
                await vm.loadNotifications()
            }
            .alert("ERROR", isPresented: $vm.showError) {
                Button("OK") { vm.showError = false }
            } message: {
                Text(vm.error?.localizedDescription ?? "An error occurred")
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 24) {
            StudioLoadingIndicator(size: 20)
            Text("LOADING")
                .studioLabelMedium()
        }
    }

    // MARK: - Empty View

    private var emptyView: some View {
        VStack(spacing: 24) {
            Rectangle()
                .fill(Color.studioSurface)
                .frame(width: 64, height: 64)
                .overlay {
                    Image(systemName: "bell")
                        .font(.system(size: 28, weight: .ultraLight))
                        .foregroundStyle(Color.studioMuted)
                }
                .overlay {
                    Rectangle()
                        .stroke(Color.studioLine, lineWidth: 1)
                }

            Text("NO ACTIVITY YET")
                .studioHeadlineSmall()

            Text("WHEN PEOPLE FOLLOW YOU")
                .studioLabelSmall()
            Text("YOU'LL SEE IT HERE")
                .studioLabelSmall()
        }
    }

    // MARK: - Notifications List

    private var notificationsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(vm.notifications) { notification in
                    NotificationRowView(
                        notification: notification,
                        isFollowing: vm.isFollowing(userId: notification.data?.followerId ?? UUID()),
                        isLoadingFollow: vm.isLoadingFollow(userId: notification.data?.followerId ?? UUID()),
                        onFollowTap: {
                            if let followerId = notification.data?.followerId {
                                Task {
                                    await vm.toggleFollow(userId: followerId)
                                }
                            }
                        },
                        onTap: {
                            Task {
                                await vm.markAsRead(notification)
                            }
                        }
                    )
                    .task {
                        if let followerId = notification.data?.followerId {
                            await vm.checkFollowStatus(userId: followerId)
                        }
                    }

                    Rectangle()
                        .fill(Color.studioLine.opacity(0.3))
                        .frame(height: 1)
                        .padding(.leading, 72)
                }
            }
            .padding(.bottom, 100)
        }
    }
}

// MARK: - Notification Row View

struct NotificationRowView: View {
    let notification: AppNotification
    let isFollowing: Bool
    let isLoadingFollow: Bool
    let onFollowTap: () -> Void
    let onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: 12) {
                // Avatar
                AvatarView(
                    url: notification.data?.followerAvatarUrl,
                    size: .medium,
                    showBorder: !notification.read
                )

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    // Username
                    Text(notification.data?.followerUsername?.uppercased() ?? "USER")
                        .font(StudioTypography.labelLarge)
                        .tracking(StudioTypography.trackingStandard)
                        .foregroundStyle(notification.read ? Color.studioSecondary : Color.studioPrimary)

                    // Action text
                    Text("STARTED FOLLOWING YOU")
                        .font(StudioTypography.labelSmall)
                        .tracking(StudioTypography.trackingNormal)
                        .foregroundStyle(Color.studioMuted)

                    // Time ago
                    Text(timeAgo(from: notification.createdAt).uppercased())
                        .font(StudioTypography.labelSmall)
                        .tracking(StudioTypography.trackingNormal)
                        .foregroundStyle(Color.studioMuted.opacity(0.7))
                }

                Spacer()

                // Follow back button
                if notification.type == .follow {
                    Button {
                        onFollowTap()
                    } label: {
                        if isLoadingFollow {
                            StudioLoadingIndicator(
                                size: 10,
                                color: isFollowing ? .studioPrimary : .studioBlack
                            )
                            .frame(width: 80, height: 28)
                        } else {
                            Text(isFollowing ? "FOLLOWING" : "FOLLOW")
                                .font(StudioTypography.labelSmall)
                                .tracking(StudioTypography.trackingStandard)
                                .foregroundStyle(isFollowing ? Color.studioPrimary : Color.studioBlack)
                                .frame(width: 80, height: 28)
                        }
                    }
                    .background(isFollowing ? Color.studioSurface : Color.studioChrome)
                    .overlay {
                        Rectangle()
                            .stroke(isFollowing ? Color.studioLine : Color.clear, lineWidth: 1)
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                }

                // Unread indicator
                if !notification.read {
                    Rectangle()
                        .fill(Color.studioChrome)
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(notification.read ? Color.clear : Color.studioSurface.opacity(0.3))
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }

    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Preview

#Preview("Activity View") {
    ActivityView()
}
