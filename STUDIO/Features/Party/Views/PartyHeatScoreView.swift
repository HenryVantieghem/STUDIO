//
//  PartyHeatScoreView.swift
//  STUDIO
//
//  Party heat/engagement score system
//  Basel Afterdark Design System
//

import SwiftUI

// MARK: - Party Heat Score Model

struct PartyHeatScore: Codable, Sendable {
    let partyId: UUID
    let totalScore: Int
    let guestScore: Int
    let mediaScore: Int
    let commentScore: Int
    let statusScore: Int
    let reactionScore: Int
    let vibeScore: Int
    let timestamp: Date

    // Heat level (1-5 fire emojis)
    var heatLevel: Int {
        switch totalScore {
        case 0..<100: return 1
        case 100..<300: return 2
        case 300..<600: return 3
        case 600..<1000: return 4
        default: return 5
        }
    }

    var heatLabel: String {
        switch heatLevel {
        case 1: return "WARMING UP"
        case 2: return "GETTING HOT"
        case 3: return "ON FIRE"
        case 4: return "BLAZING"
        case 5: return "LEGENDARY"
        default: return "COLD"
        }
    }

    var heatEmoji: String {
        switch heatLevel {
        case 1: return "🌡️"
        case 2: return "🔥"
        case 3: return "🔥🔥"
        case 4: return "🔥🔥🔥"
        case 5: return "💥"
        default: return "❄️"
        }
    }
}

// MARK: - Heat Score Calculator

@Observable
class HeatScoreCalculator {
    var currentScore: PartyHeatScore?

    // Score weights
    private let guestWeight = 10      // Per guest
    private let mediaWeight = 25      // Per photo/video
    private let commentWeight = 5     // Per comment
    private let statusWeight = 8      // Per status update
    private let reactionWeight = 2    // Per reaction/like
    private let vibeWeight = 15       // Per vibe check (level multiplier)

    func calculateScore(
        partyId: UUID,
        guestCount: Int,
        mediaCount: Int,
        commentCount: Int,
        statusCount: Int,
        reactionCount: Int,
        averageVibeLevel: Double
    ) -> PartyHeatScore {
        let guestScore = guestCount * guestWeight
        let mediaScore = mediaCount * mediaWeight
        let commentScore = commentCount * commentWeight
        let statusScore = statusCount * statusWeight
        let reactionScore = reactionCount * reactionWeight
        let vibeScore = Int(averageVibeLevel * Double(vibeWeight) * Double(statusCount + 1))

        let totalScore = guestScore + mediaScore + commentScore + statusScore + reactionScore + vibeScore

        let score = PartyHeatScore(
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

        currentScore = score
        return score
    }
}

// MARK: - Party Heat Score View

struct PartyHeatScoreView: View {
    let partyId: UUID
    @State private var heatScore: PartyHeatScore?
    @State private var isLoading = true
    @State private var showBreakdown = false
    @State private var animateFlame = false

    var body: some View {
        VStack(spacing: 0) {
            // Main heat display
            heatDisplay

            // Breakdown toggle
            if heatScore != nil {
                breakdownToggle
            }

            // Score breakdown
            if showBreakdown, let score = heatScore {
                scoreBreakdown(score)
            }
        }
        .background(Color.studioSurface)
        .overlay {
            Rectangle()
                .stroke(borderColor, lineWidth: 2)
        }
        .task {
            await loadHeatScore()
        }
    }

    // MARK: - Heat Display

    private var heatDisplay: some View {
        HStack(spacing: 16) {
            // Animated flame
            ZStack {
                // Background glow
                if let score = heatScore, score.heatLevel >= 3 {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.orange.opacity(animateFlame ? 0.4 : 0.2),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 20,
                                endRadius: 60
                            )
                        )
                        .frame(width: 100, height: 100)
                        .animation(
                            .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                            value: animateFlame
                        )
                }

                // Fire emoji
                Text(heatScore?.heatEmoji ?? "🔥")
                    .font(.system(size: 48))
                    .scaleEffect(animateFlame ? 1.1 : 1.0)
                    .animation(
                        .easeInOut(duration: 0.5).repeatForever(autoreverses: true),
                        value: animateFlame
                    )
            }
            .onAppear {
                animateFlame = true
            }

            VStack(alignment: .leading, spacing: 8) {
                // Heat label
                Text(heatScore?.heatLabel ?? "CALCULATING...")
                    .font(StudioTypography.headlineMedium)
                    .tracking(StudioTypography.trackingWide)
                    .foregroundStyle(Color.studioChrome)

                // Total score
                if let score = heatScore {
                    HStack(spacing: 4) {
                        Text("\(score.totalScore)")
                            .font(StudioTypography.displayMedium)
                            .tracking(StudioTypography.trackingNormal)
                            .foregroundStyle(Color.studioPrimary)

                        Text("HEAT POINTS")
                            .font(StudioTypography.labelSmall)
                            .tracking(StudioTypography.trackingNormal)
                            .foregroundStyle(Color.studioMuted)
                    }

                    // Heat level bar
                    heatLevelBar(level: score.heatLevel)
                }
            }

            Spacer()
        }
        .padding(20)
    }

    private func heatLevelBar(level: Int) -> some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { index in
                Rectangle()
                    .fill(index <= level ? heatColor(for: index) : Color.studioLine)
                    .frame(width: 24, height: 8)
            }
        }
    }

    private func heatColor(for level: Int) -> Color {
        switch level {
        case 1: return Color.yellow.opacity(0.6)
        case 2: return Color.orange.opacity(0.7)
        case 3: return Color.orange
        case 4: return Color.red.opacity(0.8)
        case 5: return Color.red
        default: return Color.studioLine
        }
    }

    private var borderColor: Color {
        guard let score = heatScore else { return Color.studioLine }
        switch score.heatLevel {
        case 4, 5: return Color.orange.opacity(0.6)
        case 3: return Color.studioChrome
        default: return Color.studioLine
        }
    }

    // MARK: - Breakdown Toggle

    private var breakdownToggle: some View {
        Button {
            HapticManager.shared.impact(.light)
            withAnimation(.easeInOut(duration: 0.2)) {
                showBreakdown.toggle()
            }
        } label: {
            HStack {
                Text("SCORE BREAKDOWN")
                    .font(StudioTypography.labelSmall)
                    .tracking(StudioTypography.trackingWide)
                    .foregroundStyle(Color.studioMuted)

                Spacer()

                Image(systemName: showBreakdown ? "chevron.up" : "chevron.down")
                    .font(.system(size: 12, weight: .light))
                    .foregroundStyle(Color.studioMuted)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.studioDeepBlack)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Score Breakdown

    private func scoreBreakdown(_ score: PartyHeatScore) -> some View {
        VStack(spacing: 0) {
            scoreRow(icon: "person.2", label: "GUESTS", value: score.guestScore, emoji: "👥")
            scoreRow(icon: "photo", label: "MEDIA", value: score.mediaScore, emoji: "📸")
            scoreRow(icon: "bubble.left", label: "COMMENTS", value: score.commentScore, emoji: "💬")
            scoreRow(icon: "face.smiling", label: "STATUSES", value: score.statusScore, emoji: "😎")
            scoreRow(icon: "heart", label: "REACTIONS", value: score.reactionScore, emoji: "❤️")
            scoreRow(icon: "sparkles", label: "VIBES", value: score.vibeScore, emoji: "✨")
        }
        .padding(.bottom, 12)
    }

    private func scoreRow(icon: String, label: String, value: Int, emoji: String) -> some View {
        HStack {
            Text(emoji)
                .font(.system(size: 16))

            Text(label)
                .font(StudioTypography.labelSmall)
                .tracking(StudioTypography.trackingNormal)
                .foregroundStyle(Color.studioSecondary)

            Spacer()

            Text("+\(value)")
                .font(StudioTypography.labelMedium)
                .foregroundStyle(value > 0 ? Color.studioChrome : Color.studioMuted)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }

    // MARK: - Data Loading

    private func loadHeatScore() async {
        isLoading = true

        // TODO: Load actual data from Supabase
        // Simulating calculation with placeholder data
        let calculator = HeatScoreCalculator()
        heatScore = calculator.calculateScore(
            partyId: partyId,
            guestCount: 24,
            mediaCount: 45,
            commentCount: 89,
            statusCount: 32,
            reactionCount: 156,
            averageVibeLevel: 4.2
        )

        isLoading = false
    }
}

// MARK: - Compact Heat Badge

/// Small heat score badge for party cards
struct HeatBadge: View {
    let score: Int

    private var heatLevel: Int {
        switch score {
        case 0..<100: return 1
        case 100..<300: return 2
        case 300..<600: return 3
        case 600..<1000: return 4
        default: return 5
        }
    }

    private var emoji: String {
        switch heatLevel {
        case 1: return "🌡️"
        case 2: return "🔥"
        case 3: return "🔥"
        case 4: return "🔥"
        case 5: return "💥"
        default: return "❄️"
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Text(emoji)
                .font(.system(size: 12))

            Text("\(score)")
                .font(StudioTypography.labelSmall)
                .foregroundStyle(Color.studioPrimary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(badgeColor.opacity(0.2))
        .overlay {
            Rectangle()
                .stroke(badgeColor, lineWidth: 1)
        }
    }

    private var badgeColor: Color {
        switch heatLevel {
        case 4, 5: return Color.orange
        case 3: return Color.studioChrome
        default: return Color.studioLine
        }
    }
}

// MARK: - Heat Score Ring

/// Circular heat score indicator
struct HeatScoreRing: View {
    let score: Int
    let maxScore: Int

    @State private var animatedProgress: CGFloat = 0

    private var progress: CGFloat {
        min(CGFloat(score) / CGFloat(maxScore), 1.0)
    }

    private var heatLevel: Int {
        switch score {
        case 0..<100: return 1
        case 100..<300: return 2
        case 300..<600: return 3
        case 600..<1000: return 4
        default: return 5
        }
    }

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.studioLine, lineWidth: 8)

            // Progress ring
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AngularGradient(
                        colors: gradientColors,
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .square)
                )
                .rotationEffect(.degrees(-90))

            // Center content
            VStack(spacing: 4) {
                Text(heatEmoji)
                    .font(.system(size: 24))

                Text("\(score)")
                    .font(StudioTypography.headlineLarge)
                    .tracking(StudioTypography.trackingNormal)
                    .foregroundStyle(Color.studioPrimary)

                Text("HEAT")
                    .font(StudioTypography.labelSmall)
                    .tracking(StudioTypography.trackingWide)
                    .foregroundStyle(Color.studioMuted)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animatedProgress = progress
            }
        }
    }

    private var gradientColors: [Color] {
        [.yellow, .orange, .red, .orange, .yellow]
    }

    private var heatEmoji: String {
        switch heatLevel {
        case 1: return "🌡️"
        case 2: return "🔥"
        case 3: return "🔥"
        case 4: return "🔥"
        case 5: return "💥"
        default: return "❄️"
        }
    }
}

// MARK: - Live Heat Pulse

/// Animated pulse that shows real-time activity
struct LiveHeatPulse: View {
    let isActive: Bool

    @State private var pulse = false

    var body: some View {
        ZStack {
            // Outer pulse
            Circle()
                .fill(Color.red.opacity(0.3))
                .frame(width: pulse ? 20 : 12, height: pulse ? 20 : 12)
                .opacity(pulse ? 0 : 1)

            // Inner dot
            Circle()
                .fill(isActive ? Color.red : Color.studioLine)
                .frame(width: 8, height: 8)

            // Live text
            Text("LIVE")
                .font(StudioTypography.labelSmall)
                .tracking(StudioTypography.trackingWide)
                .foregroundStyle(isActive ? Color.red : Color.studioMuted)
                .offset(x: 24)
        }
        .onAppear {
            if isActive {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: false)) {
                    pulse = true
                }
            }
        }
    }
}

// MARK: - Heat Leaderboard

/// Shows parties ranked by heat score
struct HeatLeaderboardView: View {
    let parties: [(party: Party, score: Int)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("🔥")
                    .font(.system(size: 20))

                Text("HOTTEST PARTIES")
                    .font(StudioTypography.labelMedium)
                    .tracking(StudioTypography.trackingWide)
                    .foregroundStyle(Color.studioMuted)

                Spacer()

                LiveHeatPulse(isActive: true)
            }
            .padding(.horizontal, 16)

            // Party rows
            ForEach(Array(parties.enumerated()), id: \.element.party.id) { index, item in
                HeatLeaderboardRow(
                    rank: index + 1,
                    party: item.party,
                    score: item.score
                )
            }
        }
        .padding(.vertical, 16)
        .background(Color.studioSurface)
        .overlay {
            Rectangle()
                .stroke(Color.studioLine, lineWidth: 1)
        }
    }
}

struct HeatLeaderboardRow: View {
    let rank: Int
    let party: Party
    let score: Int

    var body: some View {
        HStack(spacing: 12) {
            // Rank
            Text("\(rank)")
                .font(StudioTypography.headlineMedium)
                .tracking(StudioTypography.trackingNormal)
                .foregroundStyle(rankColor)
                .frame(width: 32)

            // Party info
            VStack(alignment: .leading, spacing: 2) {
                Text(party.title.uppercased())
                    .font(StudioTypography.labelMedium)
                    .tracking(StudioTypography.trackingNormal)
                    .foregroundStyle(Color.studioPrimary)
                    .lineLimit(1)

                if let type = party.partyType {
                    Text(type.emoji + " " + type.label)
                        .font(StudioTypography.labelSmall)
                        .foregroundStyle(Color.studioMuted)
                }
            }

            Spacer()

            // Heat badge
            HeatBadge(score: score)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var rankColor: Color {
        switch rank {
        case 1: return Color.yellow
        case 2: return Color.gray
        case 3: return Color.orange
        default: return Color.studioMuted
        }
    }
}

// MARK: - Preview

#Preview("Party Heat Score") {
    PartyHeatScoreView(partyId: UUID())
        .padding()
        .background(Color.studioBlack)
}

#Preview("Heat Badge") {
    VStack(spacing: 16) {
        HeatBadge(score: 50)
        HeatBadge(score: 250)
        HeatBadge(score: 500)
        HeatBadge(score: 800)
        HeatBadge(score: 1500)
    }
    .padding()
    .background(Color.studioBlack)
}

#Preview("Heat Score Ring") {
    HeatScoreRing(score: 750, maxScore: 1000)
        .frame(width: 150, height: 150)
        .padding()
        .background(Color.studioBlack)
}
