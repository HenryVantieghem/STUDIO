//
//  AsyncImageView.swift
//  STUDIO
//
//  Created by Claude on 12/16/25.
//

import SwiftUI

// MARK: - Studio Async Image

/// Enhanced async image with loading and error states - Pixel Afterdark style (sharp edges)
struct StudioAsyncImage: View {
    let url: String?
    var contentMode: ContentMode = .fill
    var showLoadingIndicator: Bool = true

    var body: some View {
        Group {
            if let urlString = url, let imageURL = URL(string: urlString) {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .empty:
                        placeholderView
                            .overlay {
                                if showLoadingIndicator {
                                    PixelLoadingIndicator()
                                }
                            }
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: contentMode)
                    case .failure:
                        errorView
                    @unknown default:
                        placeholderView
                    }
                }
            } else {
                placeholderView
            }
        }
        .clipShape(Rectangle())
    }

    private var placeholderView: some View {
        Rectangle()
            .fill(Color.studioDeepBlack)
    }

    private var errorView: some View {
        ZStack {
            Color.studioDeepBlack

            VStack(spacing: 8) {
                Image(systemName: "photo")
                    .font(.system(size: 24, weight: .ultraLight))
                    .foregroundStyle(Color.studioMuted)

                Text("FAILED TO LOAD")
                    .font(StudioTypography.labelSmall)
                    .tracking(StudioTypography.trackingNormal)
                    .foregroundStyle(Color.studioMuted)
            }
        }
    }
}

// MARK: - Media Thumbnail

/// Thumbnail view for media items (photos/videos) - Pixel Afterdark style
struct MediaThumbnail: View {
    let url: String?
    var isVideo: Bool = false
    var duration: TimeInterval?
    var size: CGFloat = 100

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            StudioAsyncImage(
                url: url,
                contentMode: .fill
            )
            .frame(width: size, height: size)

            // Video indicator - pixel style
            if isVideo {
                HStack(spacing: 4) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 10, weight: .light))

                    if let duration {
                        Text(formatDuration(duration))
                            .font(StudioTypography.labelSmall)
                    }
                }
                .foregroundStyle(Color.studioPrimary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.studioBlack.opacity(0.8))
                .overlay {
                    Rectangle()
                        .stroke(Color.studioLine, lineWidth: 0.5)
                }
                .padding(4)
            }
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Cover Image View

/// Large cover image with gradient overlay
struct CoverImageView: View {
    let url: String?
    var height: CGFloat = 250
    var gradientHeight: CGFloat = 100

    var body: some View {
        ZStack(alignment: .bottom) {
            StudioAsyncImage(url: url, contentMode: .fill)
                .frame(height: height)
                .clipped()

            // Bottom gradient for text readability
            LinearGradient(
                colors: [.clear, .studioBlack.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: gradientHeight)
        }
        .frame(height: height)
    }
}

// MARK: - Media Grid Item

/// Grid item for photo galleries - Pixel Afterdark style
struct MediaGridItem: View {
    let url: String?
    var isVideo: Bool = false
    var duration: TimeInterval?
    var isSelected: Bool = false
    var selectionIndex: Int?
    var onTap: (() -> Void)?

    var body: some View {
        Button {
            onTap?()
        } label: {
            GeometryReader { geo in
                ZStack(alignment: .topTrailing) {
                    StudioAsyncImage(url: url, contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.width)

                    // Video badge - pixel style
                    if isVideo {
                        HStack(spacing: 4) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 10, weight: .light))

                            if let duration {
                                Text(formatDuration(duration))
                                    .font(StudioTypography.labelSmall)
                            }
                        }
                        .foregroundStyle(Color.studioPrimary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(Color.studioBlack.opacity(0.8))
                        .overlay {
                            Rectangle()
                                .stroke(Color.studioLine, lineWidth: 0.5)
                        }
                        .padding(4)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    }

                    // Selection indicator - pixel square style
                    if isSelected {
                        ZStack {
                            Rectangle()
                                .fill(Color.studioChrome)
                                .frame(width: 24, height: 24)

                            if let index = selectionIndex {
                                Text("\(index)")
                                    .font(StudioTypography.labelSmall)
                                    .foregroundStyle(Color.studioBlack)
                            } else {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(Color.studioBlack)
                            }
                        }
                        .overlay {
                            Rectangle()
                                .stroke(Color.studioLine, lineWidth: 0.5)
                        }
                        .padding(4)
                    }
                }
                .frame(width: geo.size.width, height: geo.size.width)
            }
            .aspectRatio(1, contentMode: .fit)
        }
        .buttonStyle(.plain)
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Preview

#Preview("Async Images") {
    ScrollView {
        VStack(spacing: 24) {
            // Basic async image - pixel style (sharp edges)
            StudioAsyncImage(url: nil)
                .frame(height: 200)

            // Media thumbnails
            HStack(spacing: 2) {
                MediaThumbnail(url: nil)
                MediaThumbnail(url: nil, isVideo: true, duration: 125)
                MediaThumbnail(url: nil)
            }

            // Cover image
            CoverImageView(url: nil)

            // Grid items
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 2),
                GridItem(.flexible(), spacing: 2),
                GridItem(.flexible(), spacing: 2)
            ], spacing: 2) {
                MediaGridItem(url: nil)
                MediaGridItem(url: nil, isVideo: true, duration: 30)
                MediaGridItem(url: nil, isSelected: true, selectionIndex: 1)
                MediaGridItem(url: nil, isSelected: true)
                MediaGridItem(url: nil)
                MediaGridItem(url: nil)
            }
        }
        .padding()
    }
    .background(Color.studioBlack)
}
