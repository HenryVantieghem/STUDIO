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
    var locationName: String?
    var locationLat: Double?
    var locationLng: Double?
    var startsAt: Date?
    var endsAt: Date?
    var status: PartyState?
    var privacy: PartyPrivacy?
    var maxGuests: Int?
    var guestCount: Int?

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
        case locationName = "location_name"
        case locationLat = "location_lat"
        case locationLng = "location_lng"
        case startsAt = "starts_at"
        case endsAt = "ends_at"
        case status
        case privacy
        case maxGuests = "max_guests"
        case guestCount = "guest_count"
        case hosts
        case guests
        case mediaCount = "media_count"
        case commentCount = "comment_count"
    }

    // Convenience computed properties for backward compatibility
    var location: String? { locationName }
    var partyDate: Date? { startsAt }
    var endDate: Date? { endsAt }
    var isActive: Bool { status == .active || status == nil }
    var isPublic: Bool { privacy == .publicParty }

    // Convenience initializer for backward compatibility with old parameter names
    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        title: String,
        description: String? = nil,
        coverImageUrl: String? = nil,
        location: String? = nil,
        partyDate: Date? = nil,
        endDate: Date? = nil,
        isActive: Bool = true,
        isPublic: Bool? = nil,
        maxGuests: Int? = nil,
        hosts: [PartyHost]? = nil,
        guests: [PartyGuest]? = nil,
        mediaCount: Int? = nil,
        commentCount: Int? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.title = title
        self.description = description
        self.coverImageUrl = coverImageUrl
        self.locationName = location
        self.locationLat = nil
        self.locationLng = nil
        self.startsAt = partyDate
        self.endsAt = endDate
        self.status = isActive ? .active : .ended
        self.privacy = isPublic == true ? .publicParty : .inviteOnly
        self.maxGuests = maxGuests
        self.guestCount = nil
        self.hosts = hosts
        self.guests = guests
        self.mediaCount = mediaCount
        self.commentCount = commentCount
    }
}

// MARK: - Party State Enum (renamed to avoid conflict with PartyStatus struct)

enum PartyState: String, Codable, Sendable {
    case active = "active"
    case ended = "ended"
    case cancelled = "cancelled"
    case draft = "draft"
}

// MARK: - Party Privacy Enum

enum PartyPrivacy: String, Codable, Sendable {
    case inviteOnly = "invite_only"
    case publicParty = "public"
    case friendsOnly = "friends_only"
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
    case host = "host"      // DB uses "host" not "cohost"
    case cohost = "cohost"  // Keep for backward compatibility
}

// MARK: - Party Guest

/// Invitation/RSVP for party guests
struct PartyGuest: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let partyId: UUID
    let userId: UUID
    var status: GuestStatus
    let invitedBy: UUID?
    let createdAt: Date
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
        case createdAt = "created_at"
        case respondedAt = "responded_at"
        case user
        case party
    }

    // Backward compatibility computed property
    var invitedAt: Date { createdAt }

    // Convenience initializer for backward compatibility
    init(
        id: UUID = UUID(),
        partyId: UUID,
        userId: UUID,
        status: GuestStatus = .pending,
        invitedBy: UUID? = nil,
        invitedAt: Date = Date(),
        respondedAt: Date? = nil,
        user: User? = nil,
        party: Party? = nil
    ) {
        self.id = id
        self.partyId = partyId
        self.userId = userId
        self.status = status
        self.invitedBy = invitedBy
        self.createdAt = invitedAt
        self.respondedAt = respondedAt
        self.user = user
        self.party = party
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
    let storagePath: String
    var thumbnailPath: String?
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
        case storagePath = "storage_path"
        case thumbnailPath = "thumbnail_path"
        case caption
        case createdAt = "created_at"
        case duration
        case user
    }

    // Backward compatibility computed properties
    var url: String { storagePath }
    var thumbnailUrl: String? { thumbnailPath }

    // Convenience initializer for backward compatibility
    init(
        id: UUID = UUID(),
        partyId: UUID,
        userId: UUID,
        mediaType: MediaType,
        url: String,
        thumbnailUrl: String? = nil,
        caption: String? = nil,
        createdAt: Date = Date(),
        duration: Double? = nil,
        user: User? = nil
    ) {
        self.id = id
        self.partyId = partyId
        self.userId = userId
        self.mediaType = mediaType
        self.storagePath = url
        self.thumbnailPath = thumbnailUrl
        self.caption = caption
        self.createdAt = createdAt
        self.duration = duration
        self.user = user
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
    let userId: UUID
    var question: String
    var pollType: PollType
    let createdAt: Date
    var endsAt: Date?
    var isActive: Bool?

    // Relationships
    var options: [PollOption]?
    var creator: User?
    var totalVotes: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case partyId = "party_id"
        case userId = "user_id"
        case question
        case pollType = "poll_type"
        case createdAt = "created_at"
        case endsAt = "ends_at"
        case isActive = "is_active"
        case options
        case creator
        case totalVotes = "total_votes"
    }

    // Backward compatibility computed properties
    var createdBy: UUID { userId }
    var expiresAt: Date? { endsAt }

    // Convenience initializer for backward compatibility
    init(
        id: UUID = UUID(),
        partyId: UUID,
        createdBy: UUID,
        question: String,
        pollType: PollType = .singleChoice,
        createdAt: Date = Date(),
        expiresAt: Date? = nil,
        isActive: Bool = true,
        options: [PollOption]? = nil,
        creator: User? = nil,
        totalVotes: Int? = nil
    ) {
        self.id = id
        self.partyId = partyId
        self.userId = createdBy
        self.question = question
        self.pollType = pollType
        self.createdAt = createdAt
        self.endsAt = expiresAt
        self.isActive = isActive
        self.options = options
        self.creator = creator
        self.totalVotes = totalVotes
    }
}

enum PollType: String, Codable, Sendable {
    case singleChoice = "single_choice"
    case multipleChoice = "multiple_choice"
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
    let title: String?
    let description: String?
    let locationName: String?
    let locationLat: Double?
    let locationLng: Double?
    let startsAt: Date?
    let endsAt: Date?
    let maxGuests: Int?
    let privacy: PartyPrivacy?
    let status: PartyState?
    let createdBy: UUID?

    enum CodingKeys: String, CodingKey {
        case title
        case description
        case locationName = "location_name"
        case locationLat = "location_lat"
        case locationLng = "location_lng"
        case startsAt = "starts_at"
        case endsAt = "ends_at"
        case maxGuests = "max_guests"
        case privacy
        case status
        case createdBy = "created_by"
    }

    // Convenience initializer with old parameter names
    init(
        title: String? = nil,
        description: String? = nil,
        location: String? = nil,
        partyDate: Date? = nil,
        maxGuests: Int? = nil,
        createdBy: UUID? = nil
    ) {
        // Use default title if none provided
        self.title = title?.isEmpty == false ? title : "Untitled Party"
        self.description = description
        self.locationName = location
        self.locationLat = nil
        self.locationLng = nil
        self.startsAt = partyDate
        self.endsAt = nil
        self.maxGuests = maxGuests
        self.privacy = .inviteOnly
        self.status = PartyState.active
        self.createdBy = createdBy
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
