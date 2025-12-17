//
//  Party.swift
//  STUDIO
//
//  Created by Claude on 12/16/25.
//

import Foundation

// MARK: - Party Model

/// Main party entity - like an Instagram collab post
struct Party: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let createdAt: Date
    var title: String
    var description: String?
    var coverImageUrl: String?
    var location: String?
    var partyDate: Date?
    var endDate: Date?
    var isActive: Bool
    var isPublic: Bool?  // Optional - may not exist in DB yet
    var maxGuests: Int?

    // Relationships (populated via joins)
    var hosts: [PartyHost]?
    var guests: [PartyGuest]?
    var mediaCount: Int?
    var commentCount: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case title
        case description
        case coverImageUrl = "cover_image_url"
        case location
        case partyDate = "party_date"
        case endDate = "end_date"
        case isActive = "is_active"
        case isPublic = "is_public"
        case maxGuests = "max_guests"
        case hosts
        case guests
        case mediaCount = "media_count"
        case commentCount = "comment_count"
    }
}

// MARK: - Party Host

/// Junction table for party hosts (up to 5 co-hosts)
struct PartyHost: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let partyId: UUID
    let userId: UUID
    let role: HostRole
    let addedAt: Date

    // Joined user profile
    var user: User?

    enum CodingKeys: String, CodingKey {
        case id
        case partyId = "party_id"
        case userId = "user_id"
        case role
        case addedAt = "added_at"
        case user
    }
}

enum HostRole: String, Codable, Sendable {
    case creator = "creator"
    case cohost = "cohost"
}

// MARK: - Party Guest

/// Invitation/RSVP for party guests
struct PartyGuest: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let partyId: UUID
    let userId: UUID
    var status: GuestStatus
    let invitedBy: UUID
    let invitedAt: Date
    var respondedAt: Date?

    // Joined user profile
    var user: User?
    // Joined party (for fetching attended parties)
    var party: Party?

    enum CodingKeys: String, CodingKey {
        case id
        case partyId = "party_id"
        case userId = "user_id"
        case status
        case invitedBy = "invited_by"
        case invitedAt = "invited_at"
        case respondedAt = "responded_at"
        case user
        case party
    }
}

enum GuestStatus: String, Codable, Sendable {
    case pending = "pending"
    case accepted = "accepted"
    case declined = "declined"
    case maybe = "maybe"
}

// MARK: - Party Media

/// Photos and videos shared in a party
struct PartyMedia: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let partyId: UUID
    let userId: UUID
    let mediaType: MediaType
    let url: String
    var thumbnailUrl: String?
    var caption: String?
    let createdAt: Date
    var duration: Double? // For videos

    // Joined user profile
    var user: User?

    enum CodingKeys: String, CodingKey {
        case id
        case partyId = "party_id"
        case userId = "user_id"
        case mediaType = "media_type"
        case url
        case thumbnailUrl = "thumbnail_url"
        case caption
        case createdAt = "created_at"
        case duration
        case user
    }
}

enum MediaType: String, Codable, Sendable {
    case photo = "photo"
    case video = "video"
}

// MARK: - Party Comment

/// Comments on a party
struct PartyComment: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let partyId: UUID
    let userId: UUID
    var content: String
    let createdAt: Date
    var updatedAt: Date?
    var parentId: UUID? // For replies

    // Joined user profile
    var user: User?
    var replies: [PartyComment]?

    enum CodingKeys: String, CodingKey {
        case id
        case partyId = "party_id"
        case userId = "user_id"
        case content
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case parentId = "parent_id"
        case user
        case replies
    }
}

// MARK: - Party Poll

/// Polls for party activities (MVP, best dressed, etc.)
struct PartyPoll: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let partyId: UUID
    let createdBy: UUID
    var question: String
    var pollType: PollType
    let createdAt: Date
    var expiresAt: Date?
    var isActive: Bool

    // Relationships
    var options: [PollOption]?
    var creator: User?
    var totalVotes: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case partyId = "party_id"
        case createdBy = "created_by"
        case question
        case pollType = "poll_type"
        case createdAt = "created_at"
        case expiresAt = "expires_at"
        case isActive = "is_active"
        case options
        case creator
        case totalVotes = "total_votes"
    }
}

enum PollType: String, Codable, Sendable {
    case partyMVP = "party_mvp"
    case bestDressed = "best_dressed"
    case bestMoment = "best_moment"
    case custom = "custom"
}

// MARK: - Poll Option

/// Options for a poll (usually users or custom text)
struct PollOption: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let pollId: UUID
    var optionText: String?
    var optionUserId: UUID? // If voting for a person
    var voteCount: Int

    // Joined user if voting for person
    var optionUser: User?
    var hasVoted: Bool? // Current user's vote status

    enum CodingKeys: String, CodingKey {
        case id
        case pollId = "poll_id"
        case optionText = "option_text"
        case optionUserId = "option_user_id"
        case voteCount = "vote_count"
        case optionUser = "option_user"
        case hasVoted = "has_voted"
    }
}

// MARK: - Poll Vote

/// Individual vote on a poll
struct PollVote: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let pollId: UUID
    let optionId: UUID
    let userId: UUID
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case pollId = "poll_id"
        case optionId = "option_id"
        case userId = "user_id"
        case createdAt = "created_at"
    }
}

// MARK: - Party Status

/// Status updates (drunk meter, vibe checks)
struct PartyStatus: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let partyId: UUID
    let userId: UUID
    var statusType: StatusType
    var value: Int // 1-5 scale
    var message: String?
    let createdAt: Date

    // Joined user profile
    var user: User?

    enum CodingKeys: String, CodingKey {
        case id
        case partyId = "party_id"
        case userId = "user_id"
        case statusType = "status_type"
        case value
        case message
        case createdAt = "created_at"
        case user
    }
}

enum StatusType: String, Codable, Sendable, CaseIterable {
    case drunkMeter = "drunk_meter"
    case vibeCheck = "vibe_check"
    case rsvp = "rsvp"
    case danceMode = "dance_mode"
    case energy = "energy"
    case socialMeter = "social_meter"
    case foodStatus = "food_status"

    /// SF Symbol icon for this status type
    var icon: String {
        switch self {
        case .drunkMeter: return "drop.fill"
        case .vibeCheck: return "sparkles"
        case .rsvp: return "figure.walk"
        case .danceMode: return "figure.dance"
        case .energy: return "bolt.fill"
        case .socialMeter: return "person.2.fill"
        case .foodStatus: return "fork.knife"
        }
    }

    /// Display label for this status type
    var label: String {
        switch self {
        case .drunkMeter: return "DRUNK METER"
        case .vibeCheck: return "VIBE CHECK"
        case .rsvp: return "RSVP"
        case .danceMode: return "DANCE MODE"
        case .energy: return "ENERGY"
        case .socialMeter: return "SOCIAL"
        case .foodStatus: return "FOOD"
        }
    }

    /// Short label for tabs
    var shortLabel: String {
        switch self {
        case .drunkMeter: return "DRUNK"
        case .vibeCheck: return "VIBE"
        case .rsvp: return "RSVP"
        case .danceMode: return "DANCE"
        case .energy: return "ENERGY"
        case .socialMeter: return "SOCIAL"
        case .foodStatus: return "FOOD"
        }
    }

    /// Labels for each level (1-5)
    var levelLabels: [String] {
        switch self {
        case .drunkMeter:
            return ["SOBER", "TIPSY", "BUZZED", "LIT", "GONE"]
        case .vibeCheck:
            return ["CHILL", "WARMING UP", "FEELING IT", "PEAK", "EUPHORIC"]
        case .rsvp:
            return ["MAYBE", "PROBABLY", "ON MY WAY", "I'M HERE", "LEAVING SOON"]
        case .danceMode:
            return ["WALLFLOWER", "NODDING", "MOVING", "DANCING", "MAIN CHARACTER"]
        case .energy:
            return ["LOW", "HANGING IN", "SOLID", "ENERGIZED", "UNSTOPPABLE"]
        case .socialMeter:
            return ["SOLO", "OBSERVING", "MINGLING", "IN THE MIX", "LIFE OF PARTY"]
        case .foodStatus:
            return ["FED", "GETTING HUNGRY", "NEED SNACK", "STARVING", "PIZZA TIME"]
        }
    }

    /// Emojis for each level (1-5)
    var levelEmojis: [String] {
        switch self {
        case .drunkMeter:
            return ["😇", "🍺", "😵‍💫", "🔥", "💀"]
        case .vibeCheck:
            return ["😌", "😎", "🥳", "✨", "🚀"]
        case .rsvp:
            return ["🤷", "👍", "🚗", "📍", "👋"]
        case .danceMode:
            return ["🧍", "🎵", "🕺", "💃", "👑"]
        case .energy:
            return ["🪫", "😮‍💨", "💪", "⚡", "🔋"]
        case .socialMeter:
            return ["🤫", "👀", "💬", "🗣️", "🎤"]
        case .foodStatus:
            return ["😋", "🤔", "🍿", "😩", "🍕"]
        }
    }

    /// Get label for a specific level (1-5)
    func labelForLevel(_ level: Int) -> String {
        let index = max(0, min(level - 1, 4))
        return levelLabels[index]
    }

    /// Get emoji for a specific level (1-5)
    func emojiForLevel(_ level: Int) -> String {
        let index = max(0, min(level - 1, 4))
        return levelEmojis[index]
    }
}

// MARK: - Vibe Level

/// Helper for drunk meter / vibe display
enum VibeLevel: Int, CaseIterable {
    case chill = 1      // Sober/relaxed
    case groovy = 2     // Feeling good
    case elevated = 3   // Getting there
    case lit = 4        // Party mode
    case gone = 5       // Peak party

    var emoji: String {
        switch self {
        case .chill: return "😌"
        case .groovy: return "😎"
        case .elevated: return "🥳"
        case .lit: return "🔥"
        case .gone: return "🚀"
        }
    }

    var label: String {
        switch self {
        case .chill: return "Chill"
        case .groovy: return "Groovy"
        case .elevated: return "Elevated"
        case .lit: return "Lit"
        case .gone: return "Gone"
        }
    }

    var colorName: String {
        switch self {
        case .chill: return "vibeChill"
        case .groovy: return "vibeGroovy"
        case .elevated: return "vibeElevated"
        case .lit: return "vibeElevated"
        case .gone: return "vibeGone"
        }
    }
}

// MARK: - Create DTOs

/// DTO for creating a new party
struct CreatePartyRequest: Encodable, Sendable {
    let title: String
    let description: String?
    let location: String?
    let partyDate: Date?
    let maxGuests: Int?

    enum CodingKeys: String, CodingKey {
        case title
        case description
        case location
        case partyDate = "party_date"
        case maxGuests = "max_guests"
    }
}

/// DTO for inviting guests
struct InviteGuestRequest: Encodable, Sendable {
    let partyId: UUID
    let userId: UUID

    enum CodingKeys: String, CodingKey {
        case partyId = "party_id"
        case userId = "user_id"
    }
}

/// DTO for creating media
struct CreateMediaRequest: Encodable, Sendable {
    let partyId: UUID
    let mediaType: MediaType
    let url: String
    let thumbnailUrl: String?
    let caption: String?
    let duration: Double?

    enum CodingKeys: String, CodingKey {
        case partyId = "party_id"
        case mediaType = "media_type"
        case url
        case thumbnailUrl = "thumbnail_url"
        case caption
        case duration
    }
}

/// DTO for creating a poll
struct CreatePollRequest: Encodable, Sendable {
    let partyId: UUID
    let question: String
    let pollType: PollType
    let options: [String]
    let expiresAt: Date?

    enum CodingKeys: String, CodingKey {
        case partyId = "party_id"
        case question
        case pollType = "poll_type"
        case options
        case expiresAt = "expires_at"
    }
}

/// DTO for creating a status update
struct CreateStatusRequest: Encodable, Sendable {
    let partyId: UUID
    let statusType: StatusType
    let value: Int
    let message: String?

    enum CodingKeys: String, CodingKey {
        case partyId = "party_id"
        case statusType = "status_type"
        case value
        case message
    }
}
