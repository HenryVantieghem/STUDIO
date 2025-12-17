//
//  PartyEngagementService.swift
//  STUDIO
//
//  Service for party engagement features - comments, statuses, reactions
//  Basel Afterdark Design System
//

import Foundation
import Supabase

// MARK: - Party Engagement Service

/// Service for managing party engagement - comments, statuses, reactions
final class PartyEngagementService: Sendable {

    // MARK: - Comments

    /// Add a comment to a party
    func addComment(partyId: UUID, content: String) async throws -> CommentCard {
        let userId = try await supabase.auth.session.user.id

        let request: [String: AnyEncodable] = [
            "party_id": AnyEncodable(partyId),
            "user_id": AnyEncodable(userId),
            "content": AnyEncodable(content)
        ]

        let comment: CommentCard = try await supabase
            .from("party_comments")
            .insert(request)
            .select("*, user:profiles(*)")
            .single()
            .execute()
            .value

        return comment
    }

    /// Get comments for a party
    func getComments(partyId: UUID, limit: Int = 50, offset: Int = 0) async throws -> [CommentCard] {
        let comments: [CommentCard] = try await supabase
            .from("party_comments")
            .select("*, user:profiles(*)")
            .eq("party_id", value: partyId.uuidString)
            .order("created_at", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()
            .value

        return comments
    }

    /// Like a comment
    func likeComment(commentId: UUID) async throws {
        let userId = try await supabase.auth.session.user.id

        let request: [String: AnyEncodable] = [
            "comment_id": AnyEncodable(commentId),
            "user_id": AnyEncodable(userId)
        ]

        try await supabase
            .from("comment_likes")
            .insert(request)
            .execute()
    }

    /// Unlike a comment
    func unlikeComment(commentId: UUID) async throws {
        let userId = try await supabase.auth.session.user.id

        try await supabase
            .from("comment_likes")
            .delete()
            .eq("comment_id", value: commentId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .execute()
    }

    /// Delete a comment
    func deleteComment(commentId: UUID) async throws {
        try await supabase
            .from("party_comments")
            .delete()
            .eq("id", value: commentId.uuidString)
            .execute()
    }

    // MARK: - Statuses

    /// Post a status update
    func postStatus(partyId: UUID, statusType: StatusType, level: Int, message: String?, emoji: String?) async throws -> StatusCard {
        let userId = try await supabase.auth.session.user.id

        var request: [String: AnyEncodable] = [
            "party_id": AnyEncodable(partyId),
            "user_id": AnyEncodable(userId),
            "status_type": AnyEncodable(statusType.rawValue),
            "level": AnyEncodable(level)
        ]

        if let message { request["message"] = AnyEncodable(message) }
        if let emoji { request["emoji"] = AnyEncodable(emoji) }

        let status: StatusCard = try await supabase
            .from("party_statuses")
            .insert(request)
            .select("*, user:profiles(*)")
            .single()
            .execute()
            .value

        return status
    }

    /// Get statuses for a party
    func getStatuses(partyId: UUID, limit: Int = 50) async throws -> [StatusCard] {
        let statuses: [StatusCard] = try await supabase
            .from("party_statuses")
            .select("*, user:profiles(*)")
            .eq("party_id", value: partyId.uuidString)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value

        return statuses
    }

    // MARK: - Reactions

    /// Add a reaction to a party moment
    func addReaction(partyId: UUID, targetType: String, targetId: UUID, emoji: String) async throws {
        let userId = try await supabase.auth.session.user.id

        let request: [String: AnyEncodable] = [
            "party_id": AnyEncodable(partyId),
            "user_id": AnyEncodable(userId),
            "target_type": AnyEncodable(targetType),
            "target_id": AnyEncodable(targetId),
            "emoji": AnyEncodable(emoji)
        ]

        try await supabase
            .from("party_reactions")
            .insert(request)
            .execute()
    }

    /// Get reaction counts for a target
    func getReactionCounts(targetType: String, targetId: UUID) async throws -> [String: Int] {
        struct ReactionCount: Codable {
            let emoji: String
            let count: Int
        }

        let reactions: [ReactionCount] = try await supabase
            .from("party_reactions")
            .select("emoji, count:id.count()")
            .eq("target_type", value: targetType)
            .eq("target_id", value: targetId.uuidString)
            .execute()
            .value

        var counts: [String: Int] = [:]
        for reaction in reactions {
            counts[reaction.emoji] = reaction.count
        }
        return counts
    }
}

// MARK: - Party Heat Score Service

/// Service for calculating and managing party heat scores
final class PartyHeatScoreService: Sendable {

    /// Calculate current heat score for a party
    func calculateHeatScore(partyId: UUID) async throws -> PartyHeatScore {
        // Get all engagement counts
        async let guestCount = getGuestCount(partyId: partyId)
        async let mediaCount = getMediaCount(partyId: partyId)
        async let commentCount = getCommentCount(partyId: partyId)
        async let statusCount = getStatusCount(partyId: partyId)
        async let reactionCount = getReactionCount(partyId: partyId)
        async let averageVibe = getAverageVibeLevel(partyId: partyId)

        let guests = try await guestCount
        let media = try await mediaCount
        let comments = try await commentCount
        let statuses = try await statusCount
        let reactions = try await reactionCount
        let vibe = try await averageVibe

        // Calculate scores with weights
        let guestScore = guests * 10
        let mediaScore = media * 25
        let commentScore = comments * 5
        let statusScore = statuses * 8
        let reactionScore = reactions * 2
        let vibeScore = Int(vibe * 15.0 * Double(statuses + 1))

        let totalScore = guestScore + mediaScore + commentScore + statusScore + reactionScore + vibeScore

        return PartyHeatScore(
            partyId: partyId,
            totalScore: totalScore,
            guestScore: guestScore,
            mediaScore: mediaScore,
            commentScore: commentScore,
            statusScore: statusScore,
            reactionScore: reactionScore,
            vibeScore: vibeScore,
            timestamp: Date()
        )
    }

    /// Get guest count for a party
    private func getGuestCount(partyId: UUID) async throws -> Int {
        struct CountResult: Codable {
            let count: Int
        }

        let result: [CountResult] = try await supabase
            .from("party_guests")
            .select("count:id.count()", head: false)
            .eq("party_id", value: partyId.uuidString)
            .eq("status", value: "accepted")
            .execute()
            .value

        return result.first?.count ?? 0
    }

    /// Get media count for a party
    private func getMediaCount(partyId: UUID) async throws -> Int {
        struct CountResult: Codable {
            let count: Int
        }

        let result: [CountResult] = try await supabase
            .from("party_media")
            .select("count:id.count()", head: false)
            .eq("party_id", value: partyId.uuidString)
            .execute()
            .value

        return result.first?.count ?? 0
    }

    /// Get comment count for a party
    private func getCommentCount(partyId: UUID) async throws -> Int {
        struct CountResult: Codable {
            let count: Int
        }

        let result: [CountResult] = try await supabase
            .from("party_comments")
            .select("count:id.count()", head: false)
            .eq("party_id", value: partyId.uuidString)
            .execute()
            .value

        return result.first?.count ?? 0
    }

    /// Get status count for a party
    private func getStatusCount(partyId: UUID) async throws -> Int {
        struct CountResult: Codable {
            let count: Int
        }

        let result: [CountResult] = try await supabase
            .from("party_statuses")
            .select("count:id.count()", head: false)
            .eq("party_id", value: partyId.uuidString)
            .execute()
            .value

        return result.first?.count ?? 0
    }

    /// Get reaction count for a party
    private func getReactionCount(partyId: UUID) async throws -> Int {
        struct CountResult: Codable {
            let count: Int
        }

        let result: [CountResult] = try await supabase
            .from("party_reactions")
            .select("count:id.count()", head: false)
            .eq("party_id", value: partyId.uuidString)
            .execute()
            .value

        return result.first?.count ?? 0
    }

    /// Get average vibe level from statuses
    private func getAverageVibeLevel(partyId: UUID) async throws -> Double {
        struct VibeStatus: Codable {
            let level: Int
        }

        let statuses: [VibeStatus] = try await supabase
            .from("party_statuses")
            .select("level")
            .eq("party_id", value: partyId.uuidString)
            .eq("status_type", value: "vibe_check")
            .execute()
            .value

        guard !statuses.isEmpty else { return 0 }

        let total = statuses.reduce(0) { $0 + $1.level }
        return Double(total) / Double(statuses.count)
    }

    /// Get top parties by heat score
    func getHottestParties(limit: Int = 10) async throws -> [(party: Party, score: Int)] {
        // Get active parties
        let parties: [Party] = try await supabase
            .from("parties")
            .select("*")
            .eq("is_active", value: true)
            .limit(50)
            .execute()
            .value

        // Calculate heat scores for each
        var partyScores: [(party: Party, score: Int)] = []

        for party in parties {
            let heatScore = try await calculateHeatScore(partyId: party.id)
            partyScores.append((party: party, score: heatScore.totalScore))
        }

        // Sort by score and return top N
        return partyScores
            .sorted { $0.score > $1.score }
            .prefix(limit)
            .map { $0 }
    }
}
