//
//  PartyPollsSheet.swift
//  STUDIO
//
//  Party polls voting interface
//  Basel Afterdark Design System
//

import SwiftUI

// MARK: - Party Polls Sheet

/// Slidable sheet for viewing and voting on party polls
struct PartyPollsSheet: View {
    let partyId: UUID
    let polls: [PartyPoll]
    let guests: [PartyGuest]
    var isLoading: Bool = false

    var onVote: ((UUID, UUID) -> Void)?
    var onCreatePoll: ((String, PollType, [String]) -> Void)?

    @State private var selectedTab: PollTab = .active
    @State private var showCreatePoll = false

    enum PollTab: String, CaseIterable, Identifiable {
        case active = "Active"
        case results = "Results"

        var id: String { rawValue }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with create button
            sheetHeader

            // Tab picker
            tabPicker

            // Content
            if isLoading {
                loadingView
            } else if polls.isEmpty {
                emptyPollsView
            } else {
                pollsList
            }
        }
        .background(Color.studioSurface)
        .sheet(isPresented: $showCreatePoll) {
            CreatePollSheet(
                guests: guests,
                onCreate: { question, pollType, options in
                    onCreatePoll?(question, pollType, options)
                    showCreatePoll = false
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationBackground(Color.studioSurface)
        }
    }

    // MARK: - Header

    private var sheetHeader: some View {
        HStack {
            Text("POLLS")
                .font(StudioTypography.headlineSmall)
                .tracking(StudioTypography.trackingNormal)
                .foregroundStyle(Color.studioPrimary)

            Spacer()

            Button {
                showCreatePoll = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .light))
                    Text("CREATE")
                        .font(StudioTypography.labelSmall)
                        .tracking(StudioTypography.trackingWide)
                }
                .foregroundStyle(Color.studioChrome)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.studioBlack)
                .overlay {
                    Rectangle()
                        .stroke(Color.studioLine, lineWidth: 0.5)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.studioLine)
                .frame(height: 0.5)
        }
    }

    // MARK: - Tab Picker

    private var tabPicker: some View {
        HStack(spacing: 0) {
            ForEach(PollTab.allCases) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 8) {
                        Text(tab.rawValue.uppercased())
                            .font(StudioTypography.labelSmall)
                            .tracking(StudioTypography.trackingNormal)
                            .foregroundStyle(selectedTab == tab ? Color.studioChrome : Color.studioMuted)

                        Rectangle()
                            .fill(Color.studioChrome)
                            .frame(height: 0.5)
                            .opacity(selectedTab == tab ? 1 : 0)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 12)
        .background(Color.studioDeepBlack)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            Spacer()
            StudioLoadingIndicator(size: 24, color: .studioChrome)
            Text("LOADING POLLS")
                .font(StudioTypography.labelSmall)
                .tracking(StudioTypography.trackingWide)
                .foregroundStyle(Color.studioMuted)
            Spacer()
        }
    }

    // MARK: - Empty State

    private var emptyPollsView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "chart.bar")
                .font(.system(size: 48, weight: .ultraLight))
                .foregroundStyle(Color.studioLine)

            VStack(spacing: 8) {
                Text("NO POLLS YET")
                    .font(StudioTypography.labelMedium)
                    .tracking(StudioTypography.trackingWide)
                    .foregroundStyle(Color.studioMuted)

                Text("CREATE ONE TO START VOTING")
                    .font(StudioTypography.labelSmall)
                    .tracking(StudioTypography.trackingNormal)
                    .foregroundStyle(Color.studioMuted.opacity(0.6))
            }

            Button {
                showCreatePoll = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .light))
                    Text("CREATE POLL")
                        .font(StudioTypography.labelLarge)
                        .tracking(StudioTypography.trackingWide)
                }
                .foregroundStyle(Color.studioBlack)
                .frame(width: 160, height: 44)
                .background(Color.studioChrome)
            }
            .buttonStyle(.plain)
            .padding(.top, 8)

            Spacer()
        }
    }

    // MARK: - Polls List

    private var pollsList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(filteredPolls) { poll in
                    PollCard(
                        poll: poll,
                        showResults: selectedTab == .results || hasVoted(poll),
                        onVote: { optionId in
                            onVote?(poll.id, optionId)
                        }
                    )
                }
            }
            .padding(16)
        }
    }

    private var filteredPolls: [PartyPoll] {
        switch selectedTab {
        case .active:
            return polls.filter { $0.isActive == true }
        case .results:
            return polls
        }
    }

    private func hasVoted(_ poll: PartyPoll) -> Bool {
        poll.options?.contains { $0.hasVoted == true } ?? false
    }
}

// MARK: - Poll Card

/// Individual poll card with options
struct PollCard: View {
    let poll: PartyPoll
    var showResults: Bool = false
    var onVote: ((UUID) -> Void)?

    @State private var selectedOption: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Poll header
            HStack(spacing: 12) {
                // Poll type icon
                pollTypeIcon

                VStack(alignment: .leading, spacing: 4) {
                    Text(poll.question.uppercased())
                        .font(StudioTypography.labelMedium)
                        .tracking(StudioTypography.trackingNormal)
                        .foregroundStyle(Color.studioPrimary)
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        Text(poll.pollType.displayName.uppercased())
                            .font(StudioTypography.labelSmall)
                            .foregroundStyle(Color.studioChrome)

                        Text("•")
                            .foregroundStyle(Color.studioMuted)

                        Text("\(poll.totalVotes ?? 0) VOTES")
                            .font(StudioTypography.labelSmall)
                            .foregroundStyle(Color.studioMuted)
                    }
                }

                Spacer()

                // Status indicator
                if poll.isActive == true {
                    HStack(spacing: 4) {
                        Rectangle()
                            .fill(Color.studioChrome)
                            .frame(width: 4, height: 4)
                        Text("LIVE")
                            .font(StudioTypography.labelSmall)
                            .tracking(StudioTypography.trackingWide)
                            .foregroundStyle(Color.studioChrome)
                    }
                } else {
                    Text("ENDED")
                        .font(StudioTypography.labelSmall)
                        .foregroundStyle(Color.studioMuted)
                }
            }

            // Poll options
            VStack(spacing: 8) {
                if let options = poll.options {
                    ForEach(options) { option in
                        PollOptionRow(
                            option: option,
                            totalVotes: poll.totalVotes ?? 0,
                            showResults: showResults,
                            isSelected: option.id == selectedOption || option.hasVoted == true,
                            onTap: {
                                if poll.isActive == true && !showResults {
                                    selectedOption = option.id
                                    onVote?(option.id)
                                }
                            }
                        )
                    }
                }
            }

            // Expiry info
            if let expiresAt = poll.expiresAt {
                Text("ENDS \(formatExpiry(expiresAt).uppercased())")
                    .font(StudioTypography.labelSmall)
                    .foregroundStyle(Color.studioMuted.opacity(0.6))
            }
        }
        .padding(16)
        .background(Color.studioDeepBlack)
        .overlay {
            Rectangle()
                .stroke(Color.studioLine, lineWidth: 0.5)
        }
    }

    private var pollTypeIcon: some View {
        ZStack {
            Rectangle()
                .fill(Color.studioSurface)
                .frame(width: 44, height: 44)

            Image(systemName: poll.pollType.icon)
                .font(.system(size: 18, weight: .light))
                .foregroundStyle(Color.studioChrome)
        }
        .overlay {
            Rectangle()
                .stroke(Color.studioLine, lineWidth: 0.5)
        }
    }

    private func formatExpiry(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Poll Option Row

/// Individual poll option with voting
struct PollOptionRow: View {
    let option: PollOption
    let totalVotes: Int
    var showResults: Bool = false
    var isSelected: Bool = false
    var onTap: (() -> Void)?

    private var percentage: Double {
        guard totalVotes > 0 else { return 0 }
        return Double(option.voteCount) / Double(totalVotes) * 100
    }

    var body: some View {
        Button {
            onTap?()
        } label: {
            ZStack(alignment: .leading) {
                // Progress bar background
                if showResults {
                    GeometryReader { geo in
                        Rectangle()
                            .fill(isSelected ? Color.studioChrome.opacity(0.2) : Color.studioSurface)
                            .frame(width: geo.size.width * CGFloat(percentage / 100))
                    }
                }

                // Content
                HStack(spacing: 12) {
                    // User avatar if voting for person
                    if let user = option.optionUser {
                        AvatarView(url: user.avatarUrl, size: .small)
                    }

                    // Option text
                    Text(option.optionText ?? option.optionUser?.displayName ?? "Option")
                        .font(StudioTypography.bodySmall)
                        .tracking(StudioTypography.trackingNormal)
                        .foregroundStyle(Color.studioPrimary)
                        .lineLimit(1)

                    Spacer()

                    // Vote count or selection indicator
                    if showResults {
                        HStack(spacing: 8) {
                            Text("\(option.voteCount)")
                                .font(StudioTypography.labelSmall)
                                .foregroundStyle(Color.studioSecondary)

                            Text("\(Int(percentage))%")
                                .font(StudioTypography.labelSmall)
                                .foregroundStyle(isSelected ? Color.studioChrome : Color.studioMuted)
                        }
                    } else if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.studioChrome)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
            }
            .frame(height: 44)
            .background(Color.studioSurface)
            .overlay {
                Rectangle()
                    .stroke(isSelected ? Color.studioChrome : Color.studioLine, lineWidth: isSelected ? 1 : 0.5)
            }
        }
        .buttonStyle(.plain)
        .disabled(showResults)
    }
}

// MARK: - Create Poll Sheet

/// Sheet for creating a new poll
struct CreatePollSheet: View {
    let guests: [PartyGuest]
    var onCreate: ((String, PollType, [String]) -> Void)?

    @Environment(\.dismiss) private var dismiss

    @State private var selectedType: PollType = .custom
    @State private var question = ""
    @State private var options: [String] = ["", ""]
    @State private var selectedUsers: Set<UUID> = []

    // Preset poll types
    private let presetPolls: [(PollType, String)] = [
        (.partyMVP, "WHO'S THE PARTY MVP?"),
        (.bestDressed, "WHO'S BEST DRESSED?"),
        (.bestMoment, "BEST MOMENT OF THE NIGHT?"),
        (.custom, "CUSTOM QUESTION")
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button {
                    dismiss()
                } label: {
                    Text("CANCEL")
                        .font(StudioTypography.labelMedium)
                        .foregroundStyle(Color.studioMuted)
                }
                .buttonStyle(.plain)

                Spacer()

                Text("NEW POLL")
                    .font(StudioTypography.headlineSmall)
                    .foregroundStyle(Color.studioPrimary)

                Spacer()

                Button {
                    createPoll()
                } label: {
                    Text("CREATE")
                        .font(StudioTypography.labelMedium)
                        .foregroundStyle(isValid ? Color.studioChrome : Color.studioMuted)
                }
                .buttonStyle(.plain)
                .disabled(!isValid)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Color.studioLine)
                    .frame(height: 0.5)
            }

            ScrollView {
                VStack(spacing: 24) {
                    // Poll type selector
                    VStack(alignment: .leading, spacing: 12) {
                        Text("POLL TYPE")
                            .font(StudioTypography.labelSmall)
                            .tracking(StudioTypography.trackingWide)
                            .foregroundStyle(Color.studioMuted)

                        VStack(spacing: 8) {
                            ForEach(presetPolls, id: \.0) { type, title in
                                pollTypeButton(type: type, title: title)
                            }
                        }
                    }

                    // Question (for custom polls)
                    if selectedType == .custom {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("QUESTION")
                                .font(StudioTypography.labelSmall)
                                .tracking(StudioTypography.trackingWide)
                                .foregroundStyle(Color.studioMuted)

                            TextField("", text: $question, prompt: Text("Ask something...")
                                .foregroundStyle(Color.studioMuted))
                                .font(StudioTypography.bodyMedium)
                                .foregroundStyle(Color.studioPrimary)
                                .padding(12)
                                .background(Color.studioDeepBlack)
                                .overlay {
                                    Rectangle()
                                        .stroke(Color.studioLine, lineWidth: 0.5)
                                }
                        }
                    }

                    // Options
                    VStack(alignment: .leading, spacing: 12) {
                        Text(selectedType.isPeoplePoll ? "SELECT PEOPLE" : "OPTIONS")
                            .font(StudioTypography.labelSmall)
                            .tracking(StudioTypography.trackingWide)
                            .foregroundStyle(Color.studioMuted)

                        if selectedType.isPeoplePoll {
                            // People selector
                            peoplePicker
                        } else {
                            // Text options
                            VStack(spacing: 8) {
                                ForEach(0..<options.count, id: \.self) { index in
                                    HStack(spacing: 8) {
                                        TextField("", text: $options[index], prompt: Text("Option \(index + 1)")
                                            .foregroundStyle(Color.studioMuted))
                                            .font(StudioTypography.bodySmall)
                                            .foregroundStyle(Color.studioPrimary)
                                            .padding(12)
                                            .background(Color.studioDeepBlack)
                                            .overlay {
                                                Rectangle()
                                                    .stroke(Color.studioLine, lineWidth: 0.5)
                                            }

                                        if options.count > 2 {
                                            Button {
                                                options.remove(at: index)
                                            } label: {
                                                Image(systemName: "xmark")
                                                    .font(.system(size: 12, weight: .light))
                                                    .foregroundStyle(Color.studioMuted)
                                                    .frame(width: 44, height: 44)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }

                                if options.count < 6 {
                                    Button {
                                        options.append("")
                                    } label: {
                                        HStack(spacing: 8) {
                                            Image(systemName: "plus")
                                                .font(.system(size: 12, weight: .light))
                                            Text("ADD OPTION")
                                                .font(StudioTypography.labelSmall)
                                                .tracking(StudioTypography.trackingWide)
                                        }
                                        .foregroundStyle(Color.studioMuted)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 44)
                                        .background(Color.studioDeepBlack)
                                        .overlay {
                                            Rectangle()
                                                .stroke(Color.studioLine.opacity(0.5), lineWidth: 0.5)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                .padding(16)
            }
        }
        .background(Color.studioSurface)
    }

    private func pollTypeButton(type: PollType, title: String) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedType = type
                question = type == .custom ? "" : title
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: type.icon)
                    .font(.system(size: 16, weight: .light))
                    .foregroundStyle(selectedType == type ? Color.studioChrome : Color.studioMuted)

                Text(title)
                    .font(StudioTypography.labelMedium)
                    .tracking(StudioTypography.trackingNormal)
                    .foregroundStyle(selectedType == type ? Color.studioPrimary : Color.studioSecondary)

                Spacer()

                if selectedType == type {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.studioChrome)
                }
            }
            .padding(12)
            .background(selectedType == type ? Color.studioDeepBlack : Color.studioSurface)
            .overlay {
                Rectangle()
                    .stroke(selectedType == type ? Color.studioChrome : Color.studioLine, lineWidth: selectedType == type ? 1 : 0.5)
            }
        }
        .buttonStyle(.plain)
    }

    private var peoplePicker: some View {
        VStack(spacing: 8) {
            ForEach(guests) { guest in
                if let user = guest.user {
                    Button {
                        if selectedUsers.contains(user.id) {
                            selectedUsers.remove(user.id)
                        } else {
                            selectedUsers.insert(user.id)
                        }
                    } label: {
                        HStack(spacing: 12) {
                            AvatarView(url: user.avatarUrl, size: .small)

                            Text(user.displayName ?? user.username)
                                .font(StudioTypography.labelMedium)
                                .foregroundStyle(Color.studioPrimary)

                            Spacer()

                            if selectedUsers.contains(user.id) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(Color.studioChrome)
                            }
                        }
                        .padding(12)
                        .background(selectedUsers.contains(user.id) ? Color.studioDeepBlack : Color.studioSurface)
                        .overlay {
                            Rectangle()
                                .stroke(selectedUsers.contains(user.id) ? Color.studioChrome : Color.studioLine, lineWidth: 0.5)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var isValid: Bool {
        if selectedType.isPeoplePoll {
            return selectedUsers.count >= 2
        } else {
            let validOptions = options.filter { !$0.isEmpty }
            return validOptions.count >= 2 && (!question.isEmpty || selectedType != .custom)
        }
    }

    private func createPoll() {
        let finalQuestion = selectedType == .custom ? question : selectedType.defaultQuestion
        let finalOptions = selectedType.isPeoplePoll
            ? Array(selectedUsers).map { $0.uuidString }
            : options.filter { !$0.isEmpty }

        onCreate?(finalQuestion, selectedType, finalOptions)
    }
}

// MARK: - Poll Type Extensions

extension PollType {
    var displayName: String {
        switch self {
        case .partyMVP: return "PARTY MVP"
        case .bestDressed: return "BEST DRESSED"
        case .bestMoment: return "BEST MOMENT"
        case .custom: return "CUSTOM"
        case .singleChoice: return "SINGLE CHOICE"
        case .multipleChoice: return "MULTIPLE CHOICE"
        }
    }

    var icon: String {
        switch self {
        case .partyMVP: return "star.fill"
        case .bestDressed: return "sparkles"
        case .bestMoment: return "camera.fill"
        case .custom, .singleChoice, .multipleChoice: return "chart.bar"
        }
    }

    var isPeoplePoll: Bool {
        switch self {
        case .partyMVP, .bestDressed: return true
        case .bestMoment, .custom, .singleChoice, .multipleChoice: return false
        }
    }

    var defaultQuestion: String {
        switch self {
        case .partyMVP: return "Who's the party MVP?"
        case .bestDressed: return "Who's best dressed?"
        case .bestMoment: return "Best moment of the night?"
        case .custom, .singleChoice, .multipleChoice: return ""
        }
    }
}

// MARK: - Preview

#Preview("Polls Sheet") {
    PartyPollsSheet(
        partyId: UUID(),
        polls: MockData.partyPolls,
        guests: [],
        isLoading: false
    )
}

#Preview("Polls Sheet - Empty") {
    PartyPollsSheet(
        partyId: UUID(),
        polls: [],
        guests: [],
        isLoading: false
    )
}

#Preview("Create Poll") {
    CreatePollSheet(guests: [])
}
