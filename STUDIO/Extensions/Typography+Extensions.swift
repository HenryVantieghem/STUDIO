//
//  Typography+Extensions.swift
//  STUDIO
//
//  Pixel Afterdark Typography System
//  8-bit retro pixel font - VT323
//

import SwiftUI

// MARK: - Pixel Font Configuration

/// The pixel font name as registered in Info.plist
/// VT323 - A more readable pixel font with taller characters
private let pixelFontName = "VT323"

// MARK: - Pixel Afterdark Typography

/// Typography system using VT323 pixel font
/// ALL text uses pixel font for authentic 8-bit aesthetic
/// VT323 is more readable than Press Start 2P with taller glyphs
enum StudioTypography {

    // MARK: - Display Styles (Hero Text)

    /// Display Large - Hero text, splash screens
    static let displayLarge = Font.custom(pixelFontName, size: 48)

    /// Display Medium - Section headers
    static let displayMedium = Font.custom(pixelFontName, size: 36)

    /// Display Small - Card titles
    static let displaySmall = Font.custom(pixelFontName, size: 28)

    // MARK: - Headline Styles

    /// Headline Large - Page titles
    static let headlineLarge = Font.custom(pixelFontName, size: 24)

    /// Headline Medium - Section titles
    static let headlineMedium = Font.custom(pixelFontName, size: 20)

    /// Headline Small - Subsection titles
    static let headlineSmall = Font.custom(pixelFontName, size: 18)

    // MARK: - Body Styles

    /// Body Large - Primary content
    static let bodyLarge = Font.custom(pixelFontName, size: 16)

    /// Body Medium - Secondary content
    static let bodyMedium = Font.custom(pixelFontName, size: 14)

    /// Body Small - Tertiary content
    static let bodySmall = Font.custom(pixelFontName, size: 12)

    // MARK: - Label Styles

    /// Label Large - Button text
    static let labelLarge = Font.custom(pixelFontName, size: 16)

    /// Label Medium - Field labels
    static let labelMedium = Font.custom(pixelFontName, size: 14)

    /// Label Small - Captions, metadata
    static let labelSmall = Font.custom(pixelFontName, size: 12)

    // MARK: - Letter Spacing Values
    // VT323 works well with wider tracking for that retro feel

    /// Standard tracking for pixel font
    static let trackingStandard: CGFloat = 1.5

    /// Wide tracking for display text
    static let trackingWide: CGFloat = 3.0

    /// Extra wide for hero text
    static let trackingExtraWide: CGFloat = 5.0

    /// Normal tracking for body
    static let trackingNormal: CGFloat = 1.0
}

// MARK: - Font Extensions

extension Font {
    /// Pixel font with specified size
    static func studioPixel(size: CGFloat) -> Font {
        .custom(pixelFontName, size: size)
    }

    /// Fallback monospace if pixel font not loaded
    static func studioMono(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

// MARK: - View Modifiers for Typography

extension View {
    /// Apply display large style - Hero text
    func studioDisplayLarge() -> some View {
        self
            .font(StudioTypography.displayLarge)
            .tracking(StudioTypography.trackingExtraWide)
            .textCase(.uppercase)
            .foregroundStyle(Color.studioPrimary)
    }

    /// Apply display medium style
    func studioDisplayMedium() -> some View {
        self
            .font(StudioTypography.displayMedium)
            .tracking(StudioTypography.trackingWide)
            .textCase(.uppercase)
            .foregroundStyle(Color.studioPrimary)
    }

    /// Apply display small style
    func studioDisplaySmall() -> some View {
        self
            .font(StudioTypography.displaySmall)
            .tracking(StudioTypography.trackingWide)
            .textCase(.uppercase)
            .foregroundStyle(Color.studioPrimary)
    }

    /// Apply headline large style
    func studioHeadlineLarge() -> some View {
        self
            .font(StudioTypography.headlineLarge)
            .tracking(StudioTypography.trackingWide)
            .textCase(.uppercase)
            .foregroundStyle(Color.studioPrimary)
    }

    /// Apply headline medium style
    func studioHeadlineMedium() -> some View {
        self
            .font(StudioTypography.headlineMedium)
            .tracking(StudioTypography.trackingStandard)
            .textCase(.uppercase)
            .foregroundStyle(Color.studioPrimary)
    }

    /// Apply headline small style
    func studioHeadlineSmall() -> some View {
        self
            .font(StudioTypography.headlineSmall)
            .tracking(StudioTypography.trackingStandard)
            .textCase(.uppercase)
            .foregroundStyle(Color.studioPrimary)
    }

    /// Apply body large style
    func studioBodyLarge() -> some View {
        self
            .font(StudioTypography.bodyLarge)
            .tracking(StudioTypography.trackingNormal)
            .foregroundStyle(Color.studioSecondary)
    }

    /// Apply body medium style
    func studioBodyMedium() -> some View {
        self
            .font(StudioTypography.bodyMedium)
            .tracking(StudioTypography.trackingNormal)
            .foregroundStyle(Color.studioSecondary)
    }

    /// Apply body small style
    func studioBodySmall() -> some View {
        self
            .font(StudioTypography.bodySmall)
            .tracking(StudioTypography.trackingNormal)
            .foregroundStyle(Color.studioMuted)
    }

    /// Apply label large style
    func studioLabelLarge() -> some View {
        self
            .font(StudioTypography.labelLarge)
            .tracking(StudioTypography.trackingStandard)
            .textCase(.uppercase)
            .foregroundStyle(Color.studioSecondary)
    }

    /// Apply label medium style
    func studioLabelMedium() -> some View {
        self
            .font(StudioTypography.labelMedium)
            .tracking(StudioTypography.trackingNormal)
            .textCase(.uppercase)
            .foregroundStyle(Color.studioMuted)
    }

    /// Apply label small style
    func studioLabelSmall() -> some View {
        self
            .font(StudioTypography.labelSmall)
            .tracking(StudioTypography.trackingNormal)
            .textCase(.uppercase)
            .foregroundStyle(Color.studioMuted)
    }

    /// Chrome/accent text style
    func studioChrome() -> some View {
        self
            .foregroundStyle(Color.studioChrome)
    }

    /// Muted text style
    func studioMuted() -> some View {
        self
            .foregroundStyle(Color.studioMuted)
    }
}

// MARK: - Preview

#Preview("Pixel Typography") {
    ScrollView {
        VStack(alignment: .leading, spacing: 32) {
            // Display Styles
            VStack(alignment: .leading, spacing: 16) {
                Text("DISPLAY")
                    .studioLabelSmall()

                Text("AFTERDARK")
                    .studioDisplayLarge()

                Text("PRIVATE EVENT")
                    .studioDisplayMedium()

                Text("BASEL 2025")
                    .studioDisplaySmall()
            }

            Rectangle()
                .fill(Color.studioLine)
                .frame(height: 1)

            // Headline Styles
            VStack(alignment: .leading, spacing: 12) {
                Text("HEADLINES")
                    .studioLabelSmall()

                Text("PAGE TITLE")
                    .studioHeadlineLarge()

                Text("SECTION TITLE")
                    .studioHeadlineMedium()

                Text("SUBSECTION")
                    .studioHeadlineSmall()
            }

            Rectangle()
                .fill(Color.studioLine)
                .frame(height: 1)

            // Body Styles
            VStack(alignment: .leading, spacing: 12) {
                Text("BODY TEXT")
                    .studioLabelSmall()

                Text("Primary content with pixel styling")
                    .studioBodyLarge()

                Text("Secondary content for descriptions")
                    .studioBodyMedium()

                Text("Tertiary content for metadata")
                    .studioBodySmall()
            }

            Rectangle()
                .fill(Color.studioLine)
                .frame(height: 1)

            // Label Styles
            VStack(alignment: .leading, spacing: 12) {
                Text("LABELS")
                    .studioLabelSmall()

                Text("BUTTON TEXT")
                    .studioLabelLarge()

                Text("FIELD LABEL")
                    .studioLabelMedium()

                Text("CAPTION")
                    .studioLabelSmall()
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .background(Color.studioBlack)
}
