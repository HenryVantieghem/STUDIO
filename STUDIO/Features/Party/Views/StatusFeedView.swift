//
//  StatusFeedView.swift
//  STUDIO
//
//  Comment-style status feed with static status buttons at top
//  Statuses appear below like comments when posted
//  Basel Afterdark Design System
//

import SwiftUI

// MARK: - Status Feed View

/// Comment-style status feed with quick status buttons at top
struct StatusFeedView: View {
    let partyId: UUID
    @Binding var statuses: [PartyStatus]
    @Binding var drinkLogs: [DrinkLog]
    var onPostStatus: ((StatusType, Int, String?) async -> Void)?
    var onLogDrink: ((DrinkType, String?, Int) async -> Void)?

    @State private var selectedStatusType: StatusType?
    @State private var selectedLevel: Int = 3
    @State private var statusMessage = ""
    @State private var showStatusPicker = false
    @State private var showDrinkPicker = false
    @State private var isPosting = false

    var body: some View {
        VStack(spacing: 0) {
            // Static status buttons at top
            statusButtonBar

            // Drink tracking button
            drinkTrackingBar

            // Divider
            Rectangle()
                .fill(Color.studioLine)
                .frame(height: 1)

            // Status feed (like comments)
            statusFeed
        }
        .background(Color.studioBlack)
        .sheet(isPresented: $showStatusPicker) {
            StatusPickerSheet(
                selectedType: $selectedStatusType,
                selectedLevel: $selectedLevel,
                message: $statusMessage,
                onPost: {
                    Task {
                        await postStatus()
                    }
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationBackground(Color.studioSurface)
        }
        .sheet(isPresented: $showDrinkPicker) {
            DrinkPickerSheet(
                onLogDrink: { drinkType, customName, quantity in
                    Task {
                        await onLogDrink?(drinkType, customName, quantity)
                    }
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationBackground(Color.studioSurface)
        }
    }

    // MARK: - Status Button Bar

    private var statusButtonBar: some View {
        VStack(spacing: 12) {
            // Quick status buttons (static at top)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(StatusType.allCases, id: \.self) { statusType in
                        QuickStatusButton(
                            statusType: statusType,
                            isSelected: selectedStatusType == statusType
                        ) {
                            HapticManager.shared.impact(.light)
                            selectedStatusType = statusType
                            showStatusPicker = true
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 12)
        }
        .background(Color.studioDeepBlack)
    }

    // MARK: - Drink Tracking Bar

    private var drinkTrackingBar: some View {
        HStack(spacing: 12) {
            // Popular drinks quick buttons
            ForEach([DrinkType.beer, .wine, .shot, .cocktail, .water], id: \.self) { drink in
                Button {
                    HapticManager.shared.impact(.light)
                    Task {
                        await onLogDrink?(drink, nil, 1)
                    }
                } label: {
                    VStack(spacing: 4) {
                        Text(drink.emoji)
                            .font(.system(size: 24))
                        Text("+1")
                            .font(StudioTypography.labelSmall)
                            .tracking(StudioTypography.trackingNormal)
                            .foregroundStyle(Color.studioMuted)
                    }
                    .frame(width: 56, height: 56)
                    .background(Color.studioSurface)
                    .overlay {
                        Rectangle()
                            .stroke(Color.studioLine, lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)
            }

            // More drinks button
            Button {
                HapticManager.shared.impact(.light)
                showDrinkPicker = true
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .light))
                        .foregroundStyle(Color.studioChrome)
                    Text("MORE")
                        .font(StudioTypography.labelSmall)
                        .tracking(StudioTypography.trackingNormal)
                        .foregroundStyle(Color.studioMuted)
                }
                .frame(width: 56, height: 56)
                .background(Color.studioSurface)
                .overlay {
                    Rectangle()
                        .stroke(Color.studioChrome, lineWidth: 1)
                }
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.studioDeepBlack)
    }

    // MARK: - Status Feed

    private var statusFeed: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Combined feed of statuses and drinks
                let feedItems = combinedFeedItems
                    .sorted { $0.date > $1.date }

                if feedItems.isEmpty {
                    emptyState
                } else {
                    ForEach(feedItems) { item in
                        switch item.type {
                        case .status(let status):
                            StatusFeedRow(status: status)
                        case .drink(let drink):
                            DrinkFeedRow(drinkLog: drink)
                        }

                        // Divider between items
                        Rectangle()
                            .fill(Color.studioLine.opacity(0.5))
                            .frame(height: 0.5)
                            .padding(.leading, 60)
                    }
                }
            }
            .padding(.top, 16)
        }
    }

    // MARK: - Combined Feed Items

    private var combinedFeedItems: [FeedItem] {
        var items: [FeedItem] = []

        for status in statuses {
            items.append(FeedItem(
                id: status.id,
                date: status.createdAt,
                type: .status(status)
            ))
        }

        for drink in drinkLogs {
            items.append(FeedItem(
                id: drink.id,
                date: drink.createdAt,
                type: .drink(drink)
            ))
        }

        return items
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 48, weight: .ultraLight))
                .foregroundStyle(Color.studioMuted)

            Text("NO UPDATES YET")
                .font(StudioTypography.headlineMedium)
                .tracking(StudioTypography.trackingWide)
                .foregroundStyle(Color.studioSecondary)

            Text("TAP A STATUS ABOVE TO SHARE YOUR VIBE")
                .font(StudioTypography.bodyMedium)
                .tracking(StudioTypography.trackingNormal)
                .foregroundStyle(Color.studioMuted)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }

    // MARK: - Post Status

    private func postStatus() async {
        guard let type = selectedStatusType else { return }

        isPosting = true
        await onPostStatus?(type, selectedLevel, statusMessage.isEmpty ? nil : statusMessage)
        isPosting = false

        // Reset
        selectedStatusType = nil
        selectedLevel = 3
        statusMessage = ""
        showStatusPicker = false

        HapticManager.shared.notification(.success)
    }
}

// MARK: - Feed Item

struct FeedItem: Identifiable {
    let id: UUID
    let date: Date
    let type: FeedItemType

    enum FeedItemType {
        case status(PartyStatus)
        case drink(DrinkLog)
    }
}

// MARK: - Quick Status Button

struct QuickStatusButton: View {
    let statusType: StatusType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(statusType.emojiForLevel(3))
                    .font(.system(size: 20))

                Text(statusType.shortLabel)
                    .font(StudioTypography.labelSmall)
                    .tracking(StudioTypography.trackingNormal)
                    .foregroundStyle(isSelected ? Color.studioBlack : Color.studioSecondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.studioChrome : Color.studioSurface)
            .overlay {
                Rectangle()
                    .stroke(isSelected ? Color.studioChrome : Color.studioLine, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Status Feed Row

struct StatusFeedRow: View {
    let status: PartyStatus

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Avatar
            AvatarView(url: status.user?.avatarUrl, size: .medium)

            VStack(alignment: .leading, spacing: 6) {
                // Header
                HStack(spacing: 8) {
                    Text(status.user?.username?.uppercased() ?? "USER")
                        .font(StudioTypography.labelMedium)
                        .tracking(StudioTypography.trackingNormal)
                        .foregroundStyle(Color.studioPrimary)

                    Text("•")
                        .foregroundStyle(Color.studioMuted)

                    Text(status.createdAt.timeAgoAbbreviated())
                        .font(StudioTypography.labelSmall)
                        .tracking(StudioTypography.trackingNormal)
                        .foregroundStyle(Color.studioMuted)
                }

                // Status content
                HStack(spacing: 8) {
                    // Emoji indicator
                    Text(status.statusType.emojiForLevel(status.value))
                        .font(.system(size: 28))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(status.statusType.label)
                            .font(StudioTypography.labelSmall)
                            .tracking(StudioTypography.trackingNormal)
                            .foregroundStyle(Color.studioMuted)

                        Text(status.statusType.labelForLevel(status.value))
                            .font(StudioTypography.bodyLarge)
                            .tracking(StudioTypography.trackingNormal)
                            .foregroundStyle(Color.studioPrimary)
                    }

                    Spacer()

                    // Level indicator
                    HStack(spacing: 4) {
                        ForEach(1...5, id: \.self) { level in
                            Rectangle()
                                .fill(level <= status.value ? Color.studioChrome : Color.studioLine)
                                .frame(width: 8, height: 16)
                        }
                    }
                }

                // Optional message
                if let message = status.message, !message.isEmpty {
                    Text(message)
                        .font(StudioTypography.bodyMedium)
                        .foregroundStyle(Color.studioSecondary)
                        .padding(.top, 4)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Drink Feed Row

struct DrinkFeedRow: View {
    let drinkLog: DrinkLog

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Avatar
            AvatarView(url: drinkLog.user?.avatarUrl, size: .medium)

            VStack(alignment: .leading, spacing: 6) {
                // Header
                HStack(spacing: 8) {
                    Text(drinkLog.user?.username?.uppercased() ?? "USER")
                        .font(StudioTypography.labelMedium)
                        .tracking(StudioTypography.trackingNormal)
                        .foregroundStyle(Color.studioPrimary)

                    Text("•")
                        .foregroundStyle(Color.studioMuted)

                    Text(drinkLog.createdAt.timeAgoAbbreviated())
                        .font(StudioTypography.labelSmall)
                        .tracking(StudioTypography.trackingNormal)
                        .foregroundStyle(Color.studioMuted)
                }

                // Drink content
                HStack(spacing: 8) {
                    // Emoji
                    Text(drinkLog.emoji ?? drinkLog.drinkType.emoji)
                        .font(.system(size: 28))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("HAD A DRINK")
                            .font(StudioTypography.labelSmall)
                            .tracking(StudioTypography.trackingNormal)
                            .foregroundStyle(Color.studioMuted)

                        if drinkLog.drinkType == .custom, let custom = drinkLog.customDrink {
                            Text(custom.uppercased())
                                .font(StudioTypography.bodyLarge)
                                .tracking(StudioTypography.trackingNormal)
                                .foregroundStyle(Color.studioPrimary)
                        } else {
                            Text("\(drinkLog.quantity)x \(drinkLog.drinkType.label)")
                                .font(StudioTypography.bodyLarge)
                                .tracking(StudioTypography.trackingNormal)
                                .foregroundStyle(Color.studioPrimary)
                        }
                    }

                    Spacer()
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Status Picker Sheet

struct StatusPickerSheet: View {
    @Binding var selectedType: StatusType?
    @Binding var selectedLevel: Int
    @Binding var message: String
    var onPost: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Status type selector
                if let type = selectedType {
                    // Large emoji display
                    Text(type.emojiForLevel(selectedLevel))
                        .font(.system(size: 80))
                        .padding(.top, 20)

                    Text(type.labelForLevel(selectedLevel))
                        .font(StudioTypography.headlineLarge)
                        .tracking(StudioTypography.trackingWide)
                        .foregroundStyle(Color.studioPrimary)

                    // Level selector
                    HStack(spacing: 12) {
                        ForEach(1...5, id: \.self) { level in
                            Button {
                                HapticManager.shared.impact(.light)
                                selectedLevel = level
                            } label: {
                                VStack(spacing: 4) {
                                    Text(type.emojiForLevel(level))
                                        .font(.system(size: 24))

                                    Text("\(level)")
                                        .font(StudioTypography.labelMedium)
                                        .foregroundStyle(level == selectedLevel ? Color.studioBlack : Color.studioSecondary)
                                }
                                .frame(width: 56, height: 72)
                                .background(level == selectedLevel ? Color.studioChrome : Color.studioSurface)
                                .overlay {
                                    Rectangle()
                                        .stroke(level == selectedLevel ? Color.studioChrome : Color.studioLine, lineWidth: 1)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Optional message
                    VStack(alignment: .leading, spacing: 8) {
                        Text("MESSAGE (OPTIONAL)")
                            .font(StudioTypography.labelSmall)
                            .tracking(StudioTypography.trackingWide)
                            .foregroundStyle(Color.studioMuted)

                        TextField("", text: $message, prompt: Text("Add a message...")
                            .font(StudioTypography.bodyMedium)
                            .foregroundStyle(Color.studioMuted))
                            .font(StudioTypography.bodyMedium)
                            .foregroundStyle(Color.studioPrimary)
                            .padding()
                            .background(Color.studioDeepBlack)
                            .overlay {
                                Rectangle()
                                    .stroke(Color.studioLine, lineWidth: 1)
                            }
                    }
                    .padding(.horizontal, 16)
                }

                Spacer()

                // Post button
                Button {
                    onPost()
                } label: {
                    Text("POST STATUS")
                        .font(StudioTypography.labelLarge)
                        .tracking(StudioTypography.trackingWide)
                        .foregroundStyle(Color.studioBlack)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.studioChrome)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .background(Color.studioSurface)
            .navigationTitle(selectedType?.label ?? "UPDATE STATUS")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("CANCEL") {
                        dismiss()
                    }
                    .font(StudioTypography.labelMedium)
                    .foregroundStyle(Color.studioMuted)
                }
            }
        }
    }
}

// MARK: - Drink Picker Sheet

struct DrinkPickerSheet: View {
    var onLogDrink: ((DrinkType, String?, Int) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var selectedDrink: DrinkType = .beer
    @State private var customDrinkName = ""
    @State private var quantity = 1

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Drink type grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(DrinkType.allCases, id: \.self) { drink in
                            DrinkTypeButton(
                                drinkType: drink,
                                isSelected: selectedDrink == drink
                            ) {
                                HapticManager.shared.impact(.light)
                                selectedDrink = drink
                            }
                        }
                    }
                    .padding(.horizontal, 16)

                    // Custom drink name (if custom selected)
                    if selectedDrink == .custom {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("DRINK NAME")
                                .font(StudioTypography.labelSmall)
                                .tracking(StudioTypography.trackingWide)
                                .foregroundStyle(Color.studioMuted)

                            TextField("", text: $customDrinkName, prompt: Text("Enter drink name...")
                                .font(StudioTypography.bodyMedium)
                                .foregroundStyle(Color.studioMuted))
                                .font(StudioTypography.bodyMedium)
                                .foregroundStyle(Color.studioPrimary)
                                .textInputAutocapitalization(.words)
                                .padding()
                                .background(Color.studioDeepBlack)
                                .overlay {
                                    Rectangle()
                                        .stroke(Color.studioLine, lineWidth: 1)
                                }
                        }
                        .padding(.horizontal, 16)
                    }

                    // Quantity selector
                    VStack(alignment: .leading, spacing: 8) {
                        Text("QUANTITY")
                            .font(StudioTypography.labelSmall)
                            .tracking(StudioTypography.trackingWide)
                            .foregroundStyle(Color.studioMuted)

                        HStack(spacing: 16) {
                            Button {
                                if quantity > 1 {
                                    HapticManager.shared.impact(.light)
                                    quantity -= 1
                                }
                            } label: {
                                Image(systemName: "minus")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundStyle(Color.studioPrimary)
                                    .frame(width: 48, height: 48)
                                    .background(Color.studioSurface)
                                    .overlay {
                                        Rectangle()
                                            .stroke(Color.studioLine, lineWidth: 1)
                                    }
                            }
                            .buttonStyle(.plain)

                            Text("\(quantity)")
                                .font(StudioTypography.displayMedium)
                                .tracking(StudioTypography.trackingWide)
                                .foregroundStyle(Color.studioPrimary)
                                .frame(width: 80)

                            Button {
                                if quantity < 10 {
                                    HapticManager.shared.impact(.light)
                                    quantity += 1
                                }
                            } label: {
                                Image(systemName: "plus")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundStyle(Color.studioPrimary)
                                    .frame(width: 48, height: 48)
                                    .background(Color.studioSurface)
                                    .overlay {
                                        Rectangle()
                                            .stroke(Color.studioLine, lineWidth: 1)
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)

                    Spacer()
                }
                .padding(.top, 16)
            }
            .background(Color.studioSurface)
            .navigationTitle("LOG DRINK")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("CANCEL") {
                        dismiss()
                    }
                    .font(StudioTypography.labelMedium)
                    .foregroundStyle(Color.studioMuted)
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        HapticManager.shared.notification(.success)
                        onLogDrink?(selectedDrink, selectedDrink == .custom ? customDrinkName : nil, quantity)
                        dismiss()
                    } label: {
                        Text("LOG")
                            .font(StudioTypography.labelMedium)
                            .foregroundStyle(Color.studioChrome)
                    }
                }
            }
        }
    }
}

// MARK: - Drink Type Button

struct DrinkTypeButton: View {
    let drinkType: DrinkType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(drinkType.emoji)
                    .font(.system(size: 28))

                Text(drinkType.label)
                    .font(StudioTypography.labelSmall)
                    .tracking(StudioTypography.trackingNormal)
                    .foregroundStyle(isSelected ? Color.studioBlack : Color.studioSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(isSelected ? Color.studioChrome : Color.studioDeepBlack)
            .overlay {
                Rectangle()
                    .stroke(isSelected ? Color.studioChrome : Color.studioLine, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Date Extension

extension Date {
    func timeAgoAbbreviated() -> String {
        let now = Date()
        let components = Calendar.current.dateComponents([.minute, .hour, .day], from: self, to: now)

        if let days = components.day, days > 0 {
            return "\(days)d"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours)h"
        } else if let minutes = components.minute, minutes > 0 {
            return "\(minutes)m"
        } else {
            return "now"
        }
    }
}

// MARK: - Preview

#Preview("Status Feed") {
    StatusFeedView(
        partyId: UUID(),
        statuses: .constant([]),
        drinkLogs: .constant([])
    )
}
