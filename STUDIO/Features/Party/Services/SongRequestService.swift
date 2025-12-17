//
//  SongRequestService.swift
//  STUDIO
//
//  Service for party song request queue management
//  Basel Afterdark Design System
//

import Foundation
import Supabase

// MARK: - Song Request Service

/// Service for managing party song request queues
final class SongRequestService: Sendable {

    // MARK: - Song Requests

    /// Request a song for a party
    func requestSong(partyId: UUID, title: String, artist: String, spotifyUri: String?) async throws -> SongRequest {
        let userId = try await supabase.auth.session.user.id

        var request: [String: AnyEncodable] = [
            "party_id": AnyEncodable(partyId),
            "user_id": AnyEncodable(userId),
            "title": AnyEncodable(title),
            "artist": AnyEncodable(artist),
            "status": AnyEncodable(SongStatus.queued.rawValue),
            "vote_count": AnyEncodable(1)  // Requester's initial upvote
        ]

        if let spotifyUri { request["spotify_uri"] = AnyEncodable(spotifyUri) }

        let song: SongRequest = try await supabase
            .from("song_requests")
            .insert(request)
            .select("*, user:profiles(*)")
            .single()
            .execute()
            .value

        // Add initial vote
        try await voteSong(songId: song.id, voteType: .up)

        return song
    }

    /// Get song queue for a party
    func getSongQueue(partyId: UUID) async throws -> [SongRequest] {
        let songs: [SongRequest] = try await supabase
            .from("song_requests")
            .select("*, user:profiles(*)")
            .eq("party_id", value: partyId.uuidString)
            .in("status", values: [SongStatus.queued.rawValue, SongStatus.playing.rawValue])
            .order("vote_count", ascending: false)
            .order("created_at", ascending: true)
            .execute()
            .value

        return songs
    }

    /// Get played songs for a party
    func getPlayedSongs(partyId: UUID) async throws -> [SongRequest] {
        let songs: [SongRequest] = try await supabase
            .from("song_requests")
            .select("*, user:profiles(*)")
            .eq("party_id", value: partyId.uuidString)
            .eq("status", value: SongStatus.played.rawValue)
            .order("played_at", ascending: false)
            .execute()
            .value

        return songs
    }

    /// Get currently playing song
    func getNowPlaying(partyId: UUID) async throws -> SongRequest? {
        let songs: [SongRequest] = try await supabase
            .from("song_requests")
            .select("*, user:profiles(*)")
            .eq("party_id", value: partyId.uuidString)
            .eq("status", value: SongStatus.playing.rawValue)
            .limit(1)
            .execute()
            .value

        return songs.first
    }

    // MARK: - Voting

    /// Vote on a song (up or down)
    func voteSong(songId: UUID, voteType: VoteType) async throws {
        let userId = try await supabase.auth.session.user.id

        // Check for existing vote
        let existingVotes: [SongVote] = try await supabase
            .from("song_votes")
            .select("*")
            .eq("song_id", value: songId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value

        if let existingVote = existingVotes.first {
            if existingVote.voteType == voteType {
                // Remove vote if same type
                try await supabase
                    .from("song_votes")
                    .delete()
                    .eq("id", value: existingVote.id.uuidString)
                    .execute()

                // Update vote count
                try await updateVoteCount(songId: songId, delta: voteType == .up ? -1 : 1)
            } else {
                // Change vote
                try await supabase
                    .from("song_votes")
                    .update(["vote_type": voteType.rawValue] as [String: String])
                    .eq("id", value: existingVote.id.uuidString)
                    .execute()

                // Update vote count (double change)
                try await updateVoteCount(songId: songId, delta: voteType == .up ? 2 : -2)
            }
        } else {
            // Add new vote
            let request: [String: AnyEncodable] = [
                "song_id": AnyEncodable(songId),
                "user_id": AnyEncodable(userId),
                "vote_type": AnyEncodable(voteType.rawValue)
            ]

            try await supabase
                .from("song_votes")
                .insert(request)
                .execute()

            // Update vote count
            try await updateVoteCount(songId: songId, delta: voteType == .up ? 1 : -1)
        }
    }

    /// Update vote count on song
    private func updateVoteCount(songId: UUID, delta: Int) async throws {
        // Get current count
        struct VoteCountResult: Codable {
            let voteCount: Int

            enum CodingKeys: String, CodingKey {
                case voteCount = "vote_count"
            }
        }

        let songs: [VoteCountResult] = try await supabase
            .from("song_requests")
            .select("vote_count")
            .eq("id", value: songId.uuidString)
            .execute()
            .value

        let currentCount = songs.first?.voteCount ?? 0
        let newCount = currentCount + delta

        try await supabase
            .from("song_requests")
            .update(["vote_count": newCount] as [String: Int])
            .eq("id", value: songId.uuidString)
            .execute()
    }

    /// Get user's vote for a song
    func getUserVote(songId: UUID) async throws -> VoteType? {
        let userId = try await supabase.auth.session.user.id

        let votes: [SongVote] = try await supabase
            .from("song_votes")
            .select("*")
            .eq("song_id", value: songId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value

        return votes.first?.voteType
    }

    // MARK: - Host Controls

    /// Mark a song as now playing (host only)
    func playSong(songId: UUID, partyId: UUID) async throws {
        // Clear any currently playing
        try await supabase
            .from("song_requests")
            .update([
                "status": SongStatus.played.rawValue,
                "played_at": ISO8601DateFormatter().string(from: Date())
            ] as [String: String])
            .eq("party_id", value: partyId.uuidString)
            .eq("status", value: SongStatus.playing.rawValue)
            .execute()

        // Set new song as playing
        try await supabase
            .from("song_requests")
            .update(["status": SongStatus.playing.rawValue] as [String: String])
            .eq("id", value: songId.uuidString)
            .execute()
    }

    /// Skip a song (host only)
    func skipSong(songId: UUID) async throws {
        try await supabase
            .from("song_requests")
            .update([
                "status": SongStatus.skipped.rawValue
            ] as [String: String])
            .eq("id", value: songId.uuidString)
            .execute()
    }

    /// Delete a song request (host or requester only)
    func deleteSongRequest(songId: UUID) async throws {
        try await supabase
            .from("song_requests")
            .delete()
            .eq("id", value: songId.uuidString)
            .execute()
    }
}

// MARK: - Song Vote Model

struct SongVote: Codable, Identifiable, Sendable {
    let id: UUID
    let songId: UUID
    let userId: UUID
    let voteType: VoteType
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case songId = "song_id"
        case userId = "user_id"
        case voteType = "vote_type"
        case createdAt = "created_at"
    }
}
