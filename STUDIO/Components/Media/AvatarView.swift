//
//  AvatarView.swift
//  STUDIO
//
//  Pixel Afterdark Avatar Styles
//  Square avatars with pixel borders
//

import SwiftUI

// MARK: - Pixel Font Reference

private let pixelFontName = "VT323"

// MARK: - Avatar View

/// User avatar component with pixel aesthetic
/// Square shape for architectural feel, pixel border
struct AvatarView: View {
    let url: String?
    var size: AvatarSize = .medium
    var showBorder: Bool = false
    var borderColor: Color = .studioLine
    var placeholder: String = "person"

    var body: some View {
        Group {
            if let urlString = url, let imageURL = URL(string: urlString) {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .empty:
                        placeholderView
                            .overlay {
                                PixelLoadingIndicator()
                                    .scaleEffect(0.6)
                            }
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        placeholderView
                    @unknown default:
                        placeholderView
                    }
                }
            } else {
                placeholderView
            }
        }
        .frame(width: size.dimension, height: size.dimension)
        // Square clip for pixel aesthetic
        .clipShape(Rectangle())
        .overlay {
            Rectangle()
                .stroke(showBorder ? borderColor : Color.studioLine, lineWidth: showBorder ? 2 : 1)
        }
    }

    private var placeholderView: some View {
        ZStack {
            Color.studioSurface

            Image(systemName: placeholder)
                .font(.system(size: size.iconSize, weight: .ultraLight))
                .foregroundStyle(Color.studioMuted)
        }
    }
}

// MARK: - Avatar Size

enum AvatarSize {
    case tiny      // 24pt - for inline mentions
    case small     // 32pt - for lists
    case medium    // 44pt - for comments
    case large     // 64pt - for profiles
    case xlarge    // 100pt - for profile headers
    case xxlarge   // 150pt - for edit profile

    var dimension: CGFloat {
        switch self {
        case .tiny: return 24
        case .small: return 32
        case .medium: return 44
        case .large: return 64
        case .xlarge: return 100
        case .xxlarge: return 150
        }
    }

    var iconSize: CGFloat {
        switch self {
        case .tiny: return 10
        case .small: return 14
        case .medium: return 18
        case .large: return 26
        case .xlarge: return 40
        case .xxlarge: return 60
        }
    }
}

// MARK: - Avatar Stack

/// Overlapping avatar stack for showing multiple users
/// Uses square avatars with minimal overlap
struct AvatarStackView: View {
    let urls: [String?]
    var size: AvatarSize = .small
    var maxDisplay: Int = 3
    var overlap: CGFloat = 0.25

    var body: some View {
        HStack(spacing: -(size.dimension * overlap)) {
            ForEach(Array(urls.prefix(maxDisplay).enumerated()), id: \.offset) { index, url in
                AvatarView(url: url, size: size, showBorder: true, borderColor: .studioBlack)
                    .zIndex(Double(maxDisplay - index))
            }

            if urls.count > maxDisplay {
                ZStack {
                    Rectangle()
                        .fill(Color.studioSurface)

                    Text("+\(urls.count - maxDisplay)")
                        .font(.custom(pixelFontName, size: max(12, size.iconSize * 0.6)))
                        .foregroundStyle(Color.studioPrimary)
                }
                .frame(width: size.dimension, height: size.dimension)
                .overlay {
                    Rectangle()
                        .stroke(Color.studioLine, lineWidth: 2)
                }
            }
        }
    }
}

// MARK: - Avatar With Status

/// Avatar with status indicator (pixel square)
struct AvatarWithStatus: View {
    let url: String?
    var size: AvatarSize = .medium
    var status: UserStatus = .none

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            AvatarView(url: url, size: size, showBorder: true)

            if status != .none {
                // Pixel square status indicator
                Rectangle()
                    .fill(status.color)
                    .frame(width: statusSize, height: statusSize)
                    .overlay {
                        Rectangle()
                            .stroke(Color.studioBlack, lineWidth: 1)
                    }
                    .offset(x: 2, y: 2)
            }
        }
    }

    private var statusSize: CGFloat {
        switch size {
        case .tiny, .small: return 8
        case .medium: return 10
        case .large, .xlarge, .xxlarge: return 12
        }
    }
}

enum UserStatus {
    case none
    case online
    case away
    case busy

    var color: Color {
        switch self {
        case .none: return .clear
        case .online: return .studioPrimary
        case .away: return .studioMuted
        case .busy: return .studioError
        }
    }
}

// MARK: - Pixel Avatar (Alternate Style)

/// Pixelated avatar border style
struct PixelAvatarView: View {
    let url: String?
    var size: AvatarSize = .medium

    var body: some View {
        AvatarView(url: url, size: size)
            .overlay {
                // Double pixel border
                ZStack {
                    Rectangle()
                        .stroke(Color.studioLine, lineWidth: 2)
                    Rectangle()
                        .stroke(Color.studioLine.opacity(0.5), lineWidth: 1)
                        .padding(3)
                }
            }
    }
}

// MARK: - Preview

#Preview("Pixel Avatars") {
    ScrollView {
        VStack(spacing: 28) {
            Text("AVATARS")
                .studioLabelSmall()

            // Sizes
            HStack(spacing: 14) {
                AvatarView(url: nil, size: .tiny)
                AvatarView(url: nil, size: .small)
                AvatarView(url: nil, size: .medium)
                AvatarView(url: nil, size: .large)
            }

            Rectangle()
                .fill(Color.studioLine)
                .frame(height: 1)

            Text("WITH BORDER")
                .studioLabelSmall()

            AvatarView(url: nil, size: .large, showBorder: true)

            Rectangle()
                .fill(Color.studioLine)
                .frame(height: 1)

            Text("PIXEL STYLE")
                .studioLabelSmall()

            PixelAvatarView(url: nil, size: .large)

            Rectangle()
                .fill(Color.studioLine)
                .frame(height: 1)

            Text("STACK")
                .studioLabelSmall()

            AvatarStackView(urls: [nil, nil, nil, nil, nil])

            Rectangle()
                .fill(Color.studioLine)
                .frame(height: 1)

            Text("WITH STATUS")
                .studioLabelSmall()

            HStack(spacing: 14) {
                AvatarWithStatus(url: nil, size: .large, status: .online)
                AvatarWithStatus(url: nil, size: .large, status: .away)
                AvatarWithStatus(url: nil, size: .large, status: .busy)
            }

            Rectangle()
                .fill(Color.studioLine)
                .frame(height: 1)

            Text("PROFILE SIZE")
                .studioLabelSmall()

            AvatarView(url: nil, size: .xlarge, showBorder: true)
        }
        .padding(20)
    }
    .background(Color.studioBlack)
}
