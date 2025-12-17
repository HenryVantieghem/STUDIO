//
//  AchievementsView.swift
//  STUDIO
//
//  User achievements, XP, and level display
//  Basel Afterdark Design System
//

import SwiftUI

// MARK: - Achievements View

struct AchievementsView: View {
    let userStats: UserStats?
    let achievements: [Achievement]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Level card
                if let stats = userStats {
                    levelCard(stats)
                }

                // Streak card
                if let stats = userStats, stats.currentStreak > 0 {
                    streakCard(stats)
                }

                // Achievements grid
                achievementsSection
            }
            .padding(16)
        }
        .background(Color.studioBlack)
    }

    // MARK: - Level Card

    private func levelCard(_ stats: UserStats) -> some View {
        VStack(spacing: 16) {
            // Level badge
            ZStack {
                // Background circle
                Circle()
                    .fill(Color.studioSurface)
                    .frame(width: 100, height: 100)
                    .overlay {
                        Circle()
                            .stroke(Color.studioChrome, lineWidth: 3)
                    }

                VStack(spacing: 4) {
                    Text("LVL")
                        .font(StudioTypography.labelSmall)
                        .tracking(StudioTypography.trackingWide)
                        .foregroundStyle(Color.studioMuted)

                    Text("\(stats.level)")
                        .font(StudioTypography.displayLarge)
                        .tracking(StudioTypography.trackingNormal)
                        .foregroundStyle(Color.studioPrimary)
                }
            }

            // Level title
            Text(stats.levelTitle)
                .font(StudioTypography.headlineMedium)
                .tracking(StudioTypography.trackingWide)
                .foregroundStyle(Color.studioChrome)

            // XP progress
            VStack(spacing: 8) {
                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.studioLine)
                            .frame(height: 8)

                        Rectangle()
                            .fill(Color.studioChrome)
                            .frame(width: geo.size.width * stats.levelProgress, height: 8)
                    }
                }
                .frame(height: 8)

                // XP text
                HStack {
                    Text("\(stats.totalXP) XP")
                        .font(StudioTypography.labelMedium)
                        .foregroundStyle(Color.studioPrimary)

                    Spacer()

                    Text("\(stats.xpToNextLevel) TO NEXT LEVEL")
                        .font(StudioTypography.labelSmall)
                        .foregroundStyle(Color.studioMuted)
                }
            }
            .padding(.horizontal, 24)

            // Stats row
            HStack(spacing: 24) {
                StatItem(value: stats.partiesHosted, label: "HOSTED")
                StatItem(value: stats.partiesAttended, label: "ATTENDED")
                StatItem(value: stats.photosShared, label: "PHOTOS")
            }
            .padding(.top, 8)
        }
        .padding(20)
        .background(Color.studioSurface)
        .overlay {
            Rectangle()
                .stroke(Color.studioLine, lineWidth: 1)
        }
    }

    // MARK: - Streak Card

    private func streakCard(_ stats: UserStats) -> some View {
        HStack(spacing: 16) {
            // Fire emoji
            SkeuomorphicEmoji(
                emoji: "🔥",
                size: .large,
                showGlow: true,
                animatePulse: true
            )

            VStack(alignment: .leading, spacing: 4) {
                Text("\(stats.currentStreak) DAY STREAK")
                    .font(StudioTypography.headlineMedium)
                    .tracking(StudioTypography.trackingWide)
                    .foregroundStyle(Color.studioPrimary)

                Text("LONGEST: \(stats.longestStreak) DAYS")
                    .font(StudioTypography.labelSmall)
                    .tracking(StudioTypography.trackingNormal)
                    .foregroundStyle(Color.studioMuted)
            }

            Spacer()

            // Weekly calendar
            weeklyCalendar(currentStreak: stats.currentStreak)
        }
        .padding(16)
        .background(Color.studioSurface)
        .overlay {
            Rectangle()
                .stroke(Color.studioLine, lineWidth: 1)
        }
    }

    private func weeklyCalendar(currentStreak: Int) -> some View {
        let days = ["M", "T", "W", "T", "F", "S", "S"]
        let today = Calendar.current.component(.weekday, from: Date())
        let adjustedToday = today == 1 ? 7 : today - 1 // Convert to Monday = 1

        return HStack(spacing: 4) {
            ForEach(0..<7, id: \.self) { index in
                let isActive = index < min(currentStreak, adjustedToday)
                let isToday = index == adjustedToday - 1

                VStack(spacing: 2) {
                    Text(days[index])
                        .font(StudioTypography.labelSmall)
                        .foregroundStyle(Color.studioMuted)

                    Rectangle()
                        .fill(isActive ? Color.studioChrome : Color.studioLine)
                        .frame(width: 16, height: 16)
                        .overlay {
                            if isToday {
                                Rectangle()
                                    .stroke(Color.studioPrimary, lineWidth: 1)
                            }
                        }
                }
            }
        }
    }

    // MARK: - Achievements Section

    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("ACHIEVEMENTS")
                .font(StudioTypography.labelMedium)
                .tracking(StudioTypography.trackingWide)
                .foregroundStyle(Color.studioMuted)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(AchievementType.allCases, id: \.self) { type in
                    let achievement = achievements.first { $0.achievementType == type }
                    let isUnlocked = achievement?.isUnlocked ?? false
                    let progress = achievement?.progress ?? 0

                    AchievementCard(
                        type: type,
                        isUnlocked: isUnlocked,
                        progress: progress
                    )
                }
            }
        }
    }
}

// MARK: - Stat Item

struct StatItem: View {
    let value: Int
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(StudioTypography.headlineLarge)
                .tracking(StudioTypography.trackingNormal)
                .foregroundStyle(Color.studioPrimary)

            Text(label)
                .font(StudioTypography.labelSmall)
                .tracking(StudioTypography.trackingWide)
                .foregroundStyle(Color.studioMuted)
        }
    }
}

// MARK: - Achievement Card

struct AchievementCard: View {
    let type: AchievementType
    let isUnlocked: Bool
    let progress: Int

    @State private var showDetail = false

    var body: some View {
        Button {
            HapticManager.shared.impact(.light)
            showDetail = true
        } label: {
            VStack(spacing: 8) {
                // Badge
                AchievementBadge(
                    achievement: type,
                    isUnlocked: isUnlocked,
                    size: 56
                )

                // Label
                Text(type.label)
                    .font(StudioTypography.labelSmall)
                    .tracking(StudioTypography.trackingNormal)
                    .foregroundStyle(isUnlocked ? Color.studioPrimary : Color.studioMuted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                // Progress
                if !isUnlocked {
                    ProgressView(value: Double(progress), total: Double(type.target))
                        .tint(Color.studioChrome)
                        .frame(height: 4)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(12)
            .background(Color.studioSurface)
            .overlay {
                Rectangle()
                    .stroke(isUnlocked ? Color.studioChrome : Color.studioLine, lineWidth: isUnlocked ? 2 : 1)
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showDetail) {
            AchievementDetailSheet(type: type, isUnlocked: isUnlocked, progress: progress)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color.studioSurface)
        }
    }
}

// MARK: - Achievement Detail Sheet

struct AchievementDetailSheet: View {
    let type: AchievementType
    let isUnlocked: Bool
    let progress: Int

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            // Large badge
            ZStack {
                if isUnlocked {
                    SkeuomorphicEmoji(
                        emoji: type.emoji,
                        size: .xxlarge,
                        showGlow: true,
                        animatePulse: true
                    )
                } else {
                    ZStack {
                        Circle()
                            .fill(Color.studioDeepBlack)
                            .frame(width: 120, height: 120)
                            .overlay {
                                Circle()
                                    .stroke(Color.studioLine, lineWidth: 2)
                            }

                        Image(systemName: "lock.fill")
                            .font(.system(size: 40, weight: .ultraLight))
                            .foregroundStyle(Color.studioMuted)
                    }
                }
            }

            // Title
            Text(type.label)
                .font(StudioTypography.headlineLarge)
                .tracking(StudioTypography.trackingWide)
                .foregroundStyle(isUnlocked ? Color.studioChrome : Color.studioPrimary)

            // Description
            Text(type.description.uppercased())
                .font(StudioTypography.bodyMedium)
                .tracking(StudioTypography.trackingNormal)
                .foregroundStyle(Color.studioSecondary)
                .multilineTextAlignment(.center)

            // Progress
            VStack(spacing: 8) {
                HStack {
                    Text("PROGRESS")
                        .font(StudioTypography.labelSmall)
                        .foregroundStyle(Color.studioMuted)

                    Spacer()

                    Text("\(progress)/\(type.target)")
                        .font(StudioTypography.labelMedium)
                        .foregroundStyle(isUnlocked ? Color.studioChrome : Color.studioPrimary)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.studioLine)
                            .frame(height: 8)

                        Rectangle()
                            .fill(isUnlocked ? Color.studioChrome : Color.studioPrimary)
                            .frame(width: geo.size.width * (Double(progress) / Double(type.target)), height: 8)
                    }
                }
                .frame(height: 8)
            }
            .padding(.horizontal, 32)

            // XP reward
            if isUnlocked {
                HStack(spacing: 4) {
                    Text("+\(type.xpReward)")
                        .font(StudioTypography.headlineMedium)
                        .foregroundStyle(Color.studioChrome)

                    Text("XP EARNED")
                        .font(StudioTypography.labelMedium)
                        .foregroundStyle(Color.studioSecondary)
                }
            } else {
                HStack(spacing: 4) {
                    Text("+\(type.xpReward)")
                        .font(StudioTypography.headlineMedium)
                        .foregroundStyle(Color.studioMuted)

                    Text("XP REWARD")
                        .font(StudioTypography.labelMedium)
                        .foregroundStyle(Color.studioMuted)
                }
            }

            Spacer()

            // Close button
            Button {
                dismiss()
            } label: {
                Text("CLOSE")
                    .font(StudioTypography.labelMedium)
                    .tracking(StudioTypography.trackingWide)
                    .foregroundStyle(Color.studioMuted)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.studioDeepBlack)
                    .overlay {
                        Rectangle()
                            .stroke(Color.studioLine, lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .padding(.top, 32)
    }
}

// MARK: - Achievement Unlocked Overlay

/// Full-screen achievement unlock celebration
struct AchievementUnlockedOverlay: View {
    let achievementType: AchievementType
    var onDismiss: (() -> Void)?

    @State private var showContent = false
    @State private var showStars = false

    var body: some View {
        ZStack {
            // Dark overlay
            Color.studioBlack.opacity(0.9)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Stars animation
                if showStars {
                    HStack(spacing: 8) {
                        ForEach(0..<5, id: \.self) { index in
                            Text("⭐")
                                .font(.system(size: 24))
                                .offset(y: showStars ? 0 : -20)
                                .opacity(showStars ? 1 : 0)
                                .animation(
                                    .spring(response: 0.4, dampingFraction: 0.6)
                                    .delay(Double(index) * 0.1),
                                    value: showStars
                                )
                        }
                    }
                }

                Text("ACHIEVEMENT UNLOCKED")
                    .font(StudioTypography.labelMedium)
                    .tracking(StudioTypography.trackingExtraWide)
                    .foregroundStyle(Color.studioChrome)
                    .opacity(showContent ? 1 : 0)

                // Badge
                SkeuomorphicEmoji(
                    emoji: achievementType.emoji,
                    size: .xxlarge,
                    showGlow: true,
                    animatePulse: true
                )
                .scaleEffect(showContent ? 1 : 0.5)
                .opacity(showContent ? 1 : 0)

                // Title
                Text(achievementType.label)
                    .font(StudioTypography.displayMedium)
                    .tracking(StudioTypography.trackingWide)
                    .foregroundStyle(Color.studioPrimary)
                    .opacity(showContent ? 1 : 0)

                // Description
                Text(achievementType.description.uppercased())
                    .font(StudioTypography.bodyMedium)
                    .foregroundStyle(Color.studioSecondary)
                    .opacity(showContent ? 1 : 0)

                // XP reward
                HStack(spacing: 8) {
                    Text("+\(achievementType.xpReward)")
                        .font(StudioTypography.headlineLarge)
                        .foregroundStyle(Color.studioChrome)

                    Text("XP")
                        .font(StudioTypography.labelMedium)
                        .foregroundStyle(Color.studioSecondary)
                }
                .opacity(showContent ? 1 : 0)

                // Dismiss button
                Button {
                    HapticManager.shared.impact(.medium)
                    onDismiss?()
                } label: {
                    Text("AWESOME")
                        .font(StudioTypography.labelLarge)
                        .tracking(StudioTypography.trackingWide)
                        .foregroundStyle(Color.studioBlack)
                        .frame(width: 200, height: 56)
                        .background(Color.studioChrome)
                }
                .buttonStyle(.plain)
                .opacity(showContent ? 1 : 0)
                .padding(.top, 16)
            }
        }
        .onAppear {
            // Haptic cascade
            HapticManager.shared.notification(.success)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                HapticManager.shared.impact(.medium)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                HapticManager.shared.impact(.light)
            }

            // Animate in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showContent = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showStars = true
            }
        }
    }
}

// MARK: - Preview

#Preview("Achievements View") {
    AchievementsView(
        userStats: UserStats(
            id: UUID(),
            userId: UUID(),
            totalXP: 1250,
            level: 12,
            partiesHosted: 5,
            partiesAttended: 24,
            photosShared: 156,
            pollsCreated: 8,
            pollsVoted: 45,
            drinksLogged: 78,
            currentStreak: 5,
            longestStreak: 12,
            lastActiveDate: Date()
        ),
        achievements: [
            Achievement(id: UUID(), achievementType: .firstParty, unlockedAt: Date(), progress: 1, target: 1),
            Achievement(id: UUID(), achievementType: .partyAnimal, unlockedAt: Date(), progress: 10, target: 10),
            Achievement(id: UUID(), achievementType: .photoProof, unlockedAt: nil, progress: 45, target: 100)
        ]
    )
}
