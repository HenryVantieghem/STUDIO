//
//  Studio54Effects.swift
//  STUDIO
//
//  Studio 54 inspired visual effects
//  Disco balls, velvet rope, theatrical lighting, VIP glamour
//

import SwiftUI

// MARK: - Disco Ball Effect

/// Animated disco ball with light reflections
struct DiscoBallView: View {
    let size: CGFloat
    @State private var rotation: Double = 0
    @State private var sparkles: [Sparkle] = []

    var body: some View {
        ZStack {
            // Light rays
            ForEach(0..<12, id: \.self) { i in
                LightRay(index: i, rotation: rotation)
            }

            // Main disco ball
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white,
                            Color(white: 0.9),
                            Color(white: 0.7),
                            Color(white: 0.5)
                        ],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: size
                    )
                )
                .frame(width: size, height: size)
                .overlay {
                    // Mirror tiles
                    MirrorTilesOverlay(size: size, rotation: rotation)
                }
                .shadow(color: .white.opacity(0.5), radius: 20)
                .shadow(color: .white.opacity(0.3), radius: 40)

            // Sparkles
            ForEach(sparkles) { sparkle in
                Circle()
                    .fill(Color.white)
                    .frame(width: sparkle.size, height: sparkle.size)
                    .offset(x: sparkle.x, y: sparkle.y)
                    .opacity(sparkle.opacity)
            }
        }
        .onAppear {
            // Rotate disco ball
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                rotation = 360
            }

            // Generate sparkles
            generateSparkles()
        }
    }

    private func generateSparkles() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            let angle = Double.random(in: 0...360) * .pi / 180
            let distance = CGFloat.random(in: size/2...size * 1.5)

            let sparkle = Sparkle(
                id: UUID(),
                x: cos(angle) * distance,
                y: sin(angle) * distance,
                size: CGFloat.random(in: 2...6),
                opacity: Double.random(in: 0.3...1)
            )

            sparkles.append(sparkle)

            // Remove old sparkles
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                sparkles.removeAll { $0.id == sparkle.id }
            }
        }
    }
}

struct Sparkle: Identifiable {
    let id: UUID
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let opacity: Double
}

struct LightRay: View {
    let index: Int
    let rotation: Double

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.3),
                        Color.white.opacity(0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 3, height: 200)
            .rotationEffect(.degrees(Double(index) * 30 + rotation * 0.5))
            .opacity(0.3)
    }
}

struct MirrorTilesOverlay: View {
    let size: CGFloat
    let rotation: Double

    var body: some View {
        Canvas { context, canvasSize in
            let tileSize: CGFloat = 8
            let rows = Int(canvasSize.height / tileSize)
            let cols = Int(canvasSize.width / tileSize)

            for row in 0..<rows {
                for col in 0..<cols {
                    let x = CGFloat(col) * tileSize
                    let y = CGFloat(row) * tileSize

                    // Vary brightness based on position and rotation
                    let brightness = sin(Double(row + col) * 0.5 + rotation * 0.05) * 0.3 + 0.7

                    let rect = CGRect(x: x, y: y, width: tileSize - 1, height: tileSize - 1)
                    context.fill(
                        Path(rect),
                        with: .color(Color(white: brightness, opacity: 0.6))
                    )
                }
            }
        }
        .clipShape(Circle())
    }
}

// MARK: - Velvet Rope Animation

/// Animated velvet rope barrier
struct VelvetRopeView: View {
    @Binding var isOpen: Bool
    @State private var ropeOffset: CGFloat = 0

    var body: some View {
        HStack(spacing: 0) {
            // Left post
            VelvetPost()

            // Rope
            ZStack {
                // Rope shadow
                RopeShape(offset: ropeOffset)
                    .stroke(Color.black.opacity(0.3), lineWidth: 12)
                    .offset(y: 3)

                // Main rope
                RopeShape(offset: ropeOffset)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(red: 0.5, green: 0, blue: 0.1),
                                Color(red: 0.7, green: 0, blue: 0.15),
                                Color(red: 0.5, green: 0, blue: 0.1)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
            }
            .frame(width: 200, height: 60)

            // Right post
            VelvetPost()
        }
        .onChange(of: isOpen) { _, open in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                ropeOffset = open ? 80 : 0
            }
        }
    }
}

struct VelvetPost: View {
    var body: some View {
        VStack(spacing: 0) {
            // Gold top
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 1, green: 0.85, blue: 0.4),
                            Color(red: 0.85, green: 0.65, blue: 0.2)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 24, height: 24)

            // Post
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.85, green: 0.65, blue: 0.2),
                            Color(red: 0.7, green: 0.5, blue: 0.1),
                            Color(red: 0.85, green: 0.65, blue: 0.2)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 8, height: 100)

            // Base
            Ellipse()
                .fill(Color(red: 0.2, green: 0.2, blue: 0.2))
                .frame(width: 30, height: 10)
        }
    }
}

struct RopeShape: Shape {
    var offset: CGFloat

    var animatableData: CGFloat {
        get { offset }
        set { offset = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let startY = rect.midY
        let sag: CGFloat = 20 - (offset * 0.2) // Less sag when rope opens

        path.move(to: CGPoint(x: 0, y: startY))

        // Catenary curve
        path.addQuadCurve(
            to: CGPoint(x: rect.width, y: startY + offset),
            control: CGPoint(x: rect.midX, y: startY + sag)
        )

        return path
    }
}

// MARK: - Spotlight Effect

/// Moving spotlight effect
struct SpotlightView: View {
    @State private var spotlightPosition = CGPoint(x: 100, y: 100)
    @State private var spotlightColor = Color.white

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Dark overlay
                Color.black.opacity(0.7)

                // Spotlight cone
                RadialGradient(
                    colors: [
                        spotlightColor.opacity(0.8),
                        spotlightColor.opacity(0.3),
                        Color.clear
                    ],
                    center: UnitPoint(
                        x: spotlightPosition.x / geo.size.width,
                        y: spotlightPosition.y / geo.size.height
                    ),
                    startRadius: 20,
                    endRadius: 150
                )
            }
            .onAppear {
                animateSpotlight(in: geo.size)
            }
        }
        .allowsHitTesting(false)
    }

    private func animateSpotlight(in size: CGSize) {
        Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 2.5)) {
                spotlightPosition = CGPoint(
                    x: CGFloat.random(in: 50...size.width - 50),
                    y: CGFloat.random(in: 50...size.height - 50)
                )

                // Occasionally change color
                if Bool.random() {
                    spotlightColor = [Color.white, Color.pink, Color.purple, Color.blue].randomElement()!
                }
            }
        }
    }
}

// MARK: - Shimmer Effect

/// Luxury shimmer effect for text and elements
struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { geo in
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.white.opacity(0.5),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 2)
                    .offset(x: -geo.size.width + (phase * geo.size.width * 2))
                }
                .mask(content)
            }
            .onAppear {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerEffect())
    }
}

// MARK: - Gold Glitter Effect

/// Animated gold glitter particles
struct GoldGlitterView: View {
    @State private var particles: [GlitterParticle] = []
    let density: Int

    init(density: Int = 50) {
        self.density = density
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .opacity(particle.opacity)
                }
            }
            .onAppear {
                generateParticles(in: geo.size)
            }
        }
    }

    private func generateParticles(in size: CGSize) {
        for _ in 0..<density {
            let particle = GlitterParticle(
                id: UUID(),
                position: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: CGFloat.random(in: 0...size.height)
                ),
                size: CGFloat.random(in: 1...4),
                color: [
                    Color(red: 1, green: 0.85, blue: 0.4),
                    Color(red: 1, green: 0.9, blue: 0.6),
                    Color.white
                ].randomElement()!,
                opacity: Double.random(in: 0.3...1)
            )
            particles.append(particle)
        }

        // Animate particles
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            for i in particles.indices {
                withAnimation(.linear(duration: 0.05)) {
                    particles[i].opacity = Double.random(in: 0.2...1)
                }
            }
        }
    }
}

struct GlitterParticle: Identifiable {
    let id: UUID
    var position: CGPoint
    var size: CGFloat
    var color: Color
    var opacity: Double
}

// MARK: - VIP Glow Effect

/// Exclusive VIP glow around elements
struct VIPGlowModifier: ViewModifier {
    let isVIP: Bool
    @State private var glowIntensity: Double = 0.5

    func body(content: Content) -> some View {
        content
            .overlay {
                if isVIP {
                    RoundedRectangle(cornerRadius: 0)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(red: 1, green: 0.85, blue: 0.4).opacity(glowIntensity),
                                    Color(red: 1, green: 0.7, blue: 0.2).opacity(glowIntensity * 0.5)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .shadow(color: Color(red: 1, green: 0.85, blue: 0.4).opacity(glowIntensity * 0.5), radius: 10)
                }
            }
            .onAppear {
                if isVIP {
                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                        glowIntensity = 1
                    }
                }
            }
    }
}

extension View {
    func vipGlow(_ isVIP: Bool = true) -> some View {
        modifier(VIPGlowModifier(isVIP: isVIP))
    }
}

// MARK: - Confetti Cannon

/// Studio 54 confetti explosion
struct ConfettiView: View {
    @Binding var isActive: Bool
    @State private var confettiPieces: [ConfettiPiece] = []

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(confettiPieces) { piece in
                    ConfettiPieceView(piece: piece)
                }
            }
            .onChange(of: isActive) { _, active in
                if active {
                    triggerConfetti(in: geo.size)
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func triggerConfetti(in size: CGSize) {
        confettiPieces.removeAll()

        for _ in 0..<100 {
            let piece = ConfettiPiece(
                id: UUID(),
                x: size.width / 2,
                y: size.height,
                velocityX: CGFloat.random(in: -200...200),
                velocityY: CGFloat.random(in: -600...-300),
                rotation: Double.random(in: 0...360),
                color: [
                    Color(red: 1, green: 0.85, blue: 0.4), // Gold
                    Color.white,
                    Color(red: 0.8, green: 0.8, blue: 0.8), // Silver
                    Color(red: 1, green: 0.7, blue: 0.8) // Pink
                ].randomElement()!,
                shape: ConfettiShape.allCases.randomElement()!
            )
            confettiPieces.append(piece)
        }

        // Animate pieces
        withAnimation(.easeOut(duration: 3)) {
            for i in confettiPieces.indices {
                confettiPieces[i].y = size.height + 100
                confettiPieces[i].x += confettiPieces[i].velocityX
                confettiPieces[i].rotation += 720
            }
        }

        // Clear after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            isActive = false
            confettiPieces.removeAll()
        }
    }
}

struct ConfettiPiece: Identifiable {
    let id: UUID
    var x: CGFloat
    var y: CGFloat
    var velocityX: CGFloat
    var velocityY: CGFloat
    var rotation: Double
    var color: Color
    var shape: ConfettiShape
}

enum ConfettiShape: CaseIterable {
    case rectangle, circle, star
}

struct ConfettiPieceView: View {
    let piece: ConfettiPiece

    var body: some View {
        Group {
            switch piece.shape {
            case .rectangle:
                Rectangle()
                    .fill(piece.color)
                    .frame(width: 8, height: 12)
            case .circle:
                Circle()
                    .fill(piece.color)
                    .frame(width: 8, height: 8)
            case .star:
                Image(systemName: "star.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(piece.color)
            }
        }
        .position(x: piece.x, y: piece.y)
        .rotationEffect(.degrees(piece.rotation))
    }
}

// MARK: - Neon Text Effect

/// Glowing neon text for headlines
struct NeonTextModifier: ViewModifier {
    let color: Color
    @State private var glow: Double = 0.5

    func body(content: Content) -> some View {
        content
            .foregroundStyle(color)
            .shadow(color: color.opacity(glow), radius: 5)
            .shadow(color: color.opacity(glow * 0.7), radius: 10)
            .shadow(color: color.opacity(glow * 0.5), radius: 20)
            .onAppear {
                withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                    glow = 1
                }
            }
    }
}

extension View {
    func neonGlow(_ color: Color = .white) -> some View {
        modifier(NeonTextModifier(color: color))
    }
}

// MARK: - Preview

#Preview("Disco Ball") {
    ZStack {
        Color.black.ignoresSafeArea()
        DiscoBallView(size: 150)
    }
}

#Preview("Velvet Rope") {
    struct Preview: View {
        @State var isOpen = false

        var body: some View {
            ZStack {
                Color.studioBlack.ignoresSafeArea()

                VStack {
                    VelvetRopeView(isOpen: $isOpen)

                    Button("Toggle Rope") {
                        isOpen.toggle()
                    }
                    .padding(.top, 50)
                }
            }
        }
    }
    return Preview()
}

#Preview("Gold Glitter") {
    ZStack {
        Color.black.ignoresSafeArea()
        GoldGlitterView(density: 100)
    }
}
