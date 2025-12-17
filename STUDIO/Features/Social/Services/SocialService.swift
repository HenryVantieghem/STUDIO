//
//  SocialService.swift
//  STUDIO
//
//  Created by Claude on 12/16/25.
//

import Foundation
import Supabase

// MARK: - Social Service

/// Service for social features: polls, comments, statuses
final class SocialService: Sendable {

    // MARK: - Comments

    /// Add a comment to a party
    func addComment(partyId: UUID, content: String, parentId: UUID? = nil) async throws -> PartyComment {
        let userId = try await supabase.auth.session.user.id

        var request: [String: AnyEncodable] = [
            "party_id": AnyEncodable(partyId),
            "user_id": AnyEncodable(userId),
            "content": AnyEncodable(content)
        ]

        if let parentId {
            request["parent_id"] = AnyEncodable(parentId)
        }

        let comment: PartyComment = try await supabase
            .from("party_comments")
            .insert(request)
            .select("*, user:profiles(*)")
            .single()
            .execute()
            .value

        return comment
    }

    /// Get comments for a party
    func getComments(partyId: UUID, limit: Int = 50, offset: Int = 0) async throws -> [PartyComment] {
        let comments: [PartyComment] = try await supabase
            .from("party_comments")
            .select("*, user:profiles(*), replies:party_comments(*, user:profiles(*))")
            .eq("party_id", value: partyId.uuidString)
            .is("parent_id", value: nil) // Only top-level comments
            .order("created_at", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()
            .value

        return comments
    }

    /// Delete a comment
    func deleteComment(commentId: UUID) async throws {
        try await supabase
            .from("party_comments")
            .delete()
            .eq("id", value: commentId.uuidString)
            .execute()
    }

    /// Update a comment
    func updateComment(commentId: UUID, content: String) async throws {
        try await supabase
            .from("party_comments")
            .update(["content": content, "updated_at": ISO8601DateFormatter().string(from: Date())])
            .eq("id", value: commentId.uuidString)
            .execute()
    }

    // MARK: - Polls

    /// Create a poll
    func createPoll(partyId: UUID, question: String, pollType: PollType, options: [String], expiresAt: Date? = nil) async throws -> PartyPoll {
        let userId = try await supabase.auth.session.user.id

        // Create poll
        var pollRequest: [String: AnyEncodable] = [
            "party_id": AnyEncodable(partyId),
            "created_by": AnyEncodable(userId),
            "question": AnyEncodable(question),
            "poll_type": AnyEncodable(pollType.rawValue),
            "is_active": AnyEncodable(true)
        ]

        if let expiresAt {
            pollRequest["expires_at"] = AnyEncodable(expiresAt)
        }

        let poll: PartyPoll = try await supabase
            .from("party_polls")
            .insert(pollRequest)
            .select()
            .single()
            .execute()
            .value

        // Create options
        for option in options {
            let optionRequest: [String: AnyEncodable] = [
                "poll_id": AnyEncodable(poll.id),
                "option_text": AnyEncodable(option),
                "vote_count": AnyEncodable(0)
            ]

            try await supabase
                .from("poll_options")
                .insert(optionRequest)
                .execute()
        }

        // Return poll with options
        return try await getPoll(pollId: poll.id)
    }

    /// Create a user-based poll (voting for people)
    func createUserPoll(partyId: UUID, question: String, pollType: PollType, userIds: [UUID], expiresAt: Date? = nil) async throws -> PartyPoll {
        let userId = try await supabase.auth.session.user.id

        // Create poll
        var pollRequest: [String: AnyEncodable] = [
            "party_id": AnyEncodable(partyId),
            "created_by": AnyEncodable(userId),
            "question": AnyEncodable(question),
            "poll_type": AnyEncodable(pollType.rawValue),
            "is_active": AnyEncodable(true)
        ]

        if let expiresAt {
            pollRequest["expires_at"] = AnyEncodable(expiresAt)
        }

        let poll: PartyPoll = try await supabase
            .from("party_polls")
            .insert(pollRequest)
            .select()
            .single()
            .execute()
            .value

        // Create user options
        for optionUserId in userIds {
            let optionRequest: [String: AnyEncodable] = [
                "poll_id": AnyEncodable(poll.id),
                "option_user_id": AnyEncodable(optionUserId),
                "vote_count": AnyEncodable(0)
            ]

            try await supabase
                .from("poll_options")
                .insert(optionRequest)
                .execute()
        }

        // Return poll with options
        return try await getPoll(pollId: poll.id)
    }

    /// Get a poll with options
    func getPoll(pollId: UUID) async throws -> PartyPoll {
        _ = try await supabase.auth.session.user.id // Verify authenticated

        let poll: PartyPoll = try await supabase
            .from("party_polls")
            .select("""
                *,
                creator:profiles!created_by(*),
                options:poll_options(
                    *,
                    option_user:profiles!option_user_id(*)
                )
            """)
            .eq("id", value: pollId.uuidString)
            .single()
            .execute()
            .value

        return poll
    }

    /// Get polls for a party
    func getPolls(partyId: UUID) async throws -> [PartyPoll] {
        let polls: [PartyPoll] = try await supabase
            .from("party_polls")
            .select("""
                *,
                creator:profiles!created_by(*),
                options:poll_options(
                    *,
                    option_user:profiles!option_user_id(*)
                ),
                total_votes:poll_votes(count)
            """)
            .eq("party_id", value: partyId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value

        return polls
    }

    /// Vote on a poll
    func vote(pollId: UUID, optionId: UUID) async throws {
        let userId = try await supabase.auth.session.user.id

        // Check if already voted
        let existingVotes: [PollVote] = try await supabase
            .from("poll_votes")
            .select("id")
            .eq("poll_id", value: pollId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value

        if !existingVotes.isEmpty {
            throw SocialError.alreadyVoted
        }

        // Create vote
        let voteRequest: [String: AnyEncodable] = [
            "poll_id": AnyEncodable(pollId),
            "option_id": AnyEncodable(optionId),
            "user_id": AnyEncodable(userId)
        ]

        try await supabase
            .from("poll_votes")
            .insert(voteRequest)
            .execute()

        // Increment vote count (handled by trigger in database ideally)
        try await supabase.rpc("increment_vote_count", params: ["option_id": optionId.uuidString])
            .execute()
    }

    /// Close a poll
    func closePoll(pollId: UUID) async throws {
        try await supabase
            .from("party_polls")
            .update(["is_active": false])
            .eq("id", value: pollId.uuidString)
            .execute()
    }

    // MARK: - Status Updates

    /// Post a status update (drunk meter, vibe check)
    func postStatus(partyId: UUID, statusType: StatusType, value: Int, message: String? = nil) async throws -> PartyStatus {
        let userId = try await supabase.auth.session.user.id

        var request: [String: AnyEncodable] = [
            "party_id": AnyEncodable(partyId),
            "user_id": AnyEncodable(userId),
            "status_type": AnyEncodable(statusType.rawValue),
            "value": AnyEncodable(value)
        ]

        if let message {
            request["message"] = AnyEncodable(message)
        }

        let status: PartyStatus = try await supabase
            .from("party_statuses")
            .insert(request)
            .select("*, user:profiles(*)")
            .single()
            .execute()
            .value

        return status
    }

    /// Get status updates for a party
    func getStatuses(partyId: UUID, limit: Int = 20) async throws -> [PartyStatus] {
        let statuses: [PartyStatus] = try await supabase
            .from("party_statuses")
            .select("*, user:profiles(*)")
            .eq("party_id", value: partyId.uuidString)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value

        return statuses
    }

    /// Get latest status for each user in a party
    func getLatestStatuses(partyId: UUID) async throws -> [PartyStatus] {
        // This would ideally use a database function for efficiency
        // For now, get all and filter client-side
        let statuses: [PartyStatus] = try await supabase
            .from("party_statuses")
            .select("*, user:profiles(*)")
            .eq("party_id", value: partyId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value

        // Get only latest per user
        var latestByUser: [UUID: PartyStatus] = [:]
        for status in statuses {
            if latestByUser[status.userId] == nil {
                latestByUser[status.userId] = status
            }
        }

        return Array(latestByUser.values).sorted { $0.createdAt > $1.createdAt }
    }

    /// Get user's latest status in a party
    func getUserStatus(partyId: UUID, userId: UUID) async throws -> PartyStatus? {
        let statuses: [PartyStatus] = try await supabase
            .from("party_statuses")
            .select("*, user:profiles(*)")
            .eq("party_id", value: partyId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .limit(1)
            .execute()
            .value

        return statuses.first
    }

    // MARK: - User Search

    /// Search for users by username
    func searchUsers(query: String, limit: Int = 20) async throws -> [User] {
        guard !query.isEmpty else { return [] }

        let currentUserId = try await supabase.auth.session.user.id

        let users: [User] = try await supabase
            .from("profiles")
            .select("*")
            .ilike("username", pattern: "%\(query)%")
            .neq("id", value: currentUserId.uuidString)
            .limit(limit)
            .execute()
            .value

        return users
    }
}

// MARK: - Social Errors

enum SocialError: LocalizedError {
    case alreadyVoted
    case pollClosed
    case notAuthorized

    var errorDescription: String? {
        switch self {
        case .alreadyVoted:
            return "You've already voted on this poll"
        case .pollClosed:
            return "This poll has ended"
        case .notAuthorized:
            return "You don't have permission to do this"
        }
    }
}
