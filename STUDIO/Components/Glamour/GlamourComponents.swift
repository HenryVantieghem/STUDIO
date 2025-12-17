//
//  GlamourComponents.swift
//  STUDIO
//
//  Studio 54 glamour and disco components
//  Disco balls, spotlights, celebration effects
//  Basel Afterdark Design System
//

import SwiftUI

// MARK: - Disco Ball Component

/// Realistic animated disco ball with reflections
struct DiscoBallComponent: View {
    let size: CGFloat
    @State private var rotation: Double = 0
    @State private var sparkles: [DiscoBallSparkle] = []

    struct DiscoBallSparkle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var opacity: Double
        var scale: CGFloat
        var angle: Double
    }

    var body: some View {
        ZStack {
            // Light beams radiating out
            ForEach(0..<12) { i in
                LightBeam(angle: Double(i) * 30 + rotation)
                    .opacity(0.3)
            }

            // Main disco ball
            ZStack {
                // Ball base with gradient
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.8),
                                Color.gray.opacity(0.6),
                                Color.gray.opacity(0.3)
                            ],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: size / 2
                        )
                    )
                    .frame(width: size, height: size)

                // Mirror tiles
                MirrorTilePattern(size: size, rotation: rotation)

                // Highlight
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.white.opacity(0.9), Color.clear],
                            center: UnitPoint(x: 0.3, y: 0.3),
                            startRadius: 0,
                            endRadius: size / 3
                        )
                    )
                    .frame(width: size, height: size)
            }
            .rotation3DEffect(.degrees(15), axis: (x: 1, y: 0, z: 0))

            // Sparkles
            ForEach(sparkles) { sparkle in
                Image(systemName: "sparkle")
                    .font(.system(size: 8))
                    .foregroundStyle(Color.white)
                    .opacity(sparkle.opacity)
                    .scaleEffect(sparkle.scale)
                    .position(x: sparkle.x, y: sparkle.y)
            }
        }
        .frame(width: size * 2, height: size * 2)
        .onAppear {
            // Start rotation
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                rotation = 360
            }

            // Generate sparkles
            generateSparkles()
        }
    }

    private func generateSparkles() {
        Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { _ in
            let angle = Double.random(in: 0...360)
            let distance = CGFloat.random(in: size * 0.6...size * 1.2)
            let x = size + cos(angle * .pi / 180) * distance
            let y = size + sin(angle * .pi / 180) * distance

            let sparkle = DiscoBallSparkle(
                x: x,
                y: y,
                opacity: 1.0,
                scale: CGFloat.random(in: 0.5...1.5),
                angle: angle
            )

            withAnimation(.easeOut(duration: 0.5)) {
                sparkles.append(sparkle)
            }

            // Remove sparkle after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    sparkles.removeAll { $0.id == sparkle.id }
                }
            }
        }
    }
}

// MARK: - Light Beam

struct LightBeam: View {
    let angle: Double

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.6),
                        Color.white.opacity(0.2),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 3, height: 150)
            .offset(y: 100)
            .rotationEffect(.degrees(angle))
            .blur(radius: 2)
    }
}

// MARK: - Mirror Tile Pattern

struct MirrorTilePattern: View {
    let size: CGFloat
    let rotation: Double

    var body: some View {
        Canvas { context, canvasSize in
            let tileSize: CGFloat = size / 8
            let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
            let radius = size / 2

            for row in 0..<Int(size / tileSize) {
                for col in 0..<Int(size / tileSize) {
                    let x = CGFloat(col) * tileSize + tileSize / 2
                    let y = CGFloat(row) * tileSize + tileSize / 2

                    // Check if tile is within circle
                    let offsetX = (canvasSize.width - size) / 2
                    let offsetY = (canvasSize.height - size) / 2
                    let tileX = x + offsetX
                    let tileY = y + offsetY
                    let dx = tileX - center.x
                    let dy = tileY - center.y

                    if sqrt(dx * dx + dy * dy) < radius - tileSize / 2 {
                        // Create tile with shimmer based on rotation
                        let shimmerFactor = sin((rotation + Double(row + col) * 30) * .pi / 180)
                        let brightness = 0.3 + 0.4 * max(0, shimmerFactor)

                        let rect = CGRect(
                            x: tileX - tileSize / 2 + 1,
                            y: tileY - tileSize / 2 + 1,
                            width: tileSize - 2,
                            height: tileSize - 2
                        )

                        context.fill(
                            Path(rect),
                            with: .color(Color.white.opacity(brightness))
                        )

                        // Tile border
                        context.stroke(
                            Path(rect),
                            with: .color(Color.gray.opacity(0.3)),
                            lineWidth: 0.5
                        )
                    }
                }
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Glamour Text Effect

/// Text with glamorous shine animation
struct GlamourText: View {
    let text: String
    let font: Font

    @State private var shimmerOffset: CGFloat = -200

    var body: some View {
        Text(text)
            .font(font)
            .foregroundStyle(Color.studioPrimary)
            .overlay {
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color.white.opacity(0.8),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 100)
                .offset(x: shimmerOffset)
                .blur(radius: 5)
            }
            .mask {
                Text(text)
                    .font(font)
            }
            .onAppear {
                withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                    shimmerOffset = 300
                }
            }
    }
}

// MARK: - Gold Confetti Cannon

/// Celebratory gold confetti burst
struct GoldConfettiCannon: View {
    @Binding var isActive: Bool
    @State private var particles: [ConfettiParticle] = []

    struct ConfettiParticle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var rotation: Double
        var scale: CGFloat
        var color: Color
        var shape: ConfettiShape
        var velocity: CGSize
    }

    enum ConfettiShape: CaseIterable {
        case rectangle, circle, star

        @ViewBuilder
        var view: some View {
            switch self {
            case .rectangle:
                Rectangle().frame(width: 8, height: 4)
            case .circle:
                Circle().frame(width: 6, height: 6)
            case .star:
                Image(systemName: "star.fill")
                    .font(.system(size: 8))
            }
        }
    }

    private let colors: [Color] = [
        Color(hex: "FFD700"),  // Gold
        Color(hex: "FFC125"),  // Golden rod
        Color(hex: "C0C0C0"),  // Silver
        Color(hex: "FFFACD"),  // Lemon chiffon
        Color(hex: "F5DEB3"),  // Wheat
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    particle.shape.view
                        .foregroundStyle(particle.color)
                        .scaleEffect(particle.scale)
                        .rotationEffect(.degrees(particle.rotation))
                        .position(x: particle.x, y: particle.y)
                }
            }
            .onChange(of: isActive) { _, active in
                if active {
                    launchConfetti(in: geometry.size)
                }
            }
        }
    }

    private func launchConfetti(in size: CGSize) {
        particles = []

        for _ in 0..<100 {
            let particle = ConfettiParticle(
                x: size.width / 2,
                y: size.height,
                rotation: Double.random(in: 0...360),
                scale: CGFloat.random(in: 0.8...1.5),
                color: colors.randomElement()!,
                shape: ConfettiShape.allCases.randomElement()!,
                velocity: CGSize(
                    width: CGFloat.random(in: -150...150),
                    height: CGFloat.random(in: -400...-200)
                )
            )
            particles.append(particle)
        }

        // Animate particles
        animateParticles(in: size)

        // Reset after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            isActive = false
            particles = []
        }
    }

    private func animateParticles(in size: CGSize) {
        let gravity: CGFloat = 400
        let friction: CGFloat = 0.98
        var time: CGFloat = 0
        let interval: CGFloat = 1/60

        Timer.scheduledTimer(withTimeInterval: Double(interval), repeats: true) { timer in
            time += interval

            if time > 3 {
                timer.invalidate()
                return
            }

            for i in particles.indices {
                particles[i].x += particles[i].velocity.width * interval
                particles[i].y += particles[i].velocity.height * interval
                particles[i].velocity.height += gravity * interval
                particles[i].velocity.width *= friction
                particles[i].rotation += Double.random(in: -10...10)
            }
        }
    }
}

// MARK: - Spotlight Sweep

/// Moving spotlight that sweeps across content
struct SpotlightSweep: View {
    @State private var position: CGFloat = -100

    var body: some View {
        GeometryReader { geometry in
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(0.15), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 150
                    )
                )
                .frame(width: 200, height: 400)
                .blur(radius: 30)
                .offset(x: position, y: -50)
                .onAppear {
                    withAnimation(
                        .easeInOut(duration: 4)
                        .repeatForever(autoreverses: true)
                    ) {
                        position = geometry.size.width + 100
                    }
                }
        }
    }
}

// MARK: - Velvet Background

/// Rich velvet-textured background
struct VelvetBackground: View {
    let color: Color

    var body: some View {
        ZStack {
            color

            // Subtle texture overlay
            Canvas { context, size in
                for _ in 0..<500 {
                    let x = CGFloat.random(in: 0...size.width)
                    let y = CGFloat.random(in: 0...size.height)
                    let opacity = Double.random(in: 0.02...0.08)

                    context.fill(
                        Path(ellipseIn: CGRect(x: x, y: y, width: 2, height: 2)),
                        with: .color(Color.white.opacity(opacity))
                    )
                }
            }

            // Vignette
            RadialGradient(
                colors: [Color.clear, Color.black.opacity(0.5)],
                center: .center,
                startRadius: 100,
                endRadius: 400
            )
        }
    }
}

// MARK: - Champagne Bubbles

/// Animated champagne bubbles rising
struct ChampagneBubbles: View {
    @State private var bubbles: [Bubble] = []

    struct Bubble: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
        var speed: CGFloat
        var wobble: CGFloat
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(bubbles) { bubble in
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: bubble.size, height: bubble.size)
                        .overlay {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [Color.white.opacity(0.6), Color.clear],
                                        center: UnitPoint(x: 0.3, y: 0.3),
                                        startRadius: 0,
                                        endRadius: bubble.size / 2
                                    )
                                )
                        }
                        .position(x: bubble.x, y: bubble.y)
                }
            }
            .onAppear {
                startBubbles(in: geometry.size)
            }
        }
    }

    private func startBubbles(in size: CGSize) {
        // Initial bubbles
        for _ in 0..<15 {
            let bubble = Bubble(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height),
                size: CGFloat.random(in: 4...12),
                speed: CGFloat.random(in: 20...60),
                wobble: CGFloat.random(in: -20...20)
            )
            bubbles.append(bubble)
        }

        // Animate
        Timer.scheduledTimer(withTimeInterval: 1/30, repeats: true) { _ in
            for i in bubbles.indices {
                bubbles[i].y -= bubbles[i].speed / 30
                bubbles[i].x += sin(bubbles[i].y / 30) * bubbles[i].wobble / 30

                // Reset when off screen
                if bubbles[i].y < -20 {
                    bubbles[i].y = size.height + 20
                    bubbles[i].x = CGFloat.random(in: 0...size.width)
                }
            }
        }
    }
}

// MARK: - Party Entrance Animation

/// Full-screen party entrance with all glamour effects
struct PartyEntranceAnimation: View {
    let partyTitle: String
    var onComplete: (() -> Void)?

    @State private var phase = 0
    @State private var showConfetti = false

    var body: some View {
        ZStack {
            // Background
            Color.studioBlack.ignoresSafeArea()

            // Disco ball
            if phase >= 1 {
                DiscoBallComponent(size: 100)
                    .offset(y: -150)
                    .transition(.scale.combined(with: .opacity))
            }

            // Spotlight sweep
            if phase >= 1 {
                SpotlightSweep()
            }

            // Title
            if phase >= 2 {
                VStack(spacing: 16) {
                    GlamourText(text: partyTitle.uppercased(), font: StudioTypography.displayLarge)

                    Text("THE PARTY AWAITS")
                        .font(StudioTypography.labelMedium)
                        .tracking(StudioTypography.trackingWide)
                        .foregroundStyle(Color.studioMuted)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }

            // Confetti
            GoldConfettiCannon(isActive: $showConfetti)

            // Champagne bubbles
            if phase >= 1 {
                ChampagneBubbles()
                    .opacity(0.5)
            }
        }
        .onAppear {
            runAnimation()
        }
    }

    private func runAnimation() {
        // Phase 1: Disco ball appears
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.3)) {
            phase = 1
        }

        // Phase 2: Title appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            HapticManager.shared.impact(.medium)
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                phase = 2
            }
        }

        // Phase 3: Confetti
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            HapticManager.shared.notification(.success)
            showConfetti = true
        }

        // Complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            onComplete?()
        }
    }
}

// MARK: - Glamour Divider

/// Elegant divider with sparkle
struct GlamourDivider: View {
    @State private var shimmerOffset: CGFloat = -100

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Line
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.clear, Color.studioLine, Color.clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)

                // Center sparkle
                Image(systemName: "sparkle")
                    .font(.system(size: 12, weight: .light))
                    .foregroundStyle(Color.studioChrome)
                    .background(Color.studioBlack.frame(width: 30))

                // Shimmer
                Rectangle()
                    .fill(Color.white.opacity(0.5))
                    .frame(width: 50, height: 1)
                    .offset(x: shimmerOffset)
                    .blur(radius: 3)
                    .onAppear {
                        withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                            shimmerOffset = geometry.size.width + 100
                        }
                    }
            }
        }
        .frame(height: 20)
    }
}

// MARK: - Preview

#Preview("Disco Ball") {
    ZStack {
        Color.studioBlack.ignoresSafeArea()
        DiscoBallComponent(size: 150)
    }
}

#Preview("Glamour Text") {
    ZStack {
        Color.studioBlack.ignoresSafeArea()
        GlamourText(text: "STUDIO 54", font: StudioTypography.displayLarge)
    }
}

#Preview("Gold Confetti") {
    @Previewable @State var showConfetti = true

    ZStack {
        Color.studioBlack.ignoresSafeArea()
        GoldConfettiCannon(isActive: $showConfetti)

        Button("LAUNCH") {
            showConfetti = true
        }
        .buttonStyle(.studioPrimary)
    }
}

#Preview("Party Entrance") {
    PartyEntranceAnimation(partyTitle: "Basel Afterdark")
}

#Preview("Champagne Bubbles") {
    ZStack {
        Color.studioBlack.ignoresSafeArea()
        ChampagneBubbles()
    }
}
