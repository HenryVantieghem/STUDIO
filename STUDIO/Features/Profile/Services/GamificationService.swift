//
//  GamificationService.swift
//  STUDIO
//
//  Service for user XP, levels, achievements, and streaks
//  Basel Afterdark Design System
//

import Foundation
import Supabase

// MARK: - Gamification Service

/// Service for managing user gamification - XP, levels, achievements
final class GamificationService: Sendable {

    // MARK: - XP Constants

    // XP rewards
    private let xpHostParty = 100
    private let xpAttendParty = 25
    private let xpSharePhoto = 10
    private let xpPostComment = 5
    private let xpPostStatus = 5
    private let xpVotePoll = 3
    private let xpLogDrink = 2
    private let xpRequestSong = 5
    private let xpDailyStreak = 20  // Bonus per day in streak

    // Level formula: Level = sqrt(totalXP / 100)
    // XP to next level: (level + 1)^2 * 100 - totalXP

    // MARK: - User Stats

    /// Get user stats
    func getUserStats(userId: UUID? = nil) async throws -> UserStats? {
        let targetUserId: UUID
        if let userId {
            targetUserId = userId
        } else {
            targetUserId = try await supabase.auth.session.user.id
        }

        let stats: [UserStats] = try await supabase
            .from("user_stats")
            .select("*")
            .eq("user_id", value: targetUserId.uuidString)
            .limit(1)
            .execute()
            .value

        return stats.first
    }

    /// Create initial user stats
    func createUserStats() async throws -> UserStats {
        let userId = try await supabase.auth.session.user.id

        let request: [String: AnyEncodable] = [
            "user_id": AnyEncodable(userId),
            "total_xp": AnyEncodable(0),
            "level": AnyEncodable(1),
            "parties_hosted": AnyEncodable(0),
            "parties_attended": AnyEncodable(0),
            "photos_shared": AnyEncodable(0),
            "polls_created": AnyEncodable(0),
            "polls_voted": AnyEncodable(0),
            "drinks_logged": AnyEncodable(0),
            "current_streak": AnyEncodable(0),
            "longest_streak": AnyEncodable(0),
            "last_active_date": AnyEncodable(Date())
        ]

        let stats: UserStats = try await supabase
            .from("user_stats")
            .insert(request)
            .select()
            .single()
            .execute()
            .value

        return stats
    }

    // MARK: - Award XP

    /// Award XP for an action
    func awardXP(action: XPAction) async throws -> XPAwardResult {
        let userId = try await supabase.auth.session.user.id

        // Get current stats
        var stats = try await getUserStats(userId: userId)

        if stats == nil {
            stats = try await createUserStats()
        }

        guard var currentStats = stats else {
            throw GamificationError.statsNotFound
        }

        let xpAmount = xpForAction(action)
        let previousLevel = currentStats.level
        let newTotalXP = currentStats.totalXP + xpAmount
        let newLevel = calculateLevel(from: newTotalXP)

        // Update stat counters based on action
        var updates: [String: AnyEncodable] = [
            "total_xp": AnyEncodable(newTotalXP),
            "level": AnyEncodable(newLevel),
            "last_active_date": AnyEncodable(Date())
        ]

        switch action {
        case .hostParty:
            updates["parties_hosted"] = AnyEncodable(currentStats.partiesHosted + 1)
        case .attendParty:
            updates["parties_attended"] = AnyEncodable(currentStats.partiesAttended + 1)
        case .sharePhoto:
            updates["photos_shared"] = AnyEncodable(currentStats.photosShared + 1)
        case .createPoll:
            updates["polls_created"] = AnyEncodable(currentStats.pollsCreated + 1)
        case .votePoll:
            updates["polls_voted"] = AnyEncodable(currentStats.pollsVoted + 1)
        case .logDrink:
            updates["drinks_logged"] = AnyEncodable(currentStats.drinksLogged + 1)
        default:
            break
        }

        try await supabase
            .from("user_stats")
            .update(updates)
            .eq("user_id", value: userId.uuidString)
            .execute()

        // Check for level up
        let didLevelUp = newLevel > previousLevel

        // Check for new achievements
        let newAchievements = try await checkAchievements(stats: currentStats, action: action)

        return XPAwardResult(
            xpAwarded: xpAmount,
            newTotalXP: newTotalXP,
            previousLevel: previousLevel,
            newLevel: newLevel,
            didLevelUp: didLevelUp,
            newAchievements: newAchievements
        )
    }

    private func xpForAction(_ action: XPAction) -> Int {
        switch action {
        case .hostParty: return xpHostParty
        case .attendParty: return xpAttendParty
        case .sharePhoto: return xpSharePhoto
        case .postComment: return xpPostComment
        case .postStatus: return xpPostStatus
        case .votePoll: return xpVotePoll
        case .logDrink: return xpLogDrink
        case .requestSong: return xpRequestSong
        case .createPoll: return xpVotePoll * 2
        case .dailyStreak(let days): return xpDailyStreak * days
        }
    }

    private func calculateLevel(from xp: Int) -> Int {
        // Level = sqrt(totalXP / 100), minimum 1
        max(1, Int(sqrt(Double(xp) / 100.0)))
    }

    // MARK: - Streaks

    /// Update user streak
    func updateStreak() async throws -> (currentStreak: Int, isNewDay: Bool) {
        let userId = try await supabase.auth.session.user.id

        guard let stats = try await getUserStats(userId: userId) else {
            throw GamificationError.statsNotFound
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastActive = calendar.startOfDay(for: stats.lastActiveDate ?? Date.distantPast)

        let daysDifference = calendar.dateComponents([.day], from: lastActive, to: today).day ?? 0

        var newStreak = stats.currentStreak
        var longestStreak = stats.longestStreak
        var isNewDay = false

        if daysDifference == 0 {
            // Same day, no change
            isNewDay = false
        } else if daysDifference == 1 {
            // Consecutive day, increment streak
            newStreak += 1
            isNewDay = true
            if newStreak > longestStreak {
                longestStreak = newStreak
            }
            // Award streak bonus XP
            _ = try await awardXP(action: .dailyStreak(days: newStreak))
        } else {
            // Streak broken, reset to 1
            newStreak = 1
            isNewDay = true
        }

        // Update stats
        try await supabase
            .from("user_stats")
            .update([
                "current_streak": newStreak,
                "longest_streak": longestStreak,
                "last_active_date": ISO8601DateFormatter().string(from: Date())
            ] as [String: Any])
            .eq("user_id", value: userId.uuidString)
            .execute()

        return (currentStreak: newStreak, isNewDay: isNewDay)
    }

    // MARK: - Achievements

    /// Get user's achievements
    func getAchievements(userId: UUID? = nil) async throws -> [Achievement] {
        let targetUserId: UUID
        if let userId {
            targetUserId = userId
        } else {
            targetUserId = try await supabase.auth.session.user.id
        }

        let achievements: [Achievement] = try await supabase
            .from("achievements")
            .select("*")
            .eq("user_id", value: targetUserId.uuidString)
            .execute()
            .value

        return achievements
    }

    /// Check and award new achievements
    private func checkAchievements(stats: UserStats, action: XPAction) async throws -> [AchievementType] {
        let userId = try await supabase.auth.session.user.id

        // Get existing achievements
        let existingAchievements = try await getAchievements(userId: userId)
        let unlockedTypes = Set(existingAchievements.filter { $0.isUnlocked }.map { $0.achievementType })

        var newAchievements: [AchievementType] = []

        // Check each achievement type
        for type in AchievementType.allCases {
            // Skip if already unlocked
            guard !unlockedTypes.contains(type) else { continue }

            let currentProgress = progressForAchievement(type, stats: stats)
            let isUnlocked = currentProgress >= type.target

            // Upsert achievement progress
            let request: [String: AnyEncodable] = [
                "user_id": AnyEncodable(userId),
                "achievement_type": AnyEncodable(type.rawValue),
                "progress": AnyEncodable(currentProgress),
                "target": AnyEncodable(type.target),
                "unlocked_at": isUnlocked ? AnyEncodable(Date()) : AnyEncodable(Optional<Date>.none as Any)
            ]

            try await supabase
                .from("achievements")
                .upsert(request, onConflict: "user_id,achievement_type")
                .execute()

            if isUnlocked {
                newAchievements.append(type)
                // Award achievement XP
                _ = try await awardXP(action: .achievementUnlocked(xp: type.xpReward))
            }
        }

        return newAchievements
    }

    private func progressForAchievement(_ type: AchievementType, stats: UserStats) -> Int {
        switch type {
        case .firstParty:
            return stats.partiesAttended
        case .partyAnimal:
            return stats.partiesAttended
        case .photoProof:
            return stats.photosShared
        case .drinkMaster:
            return stats.drinksLogged
        case .pollster:
            return stats.pollsVoted
        case .hostWithMost:
            return stats.partiesHosted
        case .weekWarrior:
            return stats.currentStreak
        case .levelUp:
            return stats.level
        case .nightOwl:
            return stats.partiesAttended // TODO: Track late night parties
        case .trendsetter:
            return stats.pollsCreated
        case .socialButterfly:
            return 0 // TODO: Track unique people met
        case .legendaryHost:
            return stats.partiesHosted
        case .photographerPro:
            return stats.photosShared
        case .streakMaster:
            return stats.longestStreak
        case .partyRoyalty:
            return stats.level
        case .centurion:
            return stats.partiesAttended
        case .eliteHost:
            return stats.partiesHosted
        }
    }

    /// Unlock a specific achievement manually
    func unlockAchievement(_ type: AchievementType) async throws {
        let userId = try await supabase.auth.session.user.id

        let request: [String: AnyEncodable] = [
            "user_id": AnyEncodable(userId),
            "achievement_type": AnyEncodable(type.rawValue),
            "progress": AnyEncodable(type.target),
            "target": AnyEncodable(type.target),
            "unlocked_at": AnyEncodable(Date())
        ]

        try await supabase
            .from("achievements")
            .upsert(request, onConflict: "user_id,achievement_type")
            .execute()
    }

    // MARK: - Leaderboard

    /// Get top users by XP
    func getLeaderboard(limit: Int = 20) async throws -> [LeaderboardEntry] {
        struct LeaderboardRow: Codable {
            let userId: UUID
            let totalXP: Int
            let level: Int
            let user: User?

            enum CodingKeys: String, CodingKey {
                case userId = "user_id"
                case totalXP = "total_xp"
                case level
                case user = "profiles"
            }
        }

        let rows: [LeaderboardRow] = try await supabase
            .from("user_stats")
            .select("user_id, total_xp, level, profiles(*)")
            .order("total_xp", ascending: false)
            .limit(limit)
            .execute()
            .value

        return rows.enumerated().map { index, row in
            LeaderboardEntry(
                rank: index + 1,
                userId: row.userId,
                user: row.user,
                totalXP: row.totalXP,
                level: row.level
            )
        }
    }
}

// MARK: - XP Action

enum XPAction {
    case hostParty
    case attendParty
    case sharePhoto
    case postComment
    case postStatus
    case votePoll
    case createPoll
    case logDrink
    case requestSong
    case dailyStreak(days: Int)
    case achievementUnlocked(xp: Int)
}

// MARK: - XP Award Result

struct XPAwardResult: Sendable {
    let xpAwarded: Int
    let newTotalXP: Int
    let previousLevel: Int
    let newLevel: Int
    let didLevelUp: Bool
    let newAchievements: [AchievementType]
}

// MARK: - Leaderboard Entry

struct LeaderboardEntry: Identifiable, Sendable {
    let rank: Int
    let userId: UUID
    let user: User?
    let totalXP: Int
    let level: Int

    var id: UUID { userId }
}

// MARK: - Gamification Error

enum GamificationError: LocalizedError {
    case statsNotFound
    case invalidAction

    var errorDescription: String? {
        switch self {
        case .statsNotFound:
            return "User stats not found"
        case .invalidAction:
            return "Invalid gamification action"
        }
    }
}
