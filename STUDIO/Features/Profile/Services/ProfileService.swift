//
//  ProfileService.swift
//  STUDIO
//
//  Profile and social operations
//

import Foundation
import Supabase

// MARK: - Profile Service

/// Service for profile-related operations
final class ProfileService: Sendable {

    // MARK: - Fetch Profile

    /// Fetch a user's profile by ID
    func getProfile(userId: UUID) async throws -> User {
        let user: User = try await supabase
            .from("profiles")
            .select()
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
            .value

        return user
    }

    /// Fetch current user's profile
    func getCurrentUserProfile() async throws -> User {
        let userId = try await supabase.auth.session.user.id

        let user: User = try await supabase
            .from("profiles")
            .select()
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
            .value

        return user
    }

    // MARK: - Update Profile

    /// Update current user's profile
    func updateProfile(
        displayName: String? = nil,
        username: String? = nil,
        bio: String? = nil,
        avatarUrl: String? = nil
    ) async throws -> User {
        let userId = try await supabase.auth.session.user.id

        var updates: [String: AnyEncodable] = [
            "updated_at": AnyEncodable(ISO8601DateFormatter().string(from: Date()))
        ]

        if let displayName {
            updates["display_name"] = AnyEncodable(displayName)
        }
        if let username {
            updates["username"] = AnyEncodable(username)
        }
        if let bio {
            updates["bio"] = AnyEncodable(bio)
        }
        if let avatarUrl {
            updates["avatar_url"] = AnyEncodable(avatarUrl)
        }

        let user: User = try await supabase
            .from("profiles")
            .update(updates)
            .eq("id", value: userId.uuidString)
            .select()
            .single()
            .execute()
            .value

        return user
    }

    // MARK: - Profile Stats

    /// Get comprehensive user statistics
    func getProfileStats(userId: UUID) async throws -> UserProfileStats {
        // Run all queries in parallel
        async let hostedCount = getHostedPartiesCount(userId: userId)
        async let attendedCount = getAttendedPartiesCount(userId: userId)
        async let followersCount = getFollowersCount(userId: userId)
        async let followingCount = getFollowingCount(userId: userId)
        async let mediaCount = getMediaCount(userId: userId)
        async let achievementsCounts = getAchievementCounts(userId: userId)

        let counts = try await achievementsCounts

        return UserProfileStats(
            partiesHosted: try await hostedCount,
            partiesAttended: try await attendedCount,
            followersCount: try await followersCount,
            followingCount: try await followingCount,
            mediaUploaded: try await mediaCount,
            achievementsCount: counts.total,
            mvpCount: counts.mvp,
            bestDressedCount: counts.bestDressed
        )
    }

    /// Legacy stats method for compatibility
    func getUserStats(userId: UUID) async throws -> UserStats {
        let stats = try await getProfileStats(userId: userId)
        return UserStats(
            partiesHosted: stats.partiesHosted,
            partiesAttended: stats.partiesAttended,
            mediaUploaded: stats.mediaUploaded
        )
    }

    // MARK: - Count Helpers

    private func getHostedPartiesCount(userId: UUID) async throws -> Int {
        let parties: [Party] = try await supabase
            .from("party_hosts")
            .select("party_id")
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
        return parties.count
    }

    private func getAttendedPartiesCount(userId: UUID) async throws -> Int {
        let guests: [PartyGuest] = try await supabase
            .from("party_guests")
            .select("id")
            .eq("user_id", value: userId.uuidString)
            .eq("status", value: GuestStatus.accepted.rawValue)
            .execute()
            .value
        return guests.count
    }

    private func getFollowersCount(userId: UUID) async throws -> Int {
        let followers: [Follow] = try await supabase
            .from("follows")
            .select("follower_id")
            .eq("following_id", value: userId.uuidString)
            .execute()
            .value
        return followers.count
    }

    private func getFollowingCount(userId: UUID) async throws -> Int {
        let following: [Follow] = try await supabase
            .from("follows")
            .select("following_id")
            .eq("follower_id", value: userId.uuidString)
            .execute()
            .value
        return following.count
    }

    private func getMediaCount(userId: UUID) async throws -> Int {
        let media: [PartyMedia] = try await supabase
            .from("party_media")
            .select("id")
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
        return media.count
    }

    private func getAchievementCounts(userId: UUID) async throws -> (total: Int, mvp: Int, bestDressed: Int) {
        let achievements: [UserAchievement] = try await supabase
            .from("user_achievements")
            .select("achievement_type")
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value

        let mvpCount = achievements.filter { $0.achievementType == .partyMVP }.count
        let bestDressedCount = achievements.filter { $0.achievementType == .bestDressed }.count

        return (achievements.count, mvpCount, bestDressedCount)
    }

    // MARK: - Achievements

    /// Get user's achievements
    func getAchievements(userId: UUID, limit: Int = 50) async throws -> [UserAchievement] {
        let achievements: [UserAchievement] = try await supabase
            .from("user_achievements")
            .select("""
                *,
                party:parties(id, title, cover_image_url, starts_at)
            """)
            .eq("user_id", value: userId.uuidString)
            .order("awarded_at", ascending: false)
            .limit(limit)
            .execute()
            .value

        return achievements
    }

    /// Award achievement to user
    func awardAchievement(
        userId: UUID,
        partyId: UUID,
        pollId: UUID? = nil,
        type: AchievementType,
        title: String,
        description: String? = nil,
        voteCount: Int = 0,
        totalVotes: Int = 0
    ) async throws -> UserAchievement {
        struct CreateAchievement: Encodable {
            let user_id: String
            let party_id: String
            let poll_id: String?
            let achievement_type: String
            let title: String
            let description: String?
            let vote_count: Int
            let total_votes: Int
        }

        let payload = CreateAchievement(
            user_id: userId.uuidString,
            party_id: partyId.uuidString,
            poll_id: pollId?.uuidString,
            achievement_type: type.rawValue,
            title: title,
            description: description,
            vote_count: voteCount,
            total_votes: totalVotes
        )

        let achievement: UserAchievement = try await supabase
            .from("user_achievements")
            .insert(payload)
            .select()
            .single()
            .execute()
            .value

        return achievement
    }

    // MARK: - User's Parties

    /// Get parties hosted by a user
    func getHostedParties(userId: UUID, limit: Int = 50) async throws -> [Party] {
        // First get party IDs from party_hosts
        struct HostRecord: Codable {
            let partyId: UUID

            enum CodingKeys: String, CodingKey {
                case partyId = "party_id"
            }
        }

        let hostRecords: [HostRecord] = try await supabase
            .from("party_hosts")
            .select("party_id")
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value

        guard !hostRecords.isEmpty else { return [] }

        let partyIds = hostRecords.map { $0.partyId.uuidString }

        let parties: [Party] = try await supabase
            .from("parties")
            .select("""
                *,
                hosts:party_hosts(user_id, role, user:profiles(id, username, display_name, avatar_url))
            """)
            .in("id", values: partyIds)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value

        return parties
    }

    /// Get parties attended by a user
    func getAttendedParties(userId: UUID, limit: Int = 50) async throws -> [Party] {
        struct GuestWithParty: Codable {
            let party: Party?
        }

        let guestRecords: [GuestWithParty] = try await supabase
            .from("party_guests")
            .select("""
                party:parties(
                    *,
                    hosts:party_hosts(user_id, role, user:profiles(id, username, display_name, avatar_url))
                )
            """)
            .eq("user_id", value: userId.uuidString)
            .eq("status", value: GuestStatus.accepted.rawValue)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value

        return guestRecords.compactMap { $0.party }
    }

    // MARK: - Tagged Media

    /// Get media where user is tagged or uploaded
    func getTaggedMedia(userId: UUID, limit: Int = 50) async throws -> [PartyMedia] {
        let media: [PartyMedia] = try await supabase
            .from("party_media")
            .select("""
                *,
                user:profiles(id, username, display_name, avatar_url),
                party:parties(id, title)
            """)
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value

        return media
    }

    // MARK: - Follow Operations

    /// Check if current user is following a user
    func isFollowing(userId: UUID) async throws -> Bool {
        let currentUserId = try await supabase.auth.session.user.id

        let follows: [Follow] = try await supabase
            .from("follows")
            .select()
            .eq("follower_id", value: currentUserId.uuidString)
            .eq("following_id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value

        return !follows.isEmpty
    }

    /// Follow a user
    func followUser(userId: UUID) async throws {
        let currentUserId = try await supabase.auth.session.user.id

        struct FollowPayload: Encodable {
            let follower_id: String
            let following_id: String
        }

        let payload = FollowPayload(
            follower_id: currentUserId.uuidString,
            following_id: userId.uuidString
        )

        try await supabase
            .from("follows")
            .insert(payload)
            .execute()
    }

    /// Unfollow a user
    func unfollowUser(userId: UUID) async throws {
        let currentUserId = try await supabase.auth.session.user.id

        try await supabase
            .from("follows")
            .delete()
            .eq("follower_id", value: currentUserId.uuidString)
            .eq("following_id", value: userId.uuidString)
            .execute()
    }

    /// Get user's followers
    func getFollowers(userId: UUID, limit: Int = 100) async throws -> [User] {
        struct FollowWithUser: Codable {
            let follower: User?
        }

        let follows: [FollowWithUser] = try await supabase
            .from("follows")
            .select("follower:profiles!follows_follower_id_fkey(id, username, display_name, avatar_url, bio)")
            .eq("following_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value

        return follows.compactMap { $0.follower }
    }

    /// Get users the user is following
    func getFollowing(userId: UUID, limit: Int = 100) async throws -> [User] {
        struct FollowWithUser: Codable {
            let following: User?
        }

        let follows: [FollowWithUser] = try await supabase
            .from("follows")
            .select("following:profiles!follows_following_id_fkey(id, username, display_name, avatar_url, bio)")
            .eq("follower_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value

        return follows.compactMap { $0.following }
    }

    // MARK: - Search Users

    /// Search users by username or display name
    func searchUsers(query: String, limit: Int = 20) async throws -> [User] {
        let users: [User] = try await supabase
            .from("profiles")
            .select()
            .or("username.ilike.%\(query)%,display_name.ilike.%\(query)%")
            .limit(limit)
            .execute()
            .value

        return users
    }

    // MARK: - Check Username Availability

    /// Check if a username is available
    func isUsernameAvailable(_ username: String) async throws -> Bool {
        let currentUserId = try await supabase.auth.session.user.id

        let existingUsers: [User] = try await supabase
            .from("profiles")
            .select("id")
            .eq("username", value: username)
            .neq("id", value: currentUserId.uuidString)
            .limit(1)
            .execute()
            .value

        return existingUsers.isEmpty
    }
}

// MARK: - User Stats Model (Legacy)

struct UserStats: Sendable {
    let partiesHosted: Int
    let partiesAttended: Int
    let mediaUploaded: Int

    var totalParties: Int {
        partiesHosted + partiesAttended
    }
}
