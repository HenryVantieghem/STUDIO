//
//  PartyPostView.swift
//  STUDIO
//
//  Instagram-style Party Post
//  Basel Afterdark Design System
//

import SwiftUI

// MARK: - Party Post View

/// Instagram-style party post with hosts, media carousel, and action bar
struct PartyPostView: View {
    let party: Party
    @State private var vm: PartyPostViewModel

    // Sheet states
    @State private var showComments = false
    @State private var showPolls = false
    @State private var showStatus = false
    @State private var showAddMedia = false
    @State private var showEditParty = false

    init(party: Party) {
        self.party = party
        self._vm = State(initialValue: PartyPostViewModel(party: party))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Hosts header (like Instagram username)
            PartyHostsHeader(
                hosts: party.hosts ?? [],
                isActive: party.isActive,
                onMoreTapped: { showEditParty = true }
            )

            // Media carousel (swipeable photos/videos)
            PartyMediaCarousel(
                media: vm.media,
                isLoading: vm.isLoadingMedia
            )

            // Action bar (add media, comments, polls, status)
            PartyActionBar(
                mediaCount: vm.media.count,
                commentCount: vm.commentCount,
                pollCount: vm.activePolls.count,
                statusCount: vm.statuses.count,
                onAddMedia: { showAddMedia = true },
                onComments: { showComments = true },
                onPolls: { showPolls = true },
                onStatus: { showStatus = true }
            )

            // Party details (title, location, date, description)
            PartyDetailsSection(party: party)
        }
        .background(Color.studioBlack)
        .overlay {
            Rectangle()
                .stroke(Color.studioLine, lineWidth: 0.5)
        }
        .task {
            await vm.loadPartyData()
        }
        .sheet(isPresented: $showComments) {
            PartyCommentsSheet(
                partyId: party.id,
                comments: vm.comments,
                isLoading: vm.isLoadingComments,
                onAddComment: { content in
                    Task { await vm.addComment(content) }
                },
                onLikeComment: { commentId in
                    Task { await vm.likeComment(commentId) }
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationBackground(Color.studioSurface)
        }
        .sheet(isPresented: $showPolls) {
            PartyPollsSheet(
                partyId: party.id,
                polls: vm.polls,
                guests: party.guests ?? [],
                isLoading: vm.isLoadingPolls,
                onVote: { pollId, optionId in
                    Task { await vm.vote(pollId: pollId, optionId: optionId) }
                },
                onCreatePoll: { question, pollType, options in
                    Task { await vm.createPoll(question: question, pollType: pollType, options: options) }
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationBackground(Color.studioSurface)
        }
        .sheet(isPresented: $showStatus) {
            PartyStatusSheet(
                partyId: party.id,
                statuses: vm.statuses,
                currentUserStatus: vm.currentUserStatus,
                isLoading: vm.isLoadingStatuses,
                onUpdateStatus: { type, value, message in
                    Task { await vm.updateStatus(type: type, value: value, message: message) }
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationBackground(Color.studioSurface)
        }
        .sheet(isPresented: $showAddMedia) {
            AddMediaSheet(
                partyId: party.id,
                onMediaAdded: { mediaType, data, caption in
                    Task { await vm.addMedia(type: mediaType, data: data, caption: caption) }
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationBackground(Color.studioBlack)
        }
        .sheet(isPresented: $showEditParty) {
            PartyEditSheet(party: party)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color.studioSurface)
        }
    }
}

// MARK: - Party Hosts Header

/// Header showing hosts avatars and names (like Instagram post header)
struct PartyHostsHeader: View {
    let hosts: [PartyHost]
    var isActive: Bool = false
    var onMoreTapped: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            // Hosts avatars (overlapping)
            hostsAvatars

            // Host names and role
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(hostNames)
                        .font(StudioTypography.labelMedium)
                        .tracking(StudioTypography.trackingNormal)
                        .textCase(.uppercase)
                        .foregroundStyle(Color.studioPrimary)
                        .lineLimit(1)

                    // Verified badge for creator
                    if hosts.contains(where: { $0.role == .creator }) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.studioChrome)
                    }
                }

                HStack(spacing: 8) {
                    Text(hosts.count == 1 ? "HOST" : "\(hosts.count) HOSTS")
                        .font(StudioTypography.labelSmall)
                        .tracking(StudioTypography.trackingNormal)
                        .foregroundStyle(Color.studioMuted)

                    if isActive {
                        HStack(spacing: 4) {
                            Rectangle()
                                .fill(Color.studioChrome)
                                .frame(width: 4, height: 4)

                            Text("LIVE")
                                .font(StudioTypography.labelSmall)
                                .tracking(StudioTypography.trackingWide)
                                .foregroundStyle(Color.studioChrome)
                        }
                    }
                }
            }

            Spacer()

            // More button
            Button {
                onMoreTapped?()
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 14, weight: .light))
                    .foregroundStyle(Color.studioMuted)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.studioSurface)
    }

    private var hostsAvatars: some View {
        HStack(spacing: -8) {
            ForEach(Array(hosts.prefix(3).enumerated()), id: \.element.id) { index, host in
                AvatarView(
                    url: host.user?.avatarUrl,
                    size: .medium,
                    showBorder: true,
                    borderColor: .studioSurface
                )
                .zIndex(Double(3 - index))
            }
        }
    }

    private var hostNames: String {
        let names = hosts.compactMap { $0.user?.displayName ?? $0.user?.username }
        if names.isEmpty { return "Unknown Host" }
        if names.count == 1 { return names[0] }
        if names.count == 2 { return "\(names[0]) & \(names[1])" }
        return "\(names[0]) & \(names.count - 1) others"
    }
}

// MARK: - Party Details Section

/// Party details: title, location, date, description
struct PartyDetailsSection: View {
    let party: Party
    @State private var showFullDescription = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title
            Text(party.title)
                .font(StudioTypography.headlineSmall)
                .tracking(StudioTypography.trackingNormal)
                .textCase(.uppercase)
                .foregroundStyle(Color.studioPrimary)
                .lineLimit(2)

            // Location and date row
            HStack(spacing: 16) {
                if let location = party.location {
                    HStack(spacing: 6) {
                        Image(systemName: "location")
                            .font(.system(size: 10, weight: .light))
                        Text(location.uppercased())
                            .font(StudioTypography.labelSmall)
                            .tracking(StudioTypography.trackingNormal)
                            .lineLimit(1)
                    }
                    .foregroundStyle(Color.studioSecondary)
                }

                if let partyDate = party.partyDate {
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .font(.system(size: 10, weight: .light))
                        Text(formatPartyDate(partyDate).uppercased())
                            .font(StudioTypography.labelSmall)
                            .tracking(StudioTypography.trackingNormal)
                    }
                    .foregroundStyle(Color.studioSecondary)
                }
            }

            // Description (expandable)
            if let description = party.description, !description.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text(description)
                        .font(StudioTypography.bodySmall)
                        .tracking(StudioTypography.trackingNormal)
                        .foregroundStyle(Color.studioMuted)
                        .lineLimit(showFullDescription ? nil : 2)

                    if description.count > 100 {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showFullDescription.toggle()
                            }
                        } label: {
                            Text(showFullDescription ? "SHOW LESS" : "MORE")
                                .font(StudioTypography.labelSmall)
                                .tracking(StudioTypography.trackingNormal)
                                .foregroundStyle(Color.studioChrome)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Timestamp
            Text(formatTimestamp(party.createdAt).uppercased())
                .font(StudioTypography.labelSmall)
                .tracking(StudioTypography.trackingNormal)
                .foregroundStyle(Color.studioMuted.opacity(0.6))
                .padding(.top, 4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.studioSurface)
    }

    private func formatPartyDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let formatter = DateFormatter()

        if calendar.isDateInToday(date) {
            formatter.dateFormat = "'Today,' h:mm a"
        } else if calendar.isDateInTomorrow(date) {
            formatter.dateFormat = "'Tomorrow,' h:mm a"
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            formatter.dateFormat = "EEEE, h:mm a"
        } else {
            formatter.dateFormat = "MMM d, h:mm a"
        }

        return formatter.string(from: date)
    }

    private func formatTimestamp(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Preview

#Preview("Party Post") {
    ScrollView {
        VStack(spacing: 24) {
            PartyPostView(party: MockData.activeParties[0])
            PartyPostView(party: MockData.activeParties[1])
        }
        .padding(.vertical, 16)
    }
    .background(Color.studioBlack)
}
