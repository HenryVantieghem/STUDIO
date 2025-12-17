//
//  SkeuomorphicEmoji.swift
//  STUDIO
//
//  3D-style skeuomorphic emoji components for premium feel
//  Basel Afterdark Design System
//

import SwiftUI

// MARK: - Skeuomorphic Emoji View

/// 3D-styled emoji with depth, shadows, and glow effects
struct SkeuomorphicEmoji: View {
    let emoji: String
    var size: EmojiSize = .medium
    var glowColor: Color = .studioChrome
    var showGlow: Bool = true
    var animatePulse: Bool = false

    @State private var isPulsing = false

    enum EmojiSize: CGFloat {
        case small = 32
        case medium = 48
        case large = 64
        case xlarge = 80
        case xxlarge = 120

        var shadowRadius: CGFloat {
            switch self {
            case .small: return 4
            case .medium: return 6
            case .large: return 8
            case .xlarge: return 12
            case .xxlarge: return 16
            }
        }

        var glowRadius: CGFloat {
            switch self {
            case .small: return 8
            case .medium: return 12
            case .large: return 16
            case .xlarge: return 24
            case .xxlarge: return 32
            }
        }
    }

    var body: some View {
        ZStack {
            // Glow layer
            if showGlow {
                Text(emoji)
                    .font(.system(size: size.rawValue))
                    .blur(radius: size.glowRadius)
                    .opacity(isPulsing ? 0.6 : 0.3)
            }

            // Main emoji with shadow
            Text(emoji)
                .font(.system(size: size.rawValue))
                .shadow(color: .black.opacity(0.5), radius: size.shadowRadius, x: 0, y: size.shadowRadius / 2)
                .shadow(color: glowColor.opacity(0.3), radius: size.glowRadius, x: 0, y: 0)
                .scaleEffect(isPulsing ? 1.1 : 1.0)
        }
        .onAppear {
            if animatePulse {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
        }
    }
}

// MARK: - Emoji Button

/// Tappable emoji with skeuomorphic styling and haptic feedback
struct SkeuomorphicEmojiButton: View {
    let emoji: String
    var size: SkeuomorphicEmoji.EmojiSize = .medium
    var isSelected: Bool = false
    var action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            HapticManager.shared.impact(.light)
            action()
        }) {
            ZStack {
                // Background
                Rectangle()
                    .fill(isSelected ? Color.studioChrome.opacity(0.2) : Color.studioSurface)
                    .overlay {
                        Rectangle()
                            .stroke(isSelected ? Color.studioChrome : Color.studioLine, lineWidth: isSelected ? 2 : 1)
                    }

                // Emoji
                SkeuomorphicEmoji(
                    emoji: emoji,
                    size: size,
                    showGlow: isSelected
                )
            }
            .frame(width: size.rawValue + 24, height: size.rawValue + 24)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Emoji Picker Grid

/// Grid of skeuomorphic emoji buttons for selection
struct SkeuomorphicEmojiPicker: View {
    let emojis: [String]
    @Binding var selectedEmoji: String?
    var columns: Int = 5
    var size: SkeuomorphicEmoji.EmojiSize = .medium

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: columns), spacing: 8) {
            ForEach(emojis, id: \.self) { emoji in
                SkeuomorphicEmojiButton(
                    emoji: emoji,
                    size: size,
                    isSelected: selectedEmoji == emoji
                ) {
                    selectedEmoji = emoji
                }
            }
        }
    }
}

// MARK: - Animated Emoji Reaction

/// Floating emoji reaction animation (for double-tap likes, etc.)
struct FloatingEmojiReaction: View {
    let emoji: String
    var onComplete: (() -> Void)?

    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 1.0
    @State private var offset: CGFloat = 0

    var body: some View {
        SkeuomorphicEmoji(
            emoji: emoji,
            size: .xlarge,
            showGlow: true
        )
        .scaleEffect(scale)
        .opacity(opacity)
        .offset(y: offset)
        .onAppear {
            // Scale up
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                scale = 1.2
            }

            // Hold and then fade out
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeOut(duration: 0.5)) {
                    scale = 1.5
                    opacity = 0
                    offset = -50
                }
            }

            // Complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                onComplete?()
            }
        }
    }
}

// MARK: - Emoji Level Indicator

/// Visual level indicator using emojis (like drunk meter)
struct EmojiLevelIndicator: View {
    let emojis: [String]  // Array of 5 emojis for levels 1-5
    let currentLevel: Int
    var showLabels: Bool = false
    var labels: [String]? = nil

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<5, id: \.self) { index in
                VStack(spacing: 4) {
                    SkeuomorphicEmoji(
                        emoji: emojis[index],
                        size: .small,
                        showGlow: index < currentLevel,
                        animatePulse: index == currentLevel - 1
                    )
                    .opacity(index < currentLevel ? 1.0 : 0.3)

                    if showLabels, let labels = labels {
                        Text(labels[index])
                            .font(StudioTypography.labelSmall)
                            .tracking(StudioTypography.trackingNormal)
                            .foregroundStyle(index < currentLevel ? Color.studioPrimary : Color.studioMuted)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
            }
        }
    }
}

// MARK: - Party Type Badge

/// Skeuomorphic badge showing party type with emoji
struct PartyTypeBadge: View {
    let partyType: PartyType

    var body: some View {
        HStack(spacing: 8) {
            SkeuomorphicEmoji(
                emoji: partyType.emoji,
                size: .small,
                showGlow: false
            )

            Text(partyType.label)
                .font(StudioTypography.labelMedium)
                .tracking(StudioTypography.trackingNormal)
                .foregroundStyle(Color.studioPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.studioSurface)
        .overlay {
            Rectangle()
                .stroke(Color.studioLine, lineWidth: 1)
        }
    }
}

// MARK: - Vibe Style Badge

struct VibeStyleBadge: View {
    let vibeStyle: VibeStyle

    var body: some View {
        HStack(spacing: 6) {
            Text(vibeStyle.emoji)
                .font(.system(size: 16))

            Text(vibeStyle.label)
                .font(StudioTypography.labelSmall)
                .tracking(StudioTypography.trackingNormal)
                .foregroundStyle(Color.studioSecondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.studioDeepBlack)
        .overlay {
            Rectangle()
                .stroke(Color.studioLine, lineWidth: 0.5)
        }
    }
}

// MARK: - Dress Code Badge

struct DressCodeBadge: View {
    let dressCode: DressCode

    var body: some View {
        HStack(spacing: 6) {
            Text(dressCode.emoji)
                .font(.system(size: 16))

            Text(dressCode.label)
                .font(StudioTypography.labelSmall)
                .tracking(StudioTypography.trackingNormal)
                .foregroundStyle(Color.studioSecondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.studioDeepBlack)
        .overlay {
            Rectangle()
                .stroke(Color.studioLine, lineWidth: 0.5)
        }
    }
}

// MARK: - Achievement Badge

struct AchievementBadge: View {
    let achievement: AchievementType
    var isUnlocked: Bool = false
    var size: CGFloat = 64

    var body: some View {
        ZStack {
            // Background
            Rectangle()
                .fill(isUnlocked ? Color.studioSurface : Color.studioDeepBlack)
                .frame(width: size, height: size)

            // Emoji
            if isUnlocked {
                SkeuomorphicEmoji(
                    emoji: achievement.emoji,
                    size: size > 48 ? .medium : .small,
                    showGlow: true,
                    animatePulse: false
                )
            } else {
                Image(systemName: "lock.fill")
                    .font(.system(size: size * 0.4, weight: .ultraLight))
                    .foregroundStyle(Color.studioMuted)
            }
        }
        .overlay {
            Rectangle()
                .stroke(isUnlocked ? Color.studioChrome : Color.studioLine, lineWidth: isUnlocked ? 2 : 1)
        }
        .opacity(isUnlocked ? 1.0 : 0.5)
    }
}

// MARK: - XP Gain Animation

/// Animated XP gain notification
struct XPGainView: View {
    let amount: Int
    var onComplete: (() -> Void)?

    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var offset: CGFloat = 20

    var body: some View {
        HStack(spacing: 4) {
            Text("+\(amount)")
                .font(StudioTypography.headlineLarge)
                .tracking(StudioTypography.trackingWide)
                .foregroundStyle(Color.studioChrome)

            Text("XP")
                .font(StudioTypography.labelMedium)
                .tracking(StudioTypography.trackingWide)
                .foregroundStyle(Color.studioSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.studioSurface)
        .overlay {
            Rectangle()
                .stroke(Color.studioChrome, lineWidth: 2)
        }
        .scaleEffect(scale)
        .opacity(opacity)
        .offset(y: offset)
        .onAppear {
            // Animate in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
                offset = 0
            }

            // Animate out
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeOut(duration: 0.3)) {
                    opacity = 0
                    offset = -30
                }
            }

            // Complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                onComplete?()
            }
        }
    }
}

// MARK: - Star Rating

/// Skeuomorphic star rating component
struct SkeuomorphicStarRating: View {
    @Binding var rating: Int
    var maxRating: Int = 5
    var size: CGFloat = 32
    var isInteractive: Bool = true

    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...maxRating, id: \.self) { star in
                Button {
                    if isInteractive {
                        HapticManager.shared.impact(.light)
                        rating = star
                    }
                } label: {
                    SkeuomorphicEmoji(
                        emoji: star <= rating ? "⭐" : "☆",
                        size: size > 40 ? .medium : .small,
                        showGlow: star <= rating
                    )
                }
                .buttonStyle(.plain)
                .disabled(!isInteractive)
            }
        }
    }
}

// MARK: - Previews

#Preview("Skeuomorphic Emoji") {
    ZStack {
        Color.studioBlack.ignoresSafeArea()

        VStack(spacing: 32) {
            SkeuomorphicEmoji(emoji: "🎉", size: .xxlarge, animatePulse: true)

            HStack(spacing: 16) {
                SkeuomorphicEmoji(emoji: "🍺", size: .large)
                SkeuomorphicEmoji(emoji: "🔥", size: .large)
                SkeuomorphicEmoji(emoji: "💀", size: .large)
            }

            EmojiLevelIndicator(
                emojis: ["😇", "🍺", "😵‍💫", "🔥", "💀"],
                currentLevel: 3
            )

            PartyTypeBadge(partyType: .nightclub)

            AchievementBadge(achievement: .partyAnimal, isUnlocked: true)
        }
    }
}
