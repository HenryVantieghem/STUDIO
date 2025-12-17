//
//  PartyDetailViewModel.swift
//  STUDIO
//
//  Created by Claude on 12/16/25.
//

import Foundation

// MARK: - Party Detail ViewModel

@Observable
@MainActor
final class PartyDetailViewModel {
    // MARK: - Properties

    var party: Party
    var media: [PartyMedia] = []
    var comments: [PartyComment] = []
    var polls: [PartyPoll] = []
    var statuses: [PartyStatus] = []

    var isLoading = false
    var isLoadingMore = false
    var error: Error?
    var showError = false

    var selectedSection: PartySection = .media

    private let partyService = PartyService()
    private let mediaService = MediaService()
    private let socialService = SocialService()

    private var mediaOffset = 0
    private var commentsOffset = 0
    private let pageSize = 20

    // MARK: - Sections

    enum PartySection: String, CaseIterable, Identifiable {
        case media = "Media"
        case comments = "Chat"
        case polls = "Polls"
        case vibes = "Vibes"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .media: return "photo.on.rectangle"
            case .comments: return "bubble.left.and.bubble.right"
            case .polls: return "chart.bar"
            case .vibes: return "sparkles"
            }
        }
    }

    // MARK: - Init

    init(party: Party) {
        self.party = party
    }

    // MARK: - Load Data

    func loadPartyDetails() async {
        guard !isLoading else { return }
        isLoading = true
        error = nil

        do {
            // Refresh party details
            party = try await partyService.getParty(id: party.id)

            // Load all sections in parallel
            async let mediaTask = mediaService.getPartyMedia(partyId: party.id, limit: pageSize, offset: 0)
            async let commentsTask = socialService.getComments(partyId: party.id, limit: pageSize, offset: 0)
            async let pollsTask = socialService.getPolls(partyId: party.id)
            async let statusesTask = socialService.getLatestStatuses(partyId: party.id)

            let (loadedMedia, loadedComments, loadedPolls, loadedStatuses) = try await (
                mediaTask, commentsTask, pollsTask, statusesTask
            )

            media = loadedMedia
            comments = loadedComments
            polls = loadedPolls
            statuses = loadedStatuses

            mediaOffset = pageSize
            commentsOffset = pageSize
        } catch {
            self.error = error
            showError = true
        }

        isLoading = false
    }

    func refreshParty() async {
        mediaOffset = 0
        commentsOffset = 0
        await loadPartyDetails()
    }

    // MARK: - Load More

    func loadMoreMedia() async {
        guard !isLoadingMore else { return }
        isLoadingMore = true

        do {
            let moreMedia = try await mediaService.getPartyMedia(
                partyId: party.id,
                limit: pageSize,
                offset: mediaOffset
            )
            media.append(contentsOf: moreMedia)
            mediaOffset += pageSize
        } catch {
            self.error = error
            showError = true
        }

        isLoadingMore = false
    }

    func loadMoreComments() async {
        guard !isLoadingMore else { return }
        isLoadingMore = true

        do {
            let moreComments = try await socialService.getComments(
                partyId: party.id,
                limit: pageSize,
                offset: commentsOffset
            )
            comments.append(contentsOf: moreComments)
            commentsOffset += pageSize
        } catch {
            self.error = error
            showError = true
        }

        isLoadingMore = false
    }

    // MARK: - Actions

    func addComment(_ content: String) async {
        do {
            let newComment = try await socialService.addComment(
                partyId: party.id,
                content: content
            )
            comments.insert(newComment, at: 0)
        } catch {
            self.error = error
            showError = true
        }
    }

    func deleteComment(_ comment: PartyComment) async {
        do {
            try await socialService.deleteComment(commentId: comment.id)
            comments.removeAll { $0.id == comment.id }
        } catch {
            self.error = error
            showError = true
        }
    }

    func vote(on poll: PartyPoll, optionId: UUID) async {
        do {
            try await socialService.vote(pollId: poll.id, optionId: optionId)
            // Refresh polls to get updated counts
            polls = try await socialService.getPolls(partyId: party.id)
        } catch {
            self.error = error
            showError = true
        }
    }

    func postStatus(type: StatusType, value: Int, message: String?) async {
        do {
            let newStatus = try await socialService.postStatus(
                partyId: party.id,
                statusType: type,
                value: value,
                message: message
            )
            // Insert at beginning and filter duplicates per user
            statuses = [newStatus] + statuses.filter { $0.userId != newStatus.userId }
        } catch {
            self.error = error
            showError = true
        }
    }

    func endParty() async {
        do {
            try await partyService.endParty(id: party.id)
            party.isActive = false
        } catch {
            self.error = error
            showError = true
        }
    }

    // MARK: - Computed Properties

    var isHost: Bool {
        // This would check against current user ID
        party.hosts?.contains { _ in true } ?? false
    }

    var hostNames: String {
        guard let hosts = party.hosts else { return "" }
        let names = hosts.compactMap { $0.user?.displayName }
        switch names.count {
        case 0: return ""
        case 1: return names[0]
        case 2: return "\(names[0]) & \(names[1])"
        default: return "\(names[0]), \(names[1]) + \(names.count - 2) more"
        }
    }

    var guestCount: Int {
        party.guests?.filter { $0.status == .accepted }.count ?? 0
    }

    var averageVibeLevel: Int {
        guard !statuses.isEmpty else { return 0 }
        let vibeStatuses = statuses.filter { $0.statusType == .vibeCheck || $0.statusType == .drunkMeter }
        guard !vibeStatuses.isEmpty else { return 0 }
        return vibeStatuses.map(\.value).reduce(0, +) / vibeStatuses.count
    }
}
