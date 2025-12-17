//
//  ProfileViewModel.swift
//  STUDIO
//
//  Profile state management with @Observable
//

import Foundation
import SwiftUI

// MARK: - Profile View Model

@Observable
@MainActor
final class ProfileViewModel {
    // MARK: - State

    var user: User?
    var stats: UserProfileStats = .empty
    var achievements: [UserAchievement] = []
    var hostedParties: [Party] = []
    var attendedParties: [Party] = []
    var taggedMedia: [PartyMedia] = []
    var followers: [User] = []
    var following: [User] = []

    var isLoading = false
    var isRefreshing = false
    var error: Error?
    var showError = false

    var isFollowing = false
    var isFollowLoading = false

    // MARK: - Configuration

    let userId: UUID
    let isCurrentUser: Bool

    private let profileService = ProfileService()

    // MARK: - Init

    init(userId: UUID, isCurrentUser: Bool = false) {
        self.userId = userId
        self.isCurrentUser = isCurrentUser
    }

    // MARK: - Load Profile

    func loadProfile() async {
        guard !isLoading else { return }
        isLoading = true
        error = nil

        do {
            // Load user profile
            user = try await profileService.getProfile(userId: userId)

            // Load all data in parallel
            async let statsTask = profileService.getProfileStats(userId: userId)
            async let achievementsTask = profileService.getAchievements(userId: userId)
            async let hostedTask = profileService.getHostedParties(userId: userId)
            async let attendedTask = profileService.getAttendedParties(userId: userId)
            async let mediaTask = profileService.getTaggedMedia(userId: userId)

            // Await all
            stats = try await statsTask
            achievements = try await achievementsTask
            hostedParties = try await hostedTask
            attendedParties = try await attendedTask
            taggedMedia = try await mediaTask

            // Check follow status if not current user
            if !isCurrentUser {
                isFollowing = try await profileService.isFollowing(userId: userId)
            }

        } catch {
            self.error = error
            showError = true
        }

        isLoading = false
    }

    func refresh() async {
        isRefreshing = true
        await loadProfile()
        isRefreshing = false
    }

    // MARK: - Follow Actions

    func toggleFollow() async {
        guard !isCurrentUser else { return }
        isFollowLoading = true

        do {
            if isFollowing {
                try await profileService.unfollowUser(userId: userId)
                isFollowing = false
                stats = UserProfileStats(
                    partiesHosted: stats.partiesHosted,
                    partiesAttended: stats.partiesAttended,
                    followersCount: max(0, stats.followersCount - 1),
                    followingCount: stats.followingCount,
                    mediaUploaded: stats.mediaUploaded,
                    achievementsCount: stats.achievementsCount,
                    mvpCount: stats.mvpCount,
                    bestDressedCount: stats.bestDressedCount
                )
            } else {
                try await profileService.followUser(userId: userId)
                isFollowing = true
                stats = UserProfileStats(
                    partiesHosted: stats.partiesHosted,
                    partiesAttended: stats.partiesAttended,
                    followersCount: stats.followersCount + 1,
                    followingCount: stats.followingCount,
                    mediaUploaded: stats.mediaUploaded,
                    achievementsCount: stats.achievementsCount,
                    mvpCount: stats.mvpCount,
                    bestDressedCount: stats.bestDressedCount
                )
            }
        } catch {
            self.error = error
            showError = true
        }

        isFollowLoading = false
    }

    // MARK: - Load Followers/Following

    func loadFollowers() async {
        do {
            followers = try await profileService.getFollowers(userId: userId)
        } catch {
            self.error = error
        }
    }

    func loadFollowing() async {
        do {
            following = try await profileService.getFollowing(userId: userId)
        } catch {
            self.error = error
        }
    }

    // MARK: - Update Profile

    func updateUser(_ updatedUser: User) {
        self.user = updatedUser
    }

    // MARK: - Computed Properties

    var displayName: String {
        user?.displayName ?? user?.username ?? "User"
    }

    var username: String {
        user?.username ?? ""
    }

    var bio: String? {
        user?.bio
    }

    var avatarUrl: String? {
        user?.avatarUrl
    }

    var allParties: [Party] {
        // Combine and sort by date
        let combined = hostedParties + attendedParties
        return combined.sorted { ($0.partyDate ?? $0.createdAt) > ($1.partyDate ?? $1.createdAt) }
    }

    var featuredAchievements: [UserAchievement] {
        // Return top achievements (MVP and Best Dressed first)
        achievements.sorted { a, b in
            let priority: [AchievementType] = [.partyMVP, .bestDressed, .bestMoment, .hypeMaster, .mostPhotos]
            let aIndex = priority.firstIndex(of: a.achievementType) ?? 99
            let bIndex = priority.firstIndex(of: b.achievementType) ?? 99
            return aIndex < bIndex
        }.prefix(6).map { $0 }
    }

    var achievementSummary: [(type: AchievementType, count: Int)] {
        var counts: [AchievementType: Int] = [:]
        for achievement in achievements {
            counts[achievement.achievementType, default: 0] += 1
        }
        return counts.map { ($0.key, $0.value) }
            .sorted { $0.count > $1.count }
    }
}

// MARK: - Profile Content Tab

enum ProfileContentTab: String, CaseIterable {
    case parties
    case achievements
    case tagged

    var title: String {
        switch self {
        case .parties: return "PARTIES"
        case .achievements: return "AWARDS"
        case .tagged: return "TAGGED"
        }
    }

    var icon: String {
        switch self {
        case .parties: return "square.grid.2x2"
        case .achievements: return "trophy"
        case .tagged: return "person.crop.rectangle"
        }
    }
}
