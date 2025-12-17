//
//  PartyPostViewModel.swift
//  STUDIO
//
//  ViewModel for Instagram-style party post
//  Basel Afterdark Design System
//

import Foundation
import Supabase

// MARK: - Party Post ViewModel

/// ViewModel for PartyPostView - manages media, comments, polls, and statuses
@Observable
@MainActor
final class PartyPostViewModel {
    // MARK: - State

    var media: [PartyMedia] = []
    var comments: [PartyComment] = []
    var polls: [PartyPoll] = []
    var statuses: [PartyStatus] = []

    var isLoadingMedia = false
    var isLoadingComments = false
    var isLoadingPolls = false
    var isLoadingStatuses = false

    var error: Error?
    var showError = false

    let party: Party

    // MARK: - Services

    private let mediaService = MediaService()
    private let socialService = SocialService()

    // MARK: - Computed Properties

    var commentCount: Int {
        comments.count
    }

    var activePolls: [PartyPoll] {
        polls.filter { $0.isActive == true }
    }

    private(set) var currentUserId: UUID?

    var currentUserStatus: PartyStatus? {
        guard let userId = currentUserId else { return nil }
        return statuses.first { $0.userId == userId }
    }

    /// Load current user ID asynchronously
    func loadCurrentUser() async {
        currentUserId = try? await supabase.auth.session.user.id
    }

    // MARK: - Initialization

    init(party: Party) {
        self.party = party
    }

    // MARK: - Load Data

    /// Load all party data in parallel
    func loadPartyData() async {
        // Load current user first
        await loadCurrentUser()

        // Set loading states
        isLoadingMedia = true
        isLoadingComments = true
        isLoadingPolls = true
        isLoadingStatuses = true

        do {
            // Parallel fetch all data
            async let mediaTask = mediaService.getPartyMedia(partyId: party.id, limit: 50)
            async let commentsTask = socialService.getComments(partyId: party.id, limit: 50)
            async let pollsTask = socialService.getPolls(partyId: party.id)
            async let statusesTask = socialService.getLatestStatuses(partyId: party.id)

            let (loadedMedia, loadedComments, loadedPolls, loadedStatuses) = try await (
                mediaTask, commentsTask, pollsTask, statusesTask
            )

            // Update state
            self.media = loadedMedia
            self.comments = loadedComments
            self.polls = loadedPolls
            self.statuses = loadedStatuses

        } catch {
            self.error = error
            self.showError = true
        }

        // Clear loading states
        isLoadingMedia = false
        isLoadingComments = false
        isLoadingPolls = false
        isLoadingStatuses = false
    }

    /// Refresh media only
    func refreshMedia() async {
        isLoadingMedia = true
        do {
            media = try await mediaService.getPartyMedia(partyId: party.id, limit: 50)
        } catch {
            self.error = error
        }
        isLoadingMedia = false
    }

    /// Refresh comments only
    func refreshComments() async {
        isLoadingComments = true
        do {
            comments = try await socialService.getComments(partyId: party.id, limit: 50)
        } catch {
            self.error = error
        }
        isLoadingComments = false
    }

    /// Refresh polls only
    func refreshPolls() async {
        isLoadingPolls = true
        do {
            polls = try await socialService.getPolls(partyId: party.id)
        } catch {
            self.error = error
        }
        isLoadingPolls = false
    }

    /// Refresh statuses only
    func refreshStatuses() async {
        isLoadingStatuses = true
        do {
            statuses = try await socialService.getLatestStatuses(partyId: party.id)
        } catch {
            self.error = error
        }
        isLoadingStatuses = false
    }

    // MARK: - Media Actions

    /// Add media to party
    func addMedia(type: MediaType, data: Data, caption: String?) async {
        do {
            let newMedia = try await mediaService.uploadPartyMedia(
                partyId: party.id,
                data: data,
                mediaType: type,
                caption: caption
            )

            // Insert at beginning (most recent first)
            media.insert(newMedia, at: 0)
        } catch {
            self.error = error
            self.showError = true
        }
    }

    /// Delete media from party
    func deleteMedia(_ mediaId: UUID) async {
        do {
            try await mediaService.deletePartyMedia(mediaId: mediaId, partyId: party.id)

            // Remove from local array
            media.removeAll { $0.id == mediaId }
        } catch {
            self.error = error
            self.showError = true
        }
    }

    // MARK: - Comment Actions

    /// Add a comment
    func addComment(_ content: String, replyTo: UUID? = nil) async {
        do {
            let newComment = try await socialService.addComment(
                partyId: party.id,
                content: content,
                parentId: replyTo
            )

            if replyTo == nil {
                // Top-level comment - insert at beginning
                comments.insert(newComment, at: 0)
            } else {
                // Reply - add to parent's replies
                if let parentIndex = comments.firstIndex(where: { $0.id == replyTo }) {
                    var parent = comments[parentIndex]
                    var replies = parent.replies ?? []
                    replies.append(newComment)
                    parent.replies = replies
                    comments[parentIndex] = parent
                }
            }
        } catch {
            self.error = error
            self.showError = true
        }
    }

    /// Like a comment (placeholder - would need a likes table)
    func likeComment(_ commentId: UUID) async {
        // This would require a comment_likes table
        // For now, just log the action
        print("Liked comment: \(commentId)")
    }

    /// Delete a comment
    func deleteComment(_ commentId: UUID) async {
        do {
            try await socialService.deleteComment(commentId: commentId)
            comments.removeAll { $0.id == commentId }
        } catch {
            self.error = error
            self.showError = true
        }
    }

    // MARK: - Poll Actions

    /// Vote on a poll option
    func vote(pollId: UUID, optionId: UUID) async {
        do {
            try await socialService.vote(pollId: pollId, optionId: optionId)

            // Refresh polls to get updated counts
            await refreshPolls()
        } catch {
            self.error = error
            self.showError = true
        }
    }

    /// Create a new poll
    func createPoll(question: String, pollType: PollType, options: [String]) async {
        do {
            let newPoll = try await socialService.createPoll(
                partyId: party.id,
                question: question,
                pollType: pollType,
                options: options
            )

            polls.insert(newPoll, at: 0)
        } catch {
            self.error = error
            self.showError = true
        }
    }

    /// Create a user-based poll (voting for people)
    func createUserPoll(question: String, pollType: PollType, userIds: [UUID]) async {
        do {
            let newPoll = try await socialService.createUserPoll(
                partyId: party.id,
                question: question,
                pollType: pollType,
                userIds: userIds
            )

            polls.insert(newPoll, at: 0)
        } catch {
            self.error = error
            self.showError = true
        }
    }

    /// Close a poll
    func closePoll(_ pollId: UUID) async {
        do {
            try await socialService.closePoll(pollId: pollId)

            // Update local state
            if let index = polls.firstIndex(where: { $0.id == pollId }) {
                var poll = polls[index]
                poll.isActive = false
                polls[index] = poll
            }
        } catch {
            self.error = error
            self.showError = true
        }
    }

    // MARK: - Status Actions

    /// Update current user's status
    func updateStatus(type: StatusType, value: Int, message: String?) async {
        do {
            let newStatus = try await socialService.postStatus(
                partyId: party.id,
                statusType: type,
                value: value,
                message: message
            )

            // Replace existing status for this user or add new
            if let index = statuses.firstIndex(where: { $0.userId == newStatus.userId }) {
                statuses[index] = newStatus
            } else {
                statuses.insert(newStatus, at: 0)
            }
        } catch {
            self.error = error
            self.showError = true
        }
    }

    // MARK: - Helpers

    /// Check if current user is a host
    var isCurrentUserHost: Bool {
        guard let userId = currentUserId,
              let hosts = party.hosts else { return false }
        return hosts.contains { $0.userId == userId }
    }

    /// Check if current user is the creator
    var isCurrentUserCreator: Bool {
        guard let userId = currentUserId,
              let hosts = party.hosts else { return false }
        return hosts.contains { $0.userId == userId && $0.role == .creator }
    }

    /// Check if current user can add media
    var canAddMedia: Bool {
        guard let userId = currentUserId else { return false }

        // Hosts can always add
        if let hosts = party.hosts, hosts.contains(where: { $0.userId == userId }) {
            return true
        }

        // Accepted guests can add
        if let guests = party.guests, guests.contains(where: { $0.userId == userId && $0.status == .accepted }) {
            return true
        }

        return false
    }
}
