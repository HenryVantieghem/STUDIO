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
    var isPublic: Bool?
    var maxGuests: Int?

    // NEW: Party type and category
    var partyType: PartyType?
    var vibeStyle: VibeStyle?
    var dressCode: DressCode?

    // Relationships (populated via joins)
    var hosts: [PartyHost]?
    var guests: [PartyGuest]?
    var venueHops: [VenueHop]?  // Multi-location support
    var mediaCount: Int?
    var commentCount: Int?

    // Gamification stats
    var averageRating: Double?
    var totalVotes: Int?

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
        case partyType = "party_type"
        case vibeStyle = "vibe_style"
        case dressCode = "dress_code"
        case hosts
        case guests
        case venueHops = "venue_hops"
        case mediaCount = "media_count"
        case commentCount = "comment_count"
        case averageRating = "average_rating"
        case totalVotes = "total_votes"
    }
}

// MARK: - Party Type

/// Type of party event
enum PartyType: String, Codable, Sendable, CaseIterable {
    case pregame = "pregame"
    case mainEvent = "main_event"
    case afterparty = "afterparty"
    case dayParty = "day_party"
    case houseParty = "house_party"
    case rooftop = "rooftop"
    case nightclub = "nightclub"
    case festival = "festival"
    case rave = "rave"
    case cocktailParty = "cocktail_party"
    case poolParty = "pool_party"
    case other = "other"

    var label: String {
        switch self {
        case .pregame: return "PREGAME"
        case .mainEvent: return "MAIN EVENT"
        case .afterparty: return "AFTERPARTY"
        case .dayParty: return "DAY PARTY"
        case .houseParty: return "HOUSE PARTY"
        case .rooftop: return "ROOFTOP"
        case .nightclub: return "NIGHTCLUB"
        case .festival: return "FESTIVAL"
        case .rave: return "RAVE"
        case .cocktailParty: return "COCKTAIL PARTY"
        case .poolParty: return "POOL PARTY"
        case .other: return "OTHER"
        }
    }

    var emoji: String {
        switch self {
        case .pregame: return "🍻"
        case .mainEvent: return "🎉"
        case .afterparty: return "🌙"
        case .dayParty: return "☀️"
        case .houseParty: return "🏠"
        case .rooftop: return "🌆"
        case .nightclub: return "🪩"
        case .festival: return "🎪"
        case .rave: return "💊"
        case .cocktailParty: return "🍸"
        case .poolParty: return "🏊"
        case .other: return "✨"
        }
    }

    var icon: String {
        switch self {
        case .pregame: return "cup.and.saucer.fill"
        case .mainEvent: return "star.fill"
        case .afterparty: return "moon.stars.fill"
        case .dayParty: return "sun.max.fill"
        case .houseParty: return "house.fill"
        case .rooftop: return "building.2.fill"
        case .nightclub: return "speaker.wave.3.fill"
        case .festival: return "tent.fill"
        case .rave: return "waveform.path"
        case .cocktailParty: return "wineglass.fill"
        case .poolParty: return "figure.pool.swim"
        case .other: return "sparkles"
        }
    }
}

// MARK: - Vibe Style

/// Overall vibe/atmosphere of the party
enum VibeStyle: String, Codable, Sendable, CaseIterable {
    case chill = "chill"
    case hype = "hype"
    case classy = "classy"
    case underground = "underground"
    case bougie = "bougie"
    case casual = "casual"
    case wild = "wild"
    case intimate = "intimate"

    var label: String {
        switch self {
        case .chill: return "CHILL"
        case .hype: return "HYPE"
        case .classy: return "CLASSY"
        case .underground: return "UNDERGROUND"
        case .bougie: return "BOUGIE"
        case .casual: return "CASUAL"
        case .wild: return "WILD"
        case .intimate: return "INTIMATE"
        }
    }

    var emoji: String {
        switch self {
        case .chill: return "😌"
        case .hype: return "🔥"
        case .classy: return "🥂"
        case .underground: return "🖤"
        case .bougie: return "💎"
        case .casual: return "👋"
        case .wild: return "🤪"
        case .intimate: return "✨"
        }
    }
}

// MARK: - Dress Code

/// Dress code for the party
enum DressCode: String, Codable, Sendable, CaseIterable {
    case casual = "casual"
    case smart = "smart"
    case allBlack = "all_black"
    case white = "white"
    case costumes = "costumes"
    case formal = "formal"
    case streetwear = "streetwear"
    case anything = "anything"

    var label: String {
        switch self {
        case .casual: return "CASUAL"
        case .smart: return "SMART CASUAL"
        case .allBlack: return "ALL BLACK"
        case .white: return "ALL WHITE"
        case .costumes: return "COSTUMES"
        case .formal: return "FORMAL"
        case .streetwear: return "STREETWEAR"
        case .anything: return "ANYTHING GOES"
        }
    }

    var emoji: String {
        switch self {
        case .casual: return "👕"
        case .smart: return "👔"
        case .allBlack: return "🖤"
        case .white: return "🤍"
        case .costumes: return "🎭"
        case .formal: return "🎩"
        case .streetwear: return "👟"
        case .anything: return "🎨"
        }
    }
}

// MARK: - Venue Hop

/// Multi-location party support - move from place to place
struct VenueHop: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let partyId: UUID
    var sequence: Int           // Order of venues (1, 2, 3...)
    var venueName: String
    var location: String?
    var startTime: Date?
    var endTime: Date?
    var description: String?
    var isCurrentVenue: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case partyId = "party_id"
        case sequence
        case venueName = "venue_name"
        case location
        case startTime = "start_time"
        case endTime = "end_time"
        case description
        case isCurrentVenue = "is_current_venue"
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

// MARK: - Drink Tracking

/// Track drinks consumed at the party
struct DrinkLog: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let partyId: UUID
    let userId: UUID
    var drinkType: DrinkType
    var customDrink: String?  // For custom drinks
    var quantity: Int
    var emoji: String?
    let createdAt: Date

    // Joined user profile
    var user: User?

    enum CodingKeys: String, CodingKey {
        case id
        case partyId = "party_id"
        case userId = "user_id"
        case drinkType = "drink_type"
        case customDrink = "custom_drink"
        case quantity
        case emoji
        case createdAt = "created_at"
        case user
    }
}

/// Types of drinks
enum DrinkType: String, Codable, Sendable, CaseIterable {
    case beer = "beer"
    case wine = "wine"
    case cocktail = "cocktail"
    case shot = "shot"
    case champagne = "champagne"
    case whiskey = "whiskey"
    case vodka = "vodka"
    case tequila = "tequila"
    case gin = "gin"
    case rum = "rum"
    case margarita = "margarita"
    case martini = "martini"
    case mojito = "mojito"
    case water = "water"
    case soda = "soda"
    case redbull = "redbull"
    case custom = "custom"

    var label: String {
        switch self {
        case .beer: return "BEER"
        case .wine: return "WINE"
        case .cocktail: return "COCKTAIL"
        case .shot: return "SHOT"
        case .champagne: return "CHAMPAGNE"
        case .whiskey: return "WHISKEY"
        case .vodka: return "VODKA"
        case .tequila: return "TEQUILA"
        case .gin: return "GIN"
        case .rum: return "RUM"
        case .margarita: return "MARGARITA"
        case .martini: return "MARTINI"
        case .mojito: return "MOJITO"
        case .water: return "WATER"
        case .soda: return "SODA"
        case .redbull: return "RED BULL"
        case .custom: return "CUSTOM"
        }
    }

    var emoji: String {
        switch self {
        case .beer: return "🍺"
        case .wine: return "🍷"
        case .cocktail: return "🍹"
        case .shot: return "🥃"
        case .champagne: return "🥂"
        case .whiskey: return "🥃"
        case .vodka: return "🫗"
        case .tequila: return "🌵"
        case .gin: return "🍸"
        case .rum: return "🏴‍☠️"
        case .margarita: return "🍸"
        case .martini: return "🍸"
        case .mojito: return "🌿"
        case .water: return "💧"
        case .soda: return "🥤"
        case .redbull: return "⚡"
        case .custom: return "🍾"
        }
    }

    /// Alcoholic vs non-alcoholic
    var isAlcoholic: Bool {
        switch self {
        case .water, .soda, .redbull:
            return false
        default:
            return true
        }
    }

    /// Standard drink units (for drink counting)
    var standardUnits: Double {
        switch self {
        case .beer: return 1.0
        case .wine: return 1.5
        case .cocktail: return 1.5
        case .shot: return 1.0
        case .champagne: return 1.5
        case .whiskey: return 1.5
        case .vodka: return 1.0
        case .tequila: return 1.0
        case .gin: return 1.0
        case .rum: return 1.0
        case .margarita: return 2.0
        case .martini: return 2.0
        case .mojito: return 1.5
        case .water, .soda, .redbull: return 0
        case .custom: return 1.0
        }
    }
}

// MARK: - Gamification Models

/// User XP and level system
struct UserStats: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let userId: UUID
    var totalXP: Int
    var level: Int
    var partiesHosted: Int
    var partiesAttended: Int
    var photosShared: Int
    var pollsCreated: Int
    var pollsVoted: Int
    var drinksLogged: Int
    var currentStreak: Int
    var longestStreak: Int
    var lastActiveDate: Date?

    // Computed properties
    var levelTitle: String {
        switch level {
        case 0..<5: return "PARTY ROOKIE"
        case 5..<10: return "PARTY STARTER"
        case 10..<20: return "PARTY PRO"
        case 20..<35: return "PARTY LEGEND"
        case 35..<50: return "AFTERDARK VIP"
        default: return "AFTERDARK ICON"
        }
    }

    var xpToNextLevel: Int {
        let nextLevelXP = (level + 1) * (level + 1) * 100
        return max(0, nextLevelXP - totalXP)
    }

    var levelProgress: Double {
        let currentLevelXP = level * level * 100
        let nextLevelXP = (level + 1) * (level + 1) * 100
        let progressXP = totalXP - currentLevelXP
        let neededXP = nextLevelXP - currentLevelXP
        return Double(progressXP) / Double(neededXP)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case totalXP = "total_xp"
        case level
        case partiesHosted = "parties_hosted"
        case partiesAttended = "parties_attended"
        case photosShared = "photos_shared"
        case pollsCreated = "polls_created"
        case pollsVoted = "polls_voted"
        case drinksLogged = "drinks_logged"
        case currentStreak = "current_streak"
        case longestStreak = "longest_streak"
        case lastActiveDate = "last_active_date"
    }
}

/// Achievement badges users can earn
struct Achievement: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    var achievementType: AchievementType
    var unlockedAt: Date?
    var progress: Int
    var target: Int

    var isUnlocked: Bool {
        progress >= target
    }

    var progressPercentage: Double {
        Double(progress) / Double(target)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case achievementType = "achievement_type"
        case unlockedAt = "unlocked_at"
        case progress
        case target
    }
}

/// Types of achievements
enum AchievementType: String, Codable, Sendable, CaseIterable {
    case firstParty = "first_party"
    case partyAnimal = "party_animal"
    case socialButterfly = "social_butterfly"
    case photoProof = "photo_proof"
    case pollMaster = "poll_master"
    case vibeChecker = "vibe_checker"
    case nightOwl = "night_owl"
    case earlyBird = "early_bird"
    case weekWarrior = "week_warrior"
    case monthlyLegend = "monthly_legend"
    case bestHost = "best_host"
    case partyMVP = "party_mvp"
    case bestDressed = "best_dressed"
    case drinkTracker = "drink_tracker"
    case hydrationHero = "hydration_hero"
    case venueHopper = "venue_hopper"
    case afterdarkIcon = "afterdark_icon"

    var label: String {
        switch self {
        case .firstParty: return "FIRST PARTY"
        case .partyAnimal: return "PARTY ANIMAL"
        case .socialButterfly: return "SOCIAL BUTTERFLY"
        case .photoProof: return "PHOTO PROOF"
        case .pollMaster: return "POLL MASTER"
        case .vibeChecker: return "VIBE CHECKER"
        case .nightOwl: return "NIGHT OWL"
        case .earlyBird: return "EARLY BIRD"
        case .weekWarrior: return "WEEK WARRIOR"
        case .monthlyLegend: return "MONTHLY LEGEND"
        case .bestHost: return "BEST HOST"
        case .partyMVP: return "PARTY MVP"
        case .bestDressed: return "BEST DRESSED"
        case .drinkTracker: return "DRINK TRACKER"
        case .hydrationHero: return "HYDRATION HERO"
        case .venueHopper: return "VENUE HOPPER"
        case .afterdarkIcon: return "AFTERDARK ICON"
        }
    }

    var description: String {
        switch self {
        case .firstParty: return "Host your first party"
        case .partyAnimal: return "Attend 10 parties"
        case .socialButterfly: return "Invite 50 guests"
        case .photoProof: return "Share 100 photos"
        case .pollMaster: return "Create 20 polls"
        case .vibeChecker: return "Update vibe 50 times"
        case .nightOwl: return "Active after 2 AM"
        case .earlyBird: return "First to arrive 5 times"
        case .weekWarrior: return "7 day streak"
        case .monthlyLegend: return "30 day streak"
        case .bestHost: return "Get 5-star host rating"
        case .partyMVP: return "Win MVP poll 3 times"
        case .bestDressed: return "Win best dressed poll"
        case .drinkTracker: return "Log 100 drinks"
        case .hydrationHero: return "Log 50 waters"
        case .venueHopper: return "Attend 5 venue hops"
        case .afterdarkIcon: return "Reach level 50"
        }
    }

    var emoji: String {
        switch self {
        case .firstParty: return "🎉"
        case .partyAnimal: return "🦁"
        case .socialButterfly: return "🦋"
        case .photoProof: return "📸"
        case .pollMaster: return "📊"
        case .vibeChecker: return "✨"
        case .nightOwl: return "🦉"
        case .earlyBird: return "🐦"
        case .weekWarrior: return "🔥"
        case .monthlyLegend: return "👑"
        case .bestHost: return "⭐"
        case .partyMVP: return "🏆"
        case .bestDressed: return "👗"
        case .drinkTracker: return "🍻"
        case .hydrationHero: return "💧"
        case .venueHopper: return "🚀"
        case .afterdarkIcon: return "🌙"
        }
    }

    var xpReward: Int {
        switch self {
        case .firstParty: return 25
        case .partyAnimal: return 100
        case .socialButterfly: return 150
        case .photoProof: return 100
        case .pollMaster: return 100
        case .vibeChecker: return 50
        case .nightOwl: return 75
        case .earlyBird: return 50
        case .weekWarrior: return 50
        case .monthlyLegend: return 200
        case .bestHost: return 150
        case .partyMVP: return 100
        case .bestDressed: return 75
        case .drinkTracker: return 100
        case .hydrationHero: return 75
        case .venueHopper: return 100
        case .afterdarkIcon: return 500
        }
    }

    var target: Int {
        switch self {
        case .firstParty: return 1
        case .partyAnimal: return 10
        case .socialButterfly: return 50
        case .photoProof: return 100
        case .pollMaster: return 20
        case .vibeChecker: return 50
        case .nightOwl: return 5
        case .earlyBird: return 5
        case .weekWarrior: return 7
        case .monthlyLegend: return 30
        case .bestHost: return 1
        case .partyMVP: return 3
        case .bestDressed: return 1
        case .drinkTracker: return 100
        case .hydrationHero: return 50
        case .venueHopper: return 5
        case .afterdarkIcon: return 50
        }
    }
}

// MARK: - Party Rating

/// Rate parties and hosts
struct PartyRating: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let partyId: UUID
    let userId: UUID
    var overallRating: Int      // 1-5 stars
    var vibeRating: Int?        // 1-5
    var musicRating: Int?       // 1-5
    var crowdRating: Int?       // 1-5
    var venueRating: Int?       // 1-5
    var comment: String?
    let createdAt: Date

    var user: User?

    enum CodingKeys: String, CodingKey {
        case id
        case partyId = "party_id"
        case userId = "user_id"
        case overallRating = "overall_rating"
        case vibeRating = "vibe_rating"
        case musicRating = "music_rating"
        case crowdRating = "crowd_rating"
        case venueRating = "venue_rating"
        case comment
        case createdAt = "created_at"
        case user
    }
}

/// Host rating (separate from party)
struct HostRating: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let hostId: UUID
    let raterId: UUID
    let partyId: UUID
    var rating: Int             // 1-5 stars
    var comment: String?
    let createdAt: Date

    var rater: User?

    enum CodingKeys: String, CodingKey {
        case id
        case hostId = "host_id"
        case raterId = "rater_id"
        case partyId = "party_id"
        case rating
        case comment
        case createdAt = "created_at"
        case rater
    }
}

// MARK: - Create DTOs (Extended)

/// DTO for creating party with extended fields
struct CreatePartyRequestExtended: Encodable, Sendable {
    let title: String
    let description: String?
    let location: String?
    let partyDate: Date?
    let maxGuests: Int?
    let partyType: PartyType?
    let vibeStyle: VibeStyle?
    let dressCode: DressCode?

    enum CodingKeys: String, CodingKey {
        case title
        case description
        case location
        case partyDate = "party_date"
        case maxGuests = "max_guests"
        case partyType = "party_type"
        case vibeStyle = "vibe_style"
        case dressCode = "dress_code"
    }
}

/// DTO for logging drinks
struct LogDrinkRequest: Encodable, Sendable {
    let partyId: UUID
    let drinkType: DrinkType
    let customDrink: String?
    let quantity: Int

    enum CodingKeys: String, CodingKey {
        case partyId = "party_id"
        case drinkType = "drink_type"
        case customDrink = "custom_drink"
        case quantity
    }
}

/// DTO for adding venue hop
struct AddVenueHopRequest: Encodable, Sendable {
    let partyId: UUID
    let venueName: String
    let location: String?
    let startTime: Date?
    let description: String?

    enum CodingKeys: String, CodingKey {
        case partyId = "party_id"
        case venueName = "venue_name"
        case location
        case startTime = "start_time"
        case description
    }
}

/// DTO for rating a party
struct RatePartyRequest: Encodable, Sendable {
    let partyId: UUID
    let overallRating: Int
    let vibeRating: Int?
    let musicRating: Int?
    let crowdRating: Int?
    let venueRating: Int?
    let comment: String?

    enum CodingKeys: String, CodingKey {
        case partyId = "party_id"
        case overallRating = "overall_rating"
        case vibeRating = "vibe_rating"
        case musicRating = "music_rating"
        case crowdRating = "crowd_rating"
        case venueRating = "venue_rating"
        case comment
    }
}
