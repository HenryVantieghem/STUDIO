//
//  User.swift
//  STUDIO
//
//  Created by Claude on 12/16/25.
//

import Foundation

/// User profile model matching Supabase profiles table
struct User: Codable, Identifiable, Sendable, Hashable {
    let id: UUID
    var username: String
    var displayName: String?
    var avatarUrl: String?
    var bio: String?
    var isPrivate: Bool
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case bio
        case isPrivate = "is_private"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // Memberwise initializer for creating User instances directly
    init(
        id: UUID,
        username: String,
        displayName: String? = nil,
        avatarUrl: String? = nil,
        bio: String? = nil,
        isPrivate: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.username = username
        self.displayName = displayName
        self.avatarUrl = avatarUrl
        self.bio = bio
        self.isPrivate = isPrivate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        username = try container.decode(String.self, forKey: .username)
        displayName = try container.decodeIfPresent(String.self, forKey: .displayName)
        avatarUrl = try container.decodeIfPresent(String.self, forKey: .avatarUrl)
        bio = try container.decodeIfPresent(String.self, forKey: .bio)
        isPrivate = try container.decodeIfPresent(Bool.self, forKey: .isPrivate) ?? false
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
}

/// User creation payload for signup
struct CreateUserPayload: Encodable, Sendable {
    let id: UUID
    let username: String
    let displayName: String?
    let avatarUrl: String?

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
    }
}

/// User update payload
struct UpdateUserPayload: Encodable, Sendable {
    var username: String?
    var displayName: String?
    var avatarUrl: String?
    var bio: String?
    var isPrivate: Bool?

    enum CodingKeys: String, CodingKey {
        case username
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case bio
        case isPrivate = "is_private"
    }
}

// MARK: - Notification Model

/// Notification model matching Supabase notifications table
struct AppNotification: Codable, Identifiable, Sendable, Hashable {
    let id: UUID
    let userId: UUID
    let type: NotificationType
    var title: String?
    var body: String?
    var data: NotificationData?
    var read: Bool
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case type
        case title
        case body
        case data
        case read
        case createdAt = "created_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decode(UUID.self, forKey: .userId)
        type = try container.decode(NotificationType.self, forKey: .type)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        body = try container.decodeIfPresent(String.self, forKey: .body)
        data = try container.decodeIfPresent(NotificationData.self, forKey: .data)
        read = try container.decodeIfPresent(Bool.self, forKey: .read) ?? false
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encodeIfPresent(body, forKey: .body)
        try container.encodeIfPresent(data, forKey: .data)
        try container.encode(read, forKey: .read)
        try container.encode(createdAt, forKey: .createdAt)
    }
}

/// Notification types (for in-app notifications)
enum NotificationType: String, Codable, Sendable, Hashable {
    case partyInvite = "party_invite"
    case partyUpdate = "party_update"
    case partyReminder = "party_reminder"
    case comment = "comment"
    case newComment = "new_comment"
    case poll = "poll"
    case newPoll = "new_poll"
    case pollEnded = "poll_ended"
    case status = "status"
    case follow = "follow"
    case newFollower = "new_follower"
    case mention = "mention"
    case media = "media"
    case system = "system"

    var icon: String {
        switch self {
        case .partyInvite: return "envelope"
        case .partyUpdate, .partyReminder: return "party.popper"
        case .comment, .newComment: return "bubble.left"
        case .poll, .newPoll, .pollEnded: return "chart.bar"
        case .status: return "person.wave.2"
        case .follow, .newFollower: return "person.badge.plus"
        case .mention: return "at"
        case .media: return "photo"
        case .system: return "bell"
        }
    }
}

/// Notification data payload
struct NotificationData: Codable, Sendable, Hashable {
    var followerId: UUID?
    var followerUsername: String?
    var followerAvatarUrl: String?
    var followerDisplayName: String?
    var partyId: UUID?
    var partyTitle: String?
    var commentId: UUID?
    var pollId: UUID?
    var fromUserId: UUID?

    enum CodingKeys: String, CodingKey {
        case followerId = "follower_id"
        case followerUsername = "follower_username"
        case followerAvatarUrl = "follower_avatar_url"
        case followerDisplayName = "follower_display_name"
        case partyId = "party_id"
        case partyTitle = "party_title"
        case commentId = "comment_id"
        case pollId = "poll_id"
        case fromUserId = "from_user_id"
    }
}

// MARK: - User Achievement

/// Achievement earned from party polls or activities
struct UserAchievement: Codable, Identifiable, Sendable, Hashable {
    let id: UUID
    let userId: UUID
    let partyId: UUID
    let pollId: UUID?
    let achievementType: AchievementType
    let title: String
    var description: String?
    let awardedAt: Date
    var voteCount: Int
    var totalVotes: Int
    let createdAt: Date

    // Joined data
    var party: Party?
    var user: User?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case partyId = "party_id"
        case pollId = "poll_id"
        case achievementType = "achievement_type"
        case title
        case description
        case awardedAt = "awarded_at"
        case voteCount = "vote_count"
        case totalVotes = "total_votes"
        case createdAt = "created_at"
        case party
        case user
    }
}

/// Achievement type categories
enum AchievementType: String, Codable, Sendable, CaseIterable {
    case partyMVP = "party_mvp"
    case bestDressed = "best_dressed"
    case bestMoment = "best_moment"
    case mostPhotos = "most_photos"
    case firstArrival = "first_arrival"
    case lastStanding = "last_standing"
    case hypeMaster = "hype_master"
    case custom = "custom"

    var displayTitle: String {
        switch self {
        case .partyMVP: return "PARTY MVP"
        case .bestDressed: return "BEST DRESSED"
        case .bestMoment: return "BEST MOMENT"
        case .mostPhotos: return "MOST PHOTOS"
        case .firstArrival: return "FIRST ARRIVAL"
        case .lastStanding: return "LAST STANDING"
        case .hypeMaster: return "HYPE MASTER"
        case .custom: return "ACHIEVEMENT"
        }
    }

    var icon: String {
        switch self {
        case .partyMVP: return "crown.fill"
        case .bestDressed: return "sparkles"
        case .bestMoment: return "star.fill"
        case .mostPhotos: return "camera.fill"
        case .firstArrival: return "clock.fill"
        case .lastStanding: return "moon.stars.fill"
        case .hypeMaster: return "flame.fill"
        case .custom: return "trophy.fill"
        }
    }

    var description: String {
        switch self {
        case .partyMVP: return "Voted most valuable partier"
        case .bestDressed: return "Best fashion of the night"
        case .bestMoment: return "Created the best moment"
        case .mostPhotos: return "Captured the most memories"
        case .firstArrival: return "First to arrive"
        case .lastStanding: return "Last one standing"
        case .hypeMaster: return "Kept the energy high"
        case .custom: return "Special achievement"
        }
    }
}

// MARK: - Extended User Stats

/// Comprehensive user statistics for profile display
struct UserProfileStats: Sendable {
    let partiesHosted: Int
    let partiesAttended: Int
    let followersCount: Int
    let followingCount: Int
    let mediaUploaded: Int
    let achievementsCount: Int
    let mvpCount: Int
    let bestDressedCount: Int

    var totalParties: Int {
        partiesHosted + partiesAttended
    }

    static let empty = UserProfileStats(
        partiesHosted: 0,
        partiesAttended: 0,
        followersCount: 0,
        followingCount: 0,
        mediaUploaded: 0,
        achievementsCount: 0,
        mvpCount: 0,
        bestDressedCount: 0
    )
}

// MARK: - Follow Relationship

/// Follow relationship between users
struct Follow: Codable, Sendable, Hashable {
    let followerId: UUID
    let followingId: UUID
    let createdAt: Date

    // Joined user data
    var follower: User?
    var following: User?

    enum CodingKeys: String, CodingKey {
        case followerId = "follower_id"
        case followingId = "following_id"
        case createdAt = "created_at"
        case follower
        case following
    }
}

// MARK: - User with Stats (for lists)

/// User with additional context for display in lists
struct UserWithContext: Codable, Identifiable, Sendable, Hashable {
    let id: UUID
    var username: String
    var displayName: String?
    var avatarUrl: String?
    var bio: String?
    var isFollowing: Bool?
    var isFollower: Bool?
    var mutualFollowersCount: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case bio
        case isFollowing = "is_following"
        case isFollower = "is_follower"
        case mutualFollowersCount = "mutual_followers_count"
    }
}
