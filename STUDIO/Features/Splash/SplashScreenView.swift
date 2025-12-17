//
//  SplashScreenView.swift
//  STUDIO
//
//  Stunning app launch experience
//  Pixel Afterdark Design System
//

import SwiftUI

// MARK: - Splash Screen View

/// Beautiful app launch animation with disco ball and logo reveal
struct SplashScreenView: View {
    @Binding var isComplete: Bool

    @State private var showLogo = false
    @State private var showTagline = false
    @State private var discoBallScale: CGFloat = 0.5
    @State private var discoBallOpacity: Double = 0
    @State private var logoGlow = false
    @State private var sparkles: [SplashSparkle] = []

    struct SplashSparkle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var opacity: Double
        var scale: CGFloat
    }

    var body: some View {
        ZStack {
            // Pure black background
            Color.studioBlack.ignoresSafeArea()

            // Sparkles
            ForEach(sparkles) { sparkle in
                Image(systemName: "sparkle")
                    .font(.system(size: 8))
                    .foregroundStyle(Color.studioChrome)
                    .opacity(sparkle.opacity)
                    .scaleEffect(sparkle.scale)
                    .position(x: sparkle.x, y: sparkle.y)
            }

            // Ambient light from top
            VStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.studioChrome.opacity(0.15), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 200
                        )
                    )
                    .frame(width: 400, height: 400)
                    .blur(radius: 60)
                    .offset(y: -100)

                Spacer()
            }

            // Content
            VStack(spacing: 40) {
                Spacer()

                // Mini disco ball
                ZStack {
                    // Glow
                    Circle()
                        .fill(Color.studioChrome.opacity(0.1))
                        .frame(width: 120, height: 120)
                        .blur(radius: 30)
                        .scaleEffect(logoGlow ? 1.2 : 1.0)

                    // Ball
                    MiniDiscoBall()
                        .frame(width: 60, height: 60)
                        .scaleEffect(discoBallScale)
                        .opacity(discoBallOpacity)
                }

                // Logo
                VStack(spacing: 16) {
                    Text("STUDIO")
                        .font(StudioTypography.displayLarge)
                        .tracking(StudioTypography.trackingWide * 2)
                        .foregroundStyle(Color.studioPrimary)
                        .opacity(showLogo ? 1 : 0)
                        .scaleEffect(showLogo ? 1 : 0.9)

                    Text("THE PARTY STARTS HERE")
                        .font(StudioTypography.labelSmall)
                        .tracking(StudioTypography.trackingWide)
                        .foregroundStyle(Color.studioMuted)
                        .opacity(showTagline ? 1 : 0)
                        .offset(y: showTagline ? 0 : 10)
                }

                Spacer()
                Spacer()
            }
        }
        .onAppear {
            runAnimation()
        }
    }

    private func runAnimation() {
        // Start generating sparkles
        generateSparkles()

        // Disco ball appears
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
            discoBallScale = 1.0
            discoBallOpacity = 1.0
        }

        // Logo appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showLogo = true
            }
        }

        // Tagline appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showTagline = true
            }
        }

        // Logo glow animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                logoGlow = true
            }
        }

        // Complete after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeOut(duration: 0.3)) {
                isComplete = true
            }
        }
    }

    private func generateSparkles() {
        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if isComplete {
                timer.invalidate()
                return
            }

            let screenWidth = UIScreen.main.bounds.width
            let screenHeight = UIScreen.main.bounds.height

            let sparkle = SplashSparkle(
                x: CGFloat.random(in: 0...screenWidth),
                y: CGFloat.random(in: 0...screenHeight * 0.6),
                opacity: Double.random(in: 0.3...0.8),
                scale: CGFloat.random(in: 0.5...1.5)
            )

            sparkles.append(sparkle)

            // Fade out sparkle
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                sparkles.removeAll { $0.id == sparkle.id }
            }

            // Limit sparkle count
            if sparkles.count > 20 {
                sparkles.removeFirst()
            }
        }

        RunLoop.current.add(timer, forMode: .common)
    }
}

// MARK: - Mini Disco Ball

struct MiniDiscoBall: View {
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            // Ball
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.9),
                            Color.gray.opacity(0.6),
                            Color.gray.opacity(0.3)
                        ],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 30
                    )
                )

            // Tiles overlay
            Circle()
                .fill(
                    AngularGradient(
                        colors: [
                            Color.white.opacity(0.4),
                            Color.clear,
                            Color.white.opacity(0.3),
                            Color.clear,
                            Color.white.opacity(0.5),
                            Color.clear
                        ],
                        center: .center
                    )
                )
                .rotationEffect(.degrees(rotation))

            // Highlight
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(0.8), Color.clear],
                        center: UnitPoint(x: 0.3, y: 0.3),
                        startRadius: 0,
                        endRadius: 20
                    )
                )
        }
        .rotation3DEffect(.degrees(15), axis: (x: 1, y: 0, z: 0))
        .onAppear {
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

// MARK: - App Launch Wrapper

/// Wraps the app with splash screen on first launch
struct AppLaunchWrapper<Content: View>: View {
    @ViewBuilder let content: () -> Content

    @State private var showSplash = true

    var body: some View {
        ZStack {
            content()
                .opacity(showSplash ? 0 : 1)

            if showSplash {
                SplashScreenView(isComplete: $showSplash)
                    .transition(.opacity)
            }
        }
    }
}

// MARK: - Preview

#Preview("Splash Screen") {
    @Previewable @State var isComplete = false

    SplashScreenView(isComplete: $isComplete)
}
