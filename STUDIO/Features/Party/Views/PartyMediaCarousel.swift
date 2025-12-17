//
//  PartyMediaCarousel.swift
//  STUDIO
//
//  Instagram-style swipeable media carousel
//  Basel Afterdark Design System
//

import SwiftUI
import AVKit

// MARK: - Party Media Carousel

/// Instagram-style swipeable photo/video carousel
struct PartyMediaCarousel: View {
    let media: [PartyMedia]
    var isLoading: Bool = false
    @State private var currentIndex = 0
    @State private var showMediaDetail = false
    @State private var selectedMedia: PartyMedia?

    var body: some View {
        ZStack {
            if isLoading {
                loadingView
            } else if media.isEmpty {
                emptyMediaView
            } else {
                carouselContent
            }
        }
        .frame(height: UIScreen.main.bounds.width) // Square aspect ratio like Instagram
        .background(Color.studioDeepBlack)
        .sheet(item: $selectedMedia) { media in
            MediaDetailView(media: media)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color.studioBlack)
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        ZStack {
            Color.studioSurface

            VStack(spacing: 16) {
                StudioLoadingIndicator(size: 24, color: .studioChrome)

                Text("LOADING MEDIA")
                    .font(StudioTypography.labelSmall)
                    .tracking(StudioTypography.trackingWide)
                    .foregroundStyle(Color.studioMuted)
            }
        }
    }

    // MARK: - Empty View

    private var emptyMediaView: some View {
        ZStack {
            // Geometric pattern background
            GeometryReader { geo in
                Path { path in
                    let spacing: CGFloat = 40
                    for x in stride(from: 0, to: geo.size.width, by: spacing) {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: geo.size.height))
                    }
                    for y in stride(from: 0, to: geo.size.height, by: spacing) {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geo.size.width, y: y))
                    }
                }
                .stroke(Color.studioLine.opacity(0.3), lineWidth: 0.5)
            }

            VStack(spacing: 16) {
                Image(systemName: "camera")
                    .font(.system(size: 40, weight: .ultraLight))
                    .foregroundStyle(Color.studioLine)

                Text("NO MEDIA YET")
                    .font(StudioTypography.labelMedium)
                    .tracking(StudioTypography.trackingWide)
                    .foregroundStyle(Color.studioMuted)

                Text("BE THE FIRST TO CAPTURE")
                    .font(StudioTypography.labelSmall)
                    .tracking(StudioTypography.trackingNormal)
                    .foregroundStyle(Color.studioMuted.opacity(0.6))
            }
        }
    }

    // MARK: - Carousel Content

    private var carouselContent: some View {
        ZStack(alignment: .bottom) {
            // Swipeable carousel
            TabView(selection: $currentIndex) {
                ForEach(Array(media.enumerated()), id: \.element.id) { index, item in
                    MediaItemView(
                        media: item,
                        onTap: {
                            selectedMedia = item
                        }
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Bottom overlay with indicator and user info
            VStack(spacing: 0) {
                Spacer()

                // User who added this media
                if let currentMedia = media[safe: currentIndex],
                   let user = currentMedia.user {
                    HStack(spacing: 10) {
                        AvatarView(
                            url: user.avatarUrl,
                            size: .small,
                            showBorder: true,
                            borderColor: .studioBlack
                        )

                        VStack(alignment: .leading, spacing: 2) {
                            Text(user.displayName ?? user.username)
                                .font(StudioTypography.labelSmall)
                                .tracking(StudioTypography.trackingNormal)
                                .textCase(.uppercase)
                                .foregroundStyle(Color.studioPrimary)

                            Text(formatTimeAgo(currentMedia.createdAt))
                                .font(StudioTypography.labelSmall)
                                .tracking(StudioTypography.trackingNormal)
                                .foregroundStyle(Color.studioMuted)
                        }

                        Spacer()

                        // Media type indicator
                        if currentMedia.mediaType == .video {
                            HStack(spacing: 4) {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 8))
                                if let duration = currentMedia.duration {
                                    Text(formatDuration(duration))
                                        .font(StudioTypography.labelSmall)
                                }
                            }
                            .foregroundStyle(Color.studioChrome)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [.clear, Color.studioBlack.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }

                // Page indicator
                if media.count > 1 {
                    pageIndicator
                        .padding(.bottom, 12)
                }
            }

            // Counter badge (top right)
            if media.count > 1 {
                Text("\(currentIndex + 1)/\(media.count)")
                    .font(StudioTypography.labelSmall)
                    .tracking(StudioTypography.trackingNormal)
                    .foregroundStyle(Color.studioPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.studioBlack.opacity(0.7))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(12)
            }
        }
    }

    // MARK: - Page Indicator

    private var pageIndicator: some View {
        HStack(spacing: 4) {
            ForEach(0..<min(media.count, 10), id: \.self) { index in
                Rectangle()
                    .fill(index == currentIndex ? Color.studioChrome : Color.studioLine)
                    .frame(width: index == currentIndex ? 16 : 6, height: 2)
                    .animation(.easeInOut(duration: 0.2), value: currentIndex)
            }

            if media.count > 10 {
                Text("+\(media.count - 10)")
                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.studioMuted)
            }
        }
    }

    // MARK: - Helpers

    private func formatTimeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date()).uppercased()
    }

    private func formatDuration(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}

// MARK: - Media Item View

/// Single media item in carousel (photo or video)
struct MediaItemView: View {
    let media: PartyMedia
    var onTap: (() -> Void)?

    @State private var isPlaying = false

    var body: some View {
        ZStack {
            if media.mediaType == .video {
                videoContent
            } else {
                photoContent
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap?()
        }
    }

    private var photoContent: some View {
        AsyncImage(url: URL(string: media.url)) { phase in
            switch phase {
            case .empty:
                ZStack {
                    Color.studioSurface
                    StudioLoadingIndicator(size: 20, color: .studioChrome)
                }
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            case .failure:
                ZStack {
                    Color.studioSurface
                    VStack(spacing: 8) {
                        Image(systemName: "photo")
                            .font(.system(size: 32, weight: .ultraLight))
                            .foregroundStyle(Color.studioLine)
                        Text("FAILED TO LOAD")
                            .font(StudioTypography.labelSmall)
                            .foregroundStyle(Color.studioMuted)
                    }
                }
            @unknown default:
                Color.studioSurface
            }
        }
    }

    private var videoContent: some View {
        ZStack {
            // Thumbnail
            if let thumbnailUrl = media.thumbnailUrl {
                AsyncImage(url: URL(string: thumbnailUrl)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Color.studioSurface
                }
            } else {
                Color.studioSurface
            }

            // Play button overlay
            if !isPlaying {
                ZStack {
                    Rectangle()
                        .fill(Color.studioBlack.opacity(0.3))

                    Image(systemName: "play.fill")
                        .font(.system(size: 48, weight: .ultraLight))
                        .foregroundStyle(Color.studioPrimary)
                }
            }
        }
    }
}

// MARK: - Media Detail View

/// Full screen media viewer
struct MediaDetailView: View {
    let media: PartyMedia
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.studioBlack.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    if let user = media.user {
                        HStack(spacing: 10) {
                            AvatarView(url: user.avatarUrl, size: .small)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(user.displayName ?? user.username)
                                    .font(StudioTypography.labelMedium)
                                    .textCase(.uppercase)
                                    .foregroundStyle(Color.studioPrimary)

                                Text(formatDate(media.createdAt))
                                    .font(StudioTypography.labelSmall)
                                    .foregroundStyle(Color.studioMuted)
                            }
                        }
                    }

                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .light))
                            .foregroundStyle(Color.studioMuted)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                Spacer()

                // Media content
                if media.mediaType == .video {
                    if let url = URL(string: media.url) {
                        VideoPlayer(player: AVPlayer(url: url))
                            .aspectRatio(contentMode: .fit)
                    }
                } else {
                    AsyncImage(url: URL(string: media.url)) { image in
                        image
                            .resizable()
                            .scaledToFit()
                    } placeholder: {
                        StudioLoadingIndicator(size: 24, color: .studioChrome)
                    }
                }

                Spacer()

                // Caption
                if let caption = media.caption, !caption.isEmpty {
                    Text(caption)
                        .font(StudioTypography.bodyMedium)
                        .foregroundStyle(Color.studioSecondary)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.studioSurface)
                }
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
        return formatter.string(from: date).uppercased()
    }
}

// MARK: - Safe Collection Access

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Preview

#Preview("Media Carousel - With Media") {
    VStack(spacing: 0) {
        PartyMediaCarousel(
            media: MockData.partyMedia,
            isLoading: false
        )
    }
    .background(Color.studioBlack)
}

#Preview("Media Carousel - Empty") {
    VStack(spacing: 0) {
        PartyMediaCarousel(
            media: [],
            isLoading: false
        )
    }
    .background(Color.studioBlack)
}

#Preview("Media Carousel - Loading") {
    VStack(spacing: 0) {
        PartyMediaCarousel(
            media: [],
            isLoading: true
        )
    }
    .background(Color.studioBlack)
}
