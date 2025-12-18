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
    var isLoadingStatuses = false
    var error: Error?
    var showError = false

    var selectedSection: PartySection = .media

    // Cached current user ID (loaded async)
    private var cachedCurrentUserId: UUID?

    // Computed properties for convenience
    var guests: [PartyGuest] {
        party.guests ?? []
    }

    var currentUserStatus: PartyStatus? {
        guard let userId = cachedCurrentUserId else { return nil }
        return statuses.first { $0.userId == userId }
    }

    private let partyService = PartyService()
    private let mediaService = MediaService()
    private let socialService = SocialService()
    private let realtimeService = RealtimeService.shared

    private var mediaOffset = 0
    private var commentsOffset = 0
    private let pageSize = 20
    private var isSubscribedToRealtime = false

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

        // Cache current user ID
        cachedCurrentUserId = await AuthService.shared.currentUserId()

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

    /// Alias for postStatus for compatibility
    func updateStatus(type: StatusType, value: Int, message: String?) async {
        await postStatus(type: type, value: value, message: message)
    }

    func loadPolls() async {
        do {
            polls = try await socialService.getPolls(partyId: party.id)
        } catch {
            self.error = error
            showError = true
        }
    }

    func loadGuests() async {
        do {
            let updatedParty = try await partyService.getParty(id: party.id)
            party = updatedParty
        } catch {
            self.error = error
            showError = true
        }
    }

    func refreshMedia() async {
        do {
            mediaOffset = 0
            media = try await mediaService.getPartyMedia(partyId: party.id, limit: pageSize, offset: 0)
            mediaOffset = pageSize
        } catch {
            self.error = error
            showError = true
        }
    }

    func endParty() async {
        do {
            try await partyService.endParty(id: party.id)
            party.status = .ended
        } catch {
            self.error = error
            showError = true
        }
    }

    // MARK: - Realtime Subscriptions

    /// Subscribe to realtime updates for this party
    func subscribeToRealtimeUpdates() async {
        guard !isSubscribedToRealtime else { return }
        isSubscribedToRealtime = true

        log.info("Subscribing to realtime for party: \(party.id)", category: .realtime)

        await realtimeService.subscribeToParty(
            party.id,
            onComment: { [weak self] comment, action in
                self?.handleCommentUpdate(comment, action: action)
            },
            onStatus: { [weak self] status, action in
                self?.handleStatusUpdate(status, action: action)
            },
            onPollVote: { [weak self] vote, action in
                self?.handlePollVoteUpdate(vote, action: action)
            },
            onGuestUpdate: { [weak self] guest, action in
                self?.handleGuestUpdate(guest, action: action)
            }
        )
    }

    /// Unsubscribe from realtime updates
    func unsubscribeFromRealtimeUpdates() async {
        guard isSubscribedToRealtime else { return }
        isSubscribedToRealtime = false

        log.info("Unsubscribing from realtime for party: \(party.id)", category: .realtime)
        await realtimeService.unsubscribeFromParty(party.id)
    }

    // MARK: - Realtime Handlers

    private func handleCommentUpdate(_ comment: PartyComment, action: ChangeAction) {
        switch action {
        case .insert:
            // Add new comment if not already present
            if !comments.contains(where: { $0.id == comment.id }) {
                comments.insert(comment, at: 0)
                log.debug("New comment received: \(comment.id)", category: .realtime)
            }
        case .update:
            // Update existing comment
            if let index = comments.firstIndex(where: { $0.id == comment.id }) {
                comments[index] = comment
            }
        case .delete:
            // Remove deleted comment
            comments.removeAll { $0.id == comment.id }
        }
    }

    private func handleStatusUpdate(_ status: PartyStatus, action: ChangeAction) {
        switch action {
        case .insert:
            // Replace existing status from same user or add new
            statuses.removeAll { $0.userId == status.userId && $0.statusType == status.statusType }
            statuses.insert(status, at: 0)
            log.debug("New status received: \(status.statusType.label)", category: .realtime)
        case .update:
            if let index = statuses.firstIndex(where: { $0.id == status.id }) {
                statuses[index] = status
            }
        case .delete:
            statuses.removeAll { $0.id == status.id }
        }
    }

    private func handlePollVoteUpdate(_ vote: PollVote, action: ChangeAction) {
        // Filter: Only process votes for this party's polls
        // (Realtime subscriptions receive ALL poll_votes, not just this party's)
        guard polls.contains(where: { $0.id == vote.pollId }) else {
            log.debug("Ignoring poll vote from different party", category: .realtime)
            return
        }

        // Refresh polls to get updated vote counts
        Task {
            do {
                polls = try await socialService.getPolls(partyId: party.id)
                log.debug("Poll votes updated", category: .realtime)
            } catch {
                log.error(error, category: .realtime)
            }
        }
    }

    private func handleGuestUpdate(_ guest: PartyGuest, action: ChangeAction) {
        switch action {
        case .insert:
            if var guests = party.guests, !guests.contains(where: { $0.id == guest.id }) {
                guests.append(guest)
                party.guests = guests
                log.debug("New guest added: \(guest.id)", category: .realtime)
            }
        case .update:
            if var guests = party.guests,
               let index = guests.firstIndex(where: { $0.id == guest.id }) {
                guests[index] = guest
                party.guests = guests
            }
        case .delete:
            party.guests?.removeAll { $0.id == guest.id }
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

    var shareURL: URL {
        // Deep link URL for sharing party
        URL(string: "studio://party/\(party.id.uuidString)")!
    }
}
