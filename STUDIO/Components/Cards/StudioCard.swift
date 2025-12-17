//
//  StudioCard.swift
//  STUDIO
//
//  Pixel Afterdark Card Styles
//  8-bit retro aesthetic with pixel borders
//

import SwiftUI

// MARK: - Pixel Font Reference

private let pixelFontName = "VT323"

// MARK: - Studio Card

/// Base card component with pixel aesthetic
struct StudioCard<Content: View>: View {
    @ViewBuilder var content: () -> Content
    var padding: CGFloat = 16

    var body: some View {
        content()
            .padding(padding)
            .background(Color.studioSurface)
            .overlay {
                Rectangle()
                    .stroke(Color.studioLine, lineWidth: 2)
            }
    }
}

// MARK: - Pixel Border Card

/// Card with double pixel border effect
struct PixelBorderCard<Content: View>: View {
    @ViewBuilder var content: () -> Content
    var padding: CGFloat = 16

    var body: some View {
        content()
            .padding(padding)
            .background(Color.studioSurface)
            .overlay {
                ZStack {
                    Rectangle()
                        .stroke(Color.studioLine, lineWidth: 2)
                    Rectangle()
                        .stroke(Color.studioLine.opacity(0.5), lineWidth: 1)
                        .padding(4)
                }
            }
    }
}

// MARK: - User Row Card

/// Card for displaying user information in lists
struct UserRowCard: View {
    let name: String
    let username: String
    let avatarUrl: String?
    var subtitle: String?
    var showChevron: Bool = true
    var action: (() -> Void)?

    var body: some View {
        Button {
            action?()
        } label: {
            HStack(spacing: 14) {
                AvatarView(url: avatarUrl, size: .medium)

                VStack(alignment: .leading, spacing: 6) {
                    Text(name)
                        .font(.custom(pixelFontName, size: 18))
                        .tracking(StudioTypography.trackingStandard)
                        .textCase(.uppercase)
                        .foregroundStyle(Color.studioPrimary)

                    Text("@\(username)")
                        .font(.custom(pixelFontName, size: 14))
                        .tracking(StudioTypography.trackingNormal)
                        .foregroundStyle(Color.studioMuted)

                    if let subtitle {
                        Text(subtitle)
                            .font(.custom(pixelFontName, size: 12))
                            .tracking(StudioTypography.trackingStandard)
                            .textCase(.uppercase)
                            .foregroundStyle(Color.studioChrome)
                    }
                }

                Spacer()

                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .light))
                        .foregroundStyle(Color.studioMuted)
                }
            }
            .padding(14)
            .background(Color.studioSurface)
            .overlay {
                Rectangle()
                    .stroke(Color.studioLine, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Stat Card

/// Card for displaying statistics - pixel style
struct StatCard: View {
    let title: String
    let value: String
    var icon: String?
    var trend: StatTrend = .none

    var body: some View {
        VStack(spacing: 10) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .light))
                    .foregroundStyle(Color.studioChrome)
            }

            Text(value)
                .font(.custom(pixelFontName, size: 28))
                .tracking(StudioTypography.trackingStandard)
                .foregroundStyle(Color.studioPrimary)

            HStack(spacing: 6) {
                Text(title)
                    .font(.custom(pixelFontName, size: 12))
                    .tracking(StudioTypography.trackingStandard)
                    .textCase(.uppercase)
                    .foregroundStyle(Color.studioMuted)

                if trend != .none {
                    Image(systemName: trend.icon)
                        .font(.system(size: 8, weight: .light))
                        .foregroundStyle(trend.color)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color.studioSurface)
        .overlay {
            Rectangle()
                .stroke(Color.studioLine, lineWidth: 1)
        }
    }
}

enum StatTrend {
    case none
    case up
    case down

    var icon: String {
        switch self {
        case .none: return ""
        case .up: return "arrow.up"
        case .down: return "arrow.down"
        }
    }

    var color: Color {
        switch self {
        case .none: return .clear
        case .up: return .studioPrimary
        case .down: return .studioMuted
        }
    }
}

// MARK: - Info Card

/// Informational card with icon - pixel style
struct InfoCard: View {
    let icon: String
    let title: String
    let message: String
    var style: InfoCardStyle = .info

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .light))
                .foregroundStyle(style.color)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.custom(pixelFontName, size: 28))
                    .tracking(StudioTypography.trackingStandard)
                    .textCase(.uppercase)
                    .foregroundStyle(Color.studioPrimary)

                Text(message)
                    .font(.custom(pixelFontName, size: 14))
                    .tracking(StudioTypography.trackingNormal)
                    .foregroundStyle(Color.studioSecondary)
                    .lineSpacing(4)
            }

            Spacer()
        }
        .padding(16)
        .background(Color.studioSurface)
        .overlay {
            Rectangle()
                .stroke(style.borderColor, lineWidth: 1)
        }
    }
}

enum InfoCardStyle {
    case info
    case success
    case warning
    case error

    var color: Color {
        switch self {
        case .info: return .studioPrimary
        case .success: return .studioPrimary
        case .warning: return .studioChrome
        case .error: return .studioError
        }
    }

    var borderColor: Color {
        switch self {
        case .info: return .studioLine
        case .success: return .studioLine
        case .warning: return .studioChrome.opacity(0.4)
        case .error: return .studioError.opacity(0.4)
        }
    }
}

// MARK: - Action Card

/// Card with action button - pixel style
struct ActionCard: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String
    var action: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .light))
                    .foregroundStyle(Color.studioChrome)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.custom(pixelFontName, size: 18))
                        .tracking(StudioTypography.trackingStandard)
                        .textCase(.uppercase)
                        .foregroundStyle(Color.studioPrimary)

                    Text(message)
                        .font(.custom(pixelFontName, size: 14))
                        .tracking(StudioTypography.trackingNormal)
                        .foregroundStyle(Color.studioSecondary)
                        .lineSpacing(4)
                }

                Spacer()
            }

            Button(actionTitle, action: action)
                .buttonStyle(.studioSecondary)
        }
        .padding(16)
        .background(Color.studioSurface)
        .overlay {
            Rectangle()
                .stroke(Color.studioLine, lineWidth: 1)
        }
    }
}

// MARK: - Event Card

/// Large card for events/parties - pixel hero style
struct EventCard: View {
    let title: String
    let subtitle: String
    var date: String?
    var imageUrl: String?
    var isPrivate: Bool = false
    var action: (() -> Void)?

    var body: some View {
        Button {
            action?()
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                // Image area or placeholder
                ZStack(alignment: .topTrailing) {
                    if let imageUrl {
                        AsyncImage(url: URL(string: imageUrl)) { image in
                            image
                                .resizable()
                                .aspectRatio(16/9, contentMode: .fill)
                        } placeholder: {
                            Rectangle()
                                .fill(Color.studioSurface)
                        }
                        .frame(height: 160)
                        .clipped()
                    } else {
                        Rectangle()
                            .fill(Color.studioSurface)
                            .frame(height: 160)
                            .overlay {
                                // Pixel disco ball placeholder
                                PixelDiscoBall()
                            }
                    }

                    if isPrivate {
                        Text("PRIVATE")
                            .font(.custom(pixelFontName, size: 12))
                            .tracking(StudioTypography.trackingStandard)
                            .foregroundStyle(Color.studioPrimary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(Color.studioBlack.opacity(0.9))
                            .overlay {
                                Rectangle()
                                    .stroke(Color.studioLine, lineWidth: 1)
                            }
                            .padding(10)
                    }
                }

                // Content
                VStack(alignment: .leading, spacing: 10) {
                    Text(title)
                        .font(.custom(pixelFontName, size: 20))
                        .tracking(StudioTypography.trackingWide)
                        .textCase(.uppercase)
                        .foregroundStyle(Color.studioPrimary)
                        .lineLimit(1)

                    Text(subtitle)
                        .font(.custom(pixelFontName, size: 14))
                        .tracking(StudioTypography.trackingNormal)
                        .foregroundStyle(Color.studioSecondary)
                        .lineLimit(2)
                        .lineSpacing(3)

                    if let date {
                        Text(date)
                            .font(.custom(pixelFontName, size: 12))
                            .tracking(StudioTypography.trackingStandard)
                            .textCase(.uppercase)
                            .foregroundStyle(Color.studioMuted)
                            .padding(.top, 4)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.studioSurface)
            }
            .overlay {
                Rectangle()
                    .stroke(Color.studioLine, lineWidth: 2)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Pixel Disco Ball (Placeholder)

/// Simple pixel art disco ball for placeholders
struct PixelDiscoBall: View {
    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height) * 0.5

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(white: 0.6),
                            Color(white: 0.3),
                            Color(white: 0.15)
                        ],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: size
                    )
                )
                .frame(width: size, height: size)
                .overlay {
                    // Pixel grid effect
                    PixelGrid(rows: 8, cols: 8)
                        .clipShape(Circle())
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

/// Pixel grid overlay for disco ball effect
struct PixelGrid: View {
    let rows: Int
    let cols: Int

    var body: some View {
        GeometryReader { geo in
            let cellWidth = geo.size.width / CGFloat(cols)
            let cellHeight = geo.size.height / CGFloat(rows)

            ForEach(0..<rows, id: \.self) { row in
                ForEach(0..<cols, id: \.self) { col in
                    Rectangle()
                        .stroke(Color.studioBlack.opacity(0.3), lineWidth: 0.5)
                        .frame(width: cellWidth, height: cellHeight)
                        .position(
                            x: CGFloat(col) * cellWidth + cellWidth / 2,
                            y: CGFloat(row) * cellHeight + cellHeight / 2
                        )
                }
            }
        }
    }
}

// MARK: - Performer Box

/// Bordered box for performer names (like in the flyer)
struct PerformerBox: View {
    let label: String
    let names: [String]

    var body: some View {
        VStack(spacing: 12) {
            Text(label)
                .font(.custom(pixelFontName, size: 14))
                .tracking(StudioTypography.trackingStandard)
                .textCase(.uppercase)
                .foregroundStyle(Color.studioSecondary)

            ForEach(names, id: \.self) { name in
                Text(name)
                    .font(.custom(pixelFontName, size: 18))
                    .tracking(StudioTypography.trackingStandard)
                    .textCase(.uppercase)
                    .foregroundStyle(Color.studioPrimary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .overlay {
            Rectangle()
                .stroke(Color.studioPrimary, lineWidth: 2)
        }
    }
}

// MARK: - Preview

#Preview("Pixel Cards") {
    ScrollView {
        VStack(spacing: 20) {
            Text("CARDS")
                .studioLabelSmall()

            StudioCard {
                Text("BASIC CARD CONTENT")
                    .studioBodyMedium()
            }

            PixelBorderCard {
                Text("DOUBLE BORDER CARD")
                    .studioBodyMedium()
            }

            Rectangle()
                .fill(Color.studioLine)
                .frame(height: 1)

            Text("USER ROW")
                .studioLabelSmall()

            UserRowCard(
                name: "AFTERDARK",
                username: "afterdark",
                avatarUrl: nil,
                subtitle: "HOST"
            )

            Rectangle()
                .fill(Color.studioLine)
                .frame(height: 1)

            Text("STATISTICS")
                .studioLabelSmall()

            HStack(spacing: 10) {
                StatCard(title: "GUESTS", value: "24", icon: "person.2", trend: .up)
                StatCard(title: "PHOTOS", value: "86", icon: "camera")
            }

            Rectangle()
                .fill(Color.studioLine)
                .frame(height: 1)

            Text("PERFORMER BOX")
                .studioLabelSmall()

            PerformerBox(
                label: "PERFORMANCE BY",
                names: ["ROB THE BANK - JOA", "LUIS NORONHA - RONII"]
            )

            Rectangle()
                .fill(Color.studioLine)
                .frame(height: 1)

            Text("EVENT")
                .studioLabelSmall()

            EventCard(
                title: "BASEL AFTERDARK",
                subtitle: "Private event at undisclosed location",
                date: "DEC 4, 2025 | 10 PM - 5 AM",
                isPrivate: true
            )
        }
        .padding(20)
    }
    .background(Color.studioBlack)
}
