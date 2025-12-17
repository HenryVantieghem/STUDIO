//
//  LoadingView.swift
//  STUDIO
//
//  Basel Afterdark Loading States
//  Minimal, monochromatic, architectural
//

import SwiftUI

// MARK: - Loading View

/// Full-screen loading indicator with Basel Afterdark aesthetic
struct LoadingView: View {
    var message: String?

    @State private var isAnimating = false
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            Color.studioBlack.ignoresSafeArea()

            VStack(spacing: 32) {
                // Minimal geometric animation
                ZStack {
                    // Outer square
                    Rectangle()
                        .stroke(Color.studioLine, lineWidth: 0.5)
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(rotation))

                    // Inner square
                    Rectangle()
                        .stroke(Color.studioChrome.opacity(0.5), lineWidth: 0.5)
                        .frame(width: 40, height: 40)
                        .rotationEffect(.degrees(-rotation))

                    // Center dot
                    Circle()
                        .fill(Color.studioChrome)
                        .frame(width: 4, height: 4)
                        .opacity(isAnimating ? 1 : 0.3)
                }
                .animation(.linear(duration: 4).repeatForever(autoreverses: false), value: rotation)
                .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isAnimating)

                // Loading text - minimal
                if let message {
                    Text(message.uppercased())
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .tracking(StudioTypography.trackingWide)
                        .foregroundStyle(Color.studioMuted)
                } else {
                    Text("LOADING")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .tracking(StudioTypography.trackingWide)
                        .foregroundStyle(Color.studioMuted)
                }
            }
        }
        .onAppear {
            isAnimating = true
            rotation = 360
        }
    }
}

// MARK: - Inline Loading Indicator

/// Small loading indicator for inline use
struct StudioLoadingIndicator: View {
    var size: CGFloat = 16
    var color: Color = .studioChrome

    @State private var isAnimating = false

    var body: some View {
        Rectangle()
            .stroke(color, lineWidth: 0.5)
            .frame(width: size, height: size)
            .rotationEffect(.degrees(isAnimating ? 360 : 0))
            .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: isAnimating)
            .onAppear {
                isAnimating = true
            }
    }
}

// MARK: - Skeleton Loading View

/// Skeleton placeholder for loading content - sharp edges
struct SkeletonView: View {
    var width: CGFloat? = nil
    var height: CGFloat = 20

    @State private var isAnimating = false

    var body: some View {
        Rectangle()
            .fill(Color.studioSurface)
            .frame(width: width, height: height)
            .overlay {
                LinearGradient(
                    colors: [
                        .clear,
                        Color.studioLine.opacity(0.3),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: isAnimating ? 200 : -200)
            }
            .clipped()
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - Layout-Specific Skeletons

/// Party card skeleton that matches actual PartyCard layout
struct PartyCardSkeleton: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Cover image placeholder
            Rectangle()
                .fill(Color.studioSurface)
                .frame(height: 160)
                .shimmer(isAnimating: isAnimating)

            // Content area
            VStack(alignment: .leading, spacing: 12) {
                // Title
                SkeletonView(width: 180, height: 22)

                // Host info
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.studioSurface)
                        .frame(width: 24, height: 24)
                    SkeletonView(width: 100, height: 14)
                }

                // Date and location
                HStack(spacing: 16) {
                    SkeletonView(width: 80, height: 12)
                    SkeletonView(width: 60, height: 12)
                }

                // Stats row
                HStack(spacing: 24) {
                    SkeletonView(width: 40, height: 16)
                    SkeletonView(width: 40, height: 16)
                    SkeletonView(width: 40, height: 16)
                }
            }
            .padding(16)
        }
        .background(Color.studioSurface)
        .overlay {
            Rectangle()
                .stroke(Color.studioLine, lineWidth: 0.5)
        }
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }
}

/// User row skeleton for lists
struct UserRowSkeleton: View {
    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            Rectangle()
                .fill(Color.studioSurface)
                .frame(width: 48, height: 48)

            // Text content
            VStack(alignment: .leading, spacing: 8) {
                SkeletonView(width: 120, height: 16)
                SkeletonView(width: 80, height: 12)
            }

            Spacer()

            // Action button placeholder
            SkeletonView(width: 70, height: 32)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

/// Comment skeleton for comment lists
struct CommentSkeleton: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Avatar
            Rectangle()
                .fill(Color.studioSurface)
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 8) {
                // Username and time
                HStack(spacing: 8) {
                    SkeletonView(width: 80, height: 14)
                    SkeletonView(width: 40, height: 12)
                }

                // Comment text (multiple lines)
                SkeletonView(height: 14)
                SkeletonView(width: 200, height: 14)
            }
        }
        .padding(16)
    }
}

/// Media grid skeleton
struct MediaGridSkeleton: View {
    let columns = 3

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: columns), spacing: 2) {
            ForEach(0..<9, id: \.self) { _ in
                Rectangle()
                    .fill(Color.studioSurface)
                    .aspectRatio(1, contentMode: .fill)
                    .shimmer(isAnimating: true)
            }
        }
    }
}

/// Feed loading skeleton - matches FeedView layout
struct FeedSkeleton: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(0..<3, id: \.self) { _ in
                    PartyCardSkeleton()
                }
            }
            .padding(16)
        }
        .background(Color.studioBlack)
    }
}

// MARK: - Shimmer Modifier

extension View {
    func shimmer(isAnimating: Bool) -> some View {
        self.overlay {
            LinearGradient(
                colors: [
                    .clear,
                    Color.studioLine.opacity(0.3),
                    .clear
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .offset(x: isAnimating ? 200 : -200)
            .animation(.linear(duration: 1.5).repeatForever(autoreverses: false), value: isAnimating)
        }
        .clipped()
    }
}

// MARK: - Loading Button Content

/// Content view for buttons that are loading
struct LoadingButtonContent: View {
    let title: String
    let isLoading: Bool

    var body: some View {
        Group {
            if isLoading {
                StudioLoadingIndicator(size: 14, color: .studioBlack)
            } else {
                Text(title)
            }
        }
    }
}

// MARK: - Pull to Refresh Style

/// Custom refresh control appearance
struct StudioRefreshControl: View {
    var body: some View {
        HStack(spacing: 12) {
            StudioLoadingIndicator(size: 12)

            Text("REFRESHING")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .tracking(StudioTypography.trackingWide)
                .foregroundStyle(Color.studioMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
}

// MARK: - Preview

#Preview("Loading States") {
    VStack(spacing: 40) {
        LoadingView(message: "preparing the night...")

        VStack(spacing: 20) {
            Text("INLINE")
                .studioLabelSmall()

            HStack {
                Text("LOADING")
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundStyle(Color.studioSecondary)
                StudioLoadingIndicator()
            }

            Divider()
                .background(Color.studioLine)

            Text("SKELETON")
                .studioLabelSmall()

            VStack(alignment: .leading, spacing: 8) {
                SkeletonView(width: 200, height: 24)
                SkeletonView(height: 16)
                SkeletonView(width: 150, height: 16)
            }

            Divider()
                .background(Color.studioLine)

            Text("BUTTON")
                .studioLabelSmall()

            Button {} label: {
                LoadingButtonContent(title: "SUBMIT", isLoading: true)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
            }
            .buttonStyle(.studioPrimary)
        }
        .padding(24)
    }
    .background(Color.studioBlack)
}
