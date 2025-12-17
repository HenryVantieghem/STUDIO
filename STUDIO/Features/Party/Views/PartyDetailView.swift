//
//  PartyDetailView.swift
//  STUDIO
//
//  Basel Afterdark Design System
//  Dark luxury, minimal techno, retro-futuristic nightlife
//

import SwiftUI

// MARK: - Party Detail View

struct PartyDetailView: View {
    let party: Party
    @State private var vm: PartyDetailViewModel

    @State private var showAddMedia = false
    @State private var showCreatePoll = false
    @State private var showStatusPicker = false
    @State private var newComment = ""

    @Environment(\.dismiss) private var dismiss

    init(party: Party) {
        self.party = party
        self._vm = State(initialValue: PartyDetailViewModel(party: party))
    }

    var body: some View {
        ZStack {
            Color.studioBlack
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    headerSection

                    // Section picker
                    sectionPicker
                        .padding(.horizontal, 24)
                        .padding(.top, 20)

                    // Content based on selected section
                    sectionContent
                        .padding(.top, 20)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    if vm.isHost {
                        Button {
                            showAddMedia = true
                        } label: {
                            Label("ADD MEDIA", systemImage: "photo.badge.plus")
                        }

                        Button {
                            showCreatePoll = true
                        } label: {
                            Label("CREATE POLL", systemImage: "chart.bar.doc.horizontal")
                        }

                        Divider()

                        Button(role: .destructive) {
                            Task { await vm.endParty() }
                        } label: {
                            Label("END PARTY", systemImage: "stop.circle")
                        }
                    }

                    Button {
                        // Share party
                    } label: {
                        Label("SHARE", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14, weight: .light))
                        .foregroundStyle(Color.studioChrome)
                        .frame(width: 36, height: 36)
                        .background(Color.studioSurface)
                        .overlay {
                            Rectangle()
                                .stroke(Color.studioLine, lineWidth: 0.5)
                        }
                }
            }
        }
        .refreshable {
            await vm.refreshParty()
        }
        .task {
            await vm.loadPartyDetails()
        }
        .alert("ERROR", isPresented: $vm.showError) {
            Button("OK") { vm.showError = false }
        } message: {
            Text(vm.error?.localizedDescription ?? "An error occurred")
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        ZStack(alignment: .bottomLeading) {
            // Cover image or geometric pattern
            if let coverUrl = vm.party.coverImageUrl, URL(string: coverUrl) != nil {
                StudioAsyncImage(url: coverUrl)
                    .frame(height: 300)
                    .clipped()
            } else {
                // Geometric pattern
                ZStack {
                    Color.studioSurface

                    // Grid pattern
                    GeometryReader { geo in
                        Path { path in
                            let spacing: CGFloat = 50
                            for x in stride(from: 0, to: geo.size.width, by: spacing) {
                                path.move(to: CGPoint(x: x, y: 0))
                                path.addLine(to: CGPoint(x: x, y: geo.size.height))
                            }
                            for y in stride(from: 0, to: geo.size.height, by: spacing) {
                                path.move(to: CGPoint(x: 0, y: y))
                                path.addLine(to: CGPoint(x: geo.size.width, y: y))
                            }
                        }
                        .stroke(Color.studioLine.opacity(0.3), lineWidth: 0.5)
                    }
                }
                .frame(height: 300)
            }

            // Gradient overlay
            LinearGradient(
                colors: [.clear, Color.studioBlack],
                startPoint: .center,
                endPoint: .bottom
            )

            // Party info
            VStack(alignment: .leading, spacing: 12) {
                // Active indicator
                if vm.party.isActive {
                    HStack(spacing: 8) {
                        Rectangle()
                            .fill(Color.studioChrome)
                            .frame(width: 6, height: 6)
                        Text("LIVE")
                            .font(StudioTypography.labelSmall)
                            .tracking(StudioTypography.trackingWide)
                            .foregroundStyle(Color.studioChrome)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.studioBlack.opacity(0.8))
                    .overlay {
                        Rectangle()
                            .stroke(Color.studioLine, lineWidth: 0.5)
                    }
                }

                Text(vm.party.title.uppercased())
                    .font(StudioTypography.headlineLarge)
                    .tracking(StudioTypography.trackingWide)
                    .foregroundStyle(Color.studioPrimary)

                // Hosts
                Text("HOSTED BY \(vm.hostNames.uppercased())")
                    .font(StudioTypography.bodySmall)
                    .tracking(StudioTypography.trackingNormal)
                    .foregroundStyle(Color.studioSecondary)

                // Location and date
                HStack(spacing: 20) {
                    if let location = vm.party.location {
                        HStack(spacing: 6) {
                            Image(systemName: "location")
                                .font(.system(size: 10, weight: .light))
                            Text(location.uppercased())
                                .font(StudioTypography.labelSmall)
                                .tracking(StudioTypography.trackingNormal)
                        }
                        .foregroundStyle(Color.studioMuted)
                    }

                    if let date = vm.party.partyDate {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .font(.system(size: 10, weight: .light))
                            Text(date, style: .date)
                                .font(StudioTypography.labelSmall)
                        }
                        .foregroundStyle(Color.studioMuted)
                    }
                }

                // Stats row
                HStack(spacing: 24) {
                    statItem(value: "\(vm.guestCount)", label: "GUESTS", icon: "person.2")
                    statItem(value: "\(vm.media.count)", label: "MEDIA", icon: "photo")
                    statItem(value: "\(vm.comments.count)", label: "COMMENTS", icon: "bubble.left")

                    if vm.averageVibeLevel > 0 {
                        statItem(
                            value: VibeLevel(rawValue: vm.averageVibeLevel)?.emoji ?? "",
                            label: "VIBE",
                            icon: nil
                        )
                    }
                }
                .padding(.top, 12)
            }
            .padding(24)
        }
    }

    private func statItem(value: String, label: String, icon: String?) -> some View {
        VStack(spacing: 6) {
            if let icon {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 10, weight: .light))
                    Text(value)
                        .font(StudioTypography.headlineSmall)
                }
            } else {
                Text(value)
                    .font(.system(size: 24))
            }
            Text(label)
                .font(StudioTypography.labelSmall)
                .tracking(StudioTypography.trackingNormal)
                .foregroundStyle(Color.studioMuted)
        }
        .foregroundStyle(Color.studioPrimary)
    }

    // MARK: - Section Picker

    private var sectionPicker: some View {
        HStack(spacing: 0) {
            ForEach(PartyDetailViewModel.PartySection.allCases) { section in
                Button {
                    HapticManager.shared.impact(.light)
                    withAnimation(.easeInOut(duration: 0.2)) {
                        vm.selectedSection = section
                    }
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: section.icon)
                            .font(.system(size: 16, weight: .ultraLight))
                        Text(section.rawValue.uppercased())
                            .font(StudioTypography.labelSmall)
                            .tracking(StudioTypography.trackingNormal)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .foregroundStyle(
                        vm.selectedSection == section ? Color.studioChrome : Color.studioMuted
                    )
                    .background {
                        if vm.selectedSection == section {
                            Rectangle()
                                .fill(Color.studioChrome)
                                .frame(height: 0.5)
                                .frame(maxHeight: .infinity, alignment: .bottom)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .background(Color.studioSurface)
        .overlay {
            Rectangle()
                .stroke(Color.studioLine, lineWidth: 0.5)
        }
    }

    // MARK: - Section Content

    @ViewBuilder
    private var sectionContent: some View {
        switch vm.selectedSection {
        case .media:
            mediaSection
        case .comments:
            commentsSection
        case .polls:
            pollsSection
        case .vibes:
            vibesSection
        }
    }

    // MARK: - Media Section

    private var mediaSection: some View {
        Group {
            if vm.media.isEmpty {
                EmptyStateView(
                    icon: "photo.on.rectangle",
                    title: "NO MEDIA YET",
                    message: "BE THE FIRST TO SHARE A MOMENT",
                    actionTitle: vm.isHost ? "ADD MEDIA" : nil,
                    action: vm.isHost ? { showAddMedia = true } : nil
                )
                .padding(24)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 2),
                    GridItem(.flexible(), spacing: 2),
                    GridItem(.flexible(), spacing: 2)
                ], spacing: 2) {
                    ForEach(vm.media) { item in
                        PartyMediaThumbnail(media: item)
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }

    // MARK: - Comments Section

    private var commentsSection: some View {
        VStack(spacing: 0) {
            // Comment input
            HStack(spacing: 16) {
                TextField("", text: $newComment, prompt: Text("ADD A COMMENT")
                    .font(StudioTypography.bodySmall)
                    .foregroundStyle(Color.studioMuted.opacity(0.5)))
                    .font(StudioTypography.bodySmall)
                    .padding(16)
                    .background(Color.studioSurface)
                    .overlay {
                        Rectangle()
                            .stroke(Color.studioLine, lineWidth: 0.5)
                    }
                    .foregroundStyle(Color.studioPrimary)

                Button {
                    guard !newComment.isEmpty else { return }
                    HapticManager.shared.impact(.medium)
                    let comment = newComment
                    newComment = ""
                    Task { await vm.addComment(comment) }
                } label: {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 14, weight: .light))
                        .foregroundStyle(newComment.isEmpty ? Color.studioMuted : Color.studioChrome)
                        .frame(width: 44, height: 44)
                        .background(newComment.isEmpty ? Color.studioSurface : Color.studioChrome.opacity(0.2))
                        .overlay {
                            Rectangle()
                                .stroke(Color.studioLine, lineWidth: 0.5)
                        }
                }
                .disabled(newComment.isEmpty)
            }
            .padding(24)

            Rectangle()
                .fill(Color.studioLine)
                .frame(height: 0.5)

            // Comments list
            if vm.comments.isEmpty {
                EmptyStateView(
                    icon: "bubble.left.and.bubble.right",
                    title: "NO COMMENTS YET",
                    message: "START THE CONVERSATION"
                )
                .padding(24)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(vm.comments) { comment in
                        CommentRow(comment: comment)
                        Rectangle()
                            .fill(Color.studioLine)
                            .frame(height: 0.5)
                            .padding(.leading, 72)
                    }
                }
            }
        }
    }

    // MARK: - Polls Section

    private var pollsSection: some View {
        Group {
            if vm.polls.isEmpty {
                EmptyStateView(
                    icon: "chart.bar",
                    title: "NO POLLS YET",
                    message: "CREATE A POLL TO GET THE PARTY VOTING",
                    actionTitle: vm.isHost ? "CREATE POLL" : nil,
                    action: vm.isHost ? { showCreatePoll = true } : nil
                )
                .padding(24)
            } else {
                LazyVStack(spacing: 20) {
                    ForEach(vm.polls) { poll in
                        PollCard(poll: poll) { optionId in
                            Task { await vm.vote(on: poll, optionId: optionId) }
                        }
                    }
                }
                .padding(24)
            }
        }
    }

    // MARK: - Vibes Section

    private var vibesSection: some View {
        VStack(spacing: 24) {
            // Update status button
            Button {
                HapticManager.shared.impact(.medium)
                showStatusPicker = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .light))
                    Text("UPDATE YOUR VIBE")
                        .font(StudioTypography.labelLarge)
                        .tracking(StudioTypography.trackingWide)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
            }
            .buttonStyle(.studioPrimary)
            .padding(.horizontal, 24)

            // Status list
            if vm.statuses.isEmpty {
                EmptyStateView(
                    icon: "sparkles",
                    title: "NO VIBES YET",
                    message: "BE THE FIRST TO SHARE YOUR VIBE"
                )
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(vm.statuses) { status in
                        StatusRow(status: status)
                    }
                }
                .padding(.horizontal, 24)
            }
        }
        .padding(.top, 4)
    }
}

// MARK: - Supporting Views

struct PartyMediaThumbnail: View {
    let media: PartyMedia

    var body: some View {
        ZStack {
            StudioAsyncImage(
                url: media.thumbnailUrl ?? media.url,
                contentMode: .fill
            )

            if media.mediaType == .video {
                Image(systemName: "play")
                    .font(.system(size: 20, weight: .ultraLight))
                    .foregroundStyle(Color.studioPrimary.opacity(0.8))
                    .frame(width: 44, height: 44)
                    .background(Color.studioBlack.opacity(0.6))
                    .overlay {
                        Rectangle()
                            .stroke(Color.studioLine, lineWidth: 0.5)
                    }
            }
        }
        .aspectRatio(1, contentMode: .fill)
    }
}

struct StatusRow: View {
    let status: PartyStatus

    var vibeLevel: VibeLevel? {
        VibeLevel(rawValue: status.value)
    }

    var body: some View {
        HStack(spacing: 16) {
            AvatarView(url: status.user?.avatarUrl, size: .medium)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text((status.user?.displayName ?? "USER").uppercased())
                        .font(StudioTypography.labelSmall)
                        .tracking(StudioTypography.trackingNormal)
                        .foregroundStyle(Color.studioPrimary)

                    Text(status.createdAt, style: .relative)
                        .font(StudioTypography.labelSmall)
                        .foregroundStyle(Color.studioMuted)
                }

                if let message = status.message {
                    Text(message.uppercased())
                        .font(StudioTypography.labelSmall)
                        .tracking(StudioTypography.trackingNormal)
                        .foregroundStyle(Color.studioMuted)
                }
            }

            Spacer()

            // Vibe indicator
            if let vibe = vibeLevel {
                VStack(spacing: 4) {
                    Text(vibe.emoji)
                        .font(.system(size: 24))
                    Text(vibe.label.uppercased())
                        .font(StudioTypography.labelSmall)
                        .tracking(StudioTypography.trackingNormal)
                        .foregroundStyle(Color.studioMuted)
                }
            }
        }
        .padding(20)
        .background(Color.studioSurface)
        .overlay {
            Rectangle()
                .stroke(Color.studioLine, lineWidth: 0.5)
        }
    }
}

// MARK: - Preview

#Preview("Party Detail") {
    NavigationStack {
        PartyDetailView(party: Party(
            id: UUID(),
            createdAt: Date(),
            title: "Friday Night Disco",
            description: "Let's dance!",
            coverImageUrl: nil,
            location: "Studio 54",
            partyDate: Date(),
            endDate: nil,
            isActive: true,
            isPublic: false,
            maxGuests: 50,
            hosts: nil,
            guests: nil,
            mediaCount: 12,
            commentCount: 5
        ))
    }
}
