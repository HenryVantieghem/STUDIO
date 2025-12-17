//
//  PartyStatusSheet.swift
//  STUDIO
//
//  Instagram-style status sheet showing all guest statuses
//  Basel Afterdark Design System
//

import SwiftUI

// MARK: - Party Status Sheet

/// Sheet displaying all party guest statuses with ability to update your own
struct PartyStatusSheet: View {
    let partyId: UUID
    let statuses: [PartyStatus]
    var currentUserStatus: PartyStatus?
    var isLoading: Bool = false
    var onUpdateStatus: ((StatusType, Int, String?) -> Void)?

    @State private var selectedType: StatusType = .vibeCheck
    @State private var showStatusPicker = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            sheetHeader

            // Status type tabs
            statusTypeTabs

            // Content
            if isLoading {
                loadingView
            } else if filteredStatuses.isEmpty && currentUserStatus == nil {
                emptyStateView
            } else {
                statusGrid
            }
        }
        .background(Color.studioSurface)
        .sheet(isPresented: $showStatusPicker) {
            StatusPickerView(partyId: partyId, onStatusPosted: {
                showStatusPicker = false
            })
        }
    }

    // MARK: - Filtered Statuses

    private var filteredStatuses: [PartyStatus] {
        statuses.filter { $0.statusType == selectedType }
    }

    // MARK: - Header

    private var sheetHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("VIBES")
                    .font(StudioTypography.headlineSmall)
                    .tracking(StudioTypography.trackingNormal)
                    .foregroundStyle(Color.studioPrimary)

                Text("\(statuses.count) STATUS UPDATES")
                    .font(StudioTypography.labelSmall)
                    .tracking(StudioTypography.trackingNormal)
                    .foregroundStyle(Color.studioMuted)
            }

            Spacer()

            // Update status button
            Button {
                showStatusPicker = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .medium))
                    Text("UPDATE")
                        .font(StudioTypography.labelSmall)
                        .tracking(StudioTypography.trackingWide)
                }
                .foregroundStyle(Color.studioBlack)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.studioChrome)
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.studioLine)
                .frame(height: 0.5)
        }
    }

    // MARK: - Status Type Tabs

    private var statusTypeTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(StatusType.allCases, id: \.self) { type in
                    StatusTypeTab(
                        type: type,
                        isSelected: selectedType == type,
                        count: statuses.filter { $0.statusType == type }.count
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedType = type
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color.studioDeepBlack)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            Spacer()
            StudioLoadingIndicator(size: 24, color: .studioChrome)
            Text("LOADING VIBES")
                .font(StudioTypography.labelSmall)
                .tracking(StudioTypography.trackingWide)
                .foregroundStyle(Color.studioMuted)
            Spacer()
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: selectedType.icon)
                .font(.system(size: 48, weight: .ultraLight))
                .foregroundStyle(Color.studioLine)

            VStack(spacing: 8) {
                Text("NO \(selectedType.label) YET")
                    .font(StudioTypography.labelMedium)
                    .tracking(StudioTypography.trackingWide)
                    .foregroundStyle(Color.studioMuted)

                Text("BE THE FIRST TO SHARE YOUR VIBE")
                    .font(StudioTypography.labelSmall)
                    .tracking(StudioTypography.trackingNormal)
                    .foregroundStyle(Color.studioMuted.opacity(0.6))
            }

            Button {
                showStatusPicker = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12, weight: .light))
                    Text("SHARE YOUR \(selectedType.shortLabel)")
                        .font(StudioTypography.labelMedium)
                        .tracking(StudioTypography.trackingWide)
                }
                .foregroundStyle(Color.studioChrome)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .overlay {
                    Rectangle()
                        .stroke(Color.studioChrome, lineWidth: 0.5)
                }
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())

            Spacer()
        }
    }

    // MARK: - Status Grid

    private var statusGrid: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                // Current user status first (if they have one for this type)
                if let userStatus = currentUserStatus, userStatus.statusType == selectedType {
                    StatusCard(status: userStatus, isCurrentUser: true)
                }

                // Other users' statuses
                ForEach(filteredStatuses.filter { $0.id != currentUserStatus?.id }) { status in
                    StatusCard(status: status, isCurrentUser: false)
                }
            }
            .padding(16)
        }
    }
}

// MARK: - Status Type Tab

/// Individual tab for status type selection
struct StatusTypeTab: View {
    let type: StatusType
    let isSelected: Bool
    var count: Int = 0
    var action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: type.icon)
                    .font(.system(size: 12, weight: isSelected ? .regular : .light))

                Text(type.shortLabel)
                    .font(StudioTypography.labelSmall)
                    .tracking(StudioTypography.trackingNormal)

                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(isSelected ? Color.studioBlack : Color.studioMuted)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(isSelected ? Color.studioChrome.opacity(0.3) : Color.studioSurface)
                }
            }
            .foregroundStyle(isSelected ? Color.studioChrome : Color.studioMuted)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.studioSurface : Color.clear)
            .overlay {
                Rectangle()
                    .stroke(isSelected ? Color.studioChrome : Color.studioLine, lineWidth: 0.5)
            }
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
}

// MARK: - Status Card

/// Individual status card showing user's status
struct StatusCard: View {
    let status: PartyStatus
    var isCurrentUser: Bool = false

    var body: some View {
        VStack(spacing: 10) {
            // Avatar
            ZStack(alignment: .bottomTrailing) {
                AvatarView(
                    url: status.user?.avatarUrl,
                    size: .large,
                    showBorder: isCurrentUser,
                    borderColor: .studioChrome
                )

                // Level badge
                Text("\(status.value)")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.studioBlack)
                    .frame(width: 18, height: 18)
                    .background(levelColor(status.value))
                    .offset(x: 4, y: 4)
            }

            // Emoji
            Text(status.statusType.emojiForLevel(status.value))
                .font(.system(size: 24))

            // Level label
            Text(status.statusType.labelForLevel(status.value))
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .tracking(StudioTypography.trackingNormal)
                .foregroundStyle(isCurrentUser ? Color.studioChrome : Color.studioMuted)
                .lineLimit(1)

            // Username
            if let user = status.user {
                Text(user.username.uppercased())
                    .font(StudioTypography.labelSmall)
                    .tracking(StudioTypography.trackingNormal)
                    .foregroundStyle(Color.studioSecondary)
                    .lineLimit(1)
            }

            // Time ago
            Text(formatTimeAgo(status.createdAt))
                .font(.system(size: 8, weight: .regular, design: .monospaced))
                .foregroundStyle(Color.studioMuted.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .background(isCurrentUser ? Color.studioSurface : Color.studioDeepBlack)
        .overlay {
            Rectangle()
                .stroke(isCurrentUser ? Color.studioChrome : Color.studioLine, lineWidth: isCurrentUser ? 1 : 0.5)
        }
    }

    private func levelColor(_ level: Int) -> Color {
        // Monochromatic scale for Basel Afterdark
        switch level {
        case 1: return Color.studioMuted
        case 2: return Color.studioSecondary
        case 3: return Color.studioChrome
        case 4: return Color.studioPrimary
        default: return Color.studioPrimary
        }
    }

    private func formatTimeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date()).uppercased()
    }
}

// MARK: - Preview

#Preview("Status Sheet") {
    PartyStatusSheet(
        partyId: UUID(),
        statuses: MockData.partyStatuses,
        currentUserStatus: MockData.partyStatuses.first
    )
}

#Preview("Status Sheet - Empty") {
    PartyStatusSheet(
        partyId: UUID(),
        statuses: [],
        currentUserStatus: nil
    )
}
