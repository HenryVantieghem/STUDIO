//
//  Spacing+Extensions.swift
//  STUDIO
//
//  Pixel Afterdark Spacing System
//  Consistent spacing values for pixel-perfect layouts
//

import SwiftUI

// MARK: - Pixel Afterdark Spacing System

/// 8pt grid-based spacing system for consistent pixel-perfect layouts
enum StudioSpacing {
    // MARK: - Base Spacing (8pt grid)

    /// 4pt - Extra small spacing
    static let xs: CGFloat = 4

    /// 8pt - Small spacing
    static let sm: CGFloat = 8

    /// 12pt - Medium-small spacing
    static let md: CGFloat = 12

    /// 16pt - Medium spacing (default)
    static let lg: CGFloat = 16

    /// 20pt - Large spacing
    static let xl: CGFloat = 20

    /// 24pt - Extra large spacing
    static let xxl: CGFloat = 24

    /// 32pt - Section spacing
    static let section: CGFloat = 32

    /// 48pt - Large section spacing
    static let largeSection: CGFloat = 48

    // MARK: - Component-Specific Spacing

    /// Card internal padding
    static let cardPadding: CGFloat = 16

    /// Card internal tight padding
    static let cardPaddingTight: CGFloat = 12

    /// Card internal loose padding
    static let cardPaddingLoose: CGFloat = 20

    /// Button internal padding horizontal
    static let buttonPaddingH: CGFloat = 24

    /// Button internal padding vertical
    static let buttonPaddingV: CGFloat = 14

    /// Input field internal padding
    static let inputPadding: CGFloat = 14

    /// Screen edge margin
    static let screenMargin: CGFloat = 16

    /// Screen edge margin large
    static let screenMarginLarge: CGFloat = 24

    /// List row spacing
    static let listSpacing: CGFloat = 8

    /// Grid spacing
    static let gridSpacing: CGFloat = 12

    /// Icon-text spacing
    static let iconSpacing: CGFloat = 8

    /// Label-value spacing
    static let labelSpacing: CGFloat = 4

    // MARK: - Height Values

    /// Standard button height
    static let buttonHeight: CGFloat = 56

    /// Compact button height
    static let buttonHeightCompact: CGFloat = 44

    /// Input field height
    static let inputHeight: CGFloat = 52

    /// Navigation bar height
    static let navBarHeight: CGFloat = 56

    /// Tab bar height
    static let tabBarHeight: CGFloat = 64

    /// Avatar sizes
    static let avatarSmall: CGFloat = 32
    static let avatarMedium: CGFloat = 44
    static let avatarLarge: CGFloat = 56
    static let avatarXLarge: CGFloat = 80

    // MARK: - Border Values

    /// Standard border width
    static let borderWidth: CGFloat = 1

    /// Thick border width
    static let borderWidthThick: CGFloat = 2

    /// Focus border width
    static let borderWidthFocus: CGFloat = 2

    /// Pixel border width (double line effect)
    static let pixelBorderWidth: CGFloat = 2
}

// MARK: - EdgeInsets Extensions

extension EdgeInsets {
    /// Standard card padding
    static let studioCard = EdgeInsets(
        top: StudioSpacing.cardPadding,
        leading: StudioSpacing.cardPadding,
        bottom: StudioSpacing.cardPadding,
        trailing: StudioSpacing.cardPadding
    )

    /// Tight card padding
    static let studioCardTight = EdgeInsets(
        top: StudioSpacing.cardPaddingTight,
        leading: StudioSpacing.cardPaddingTight,
        bottom: StudioSpacing.cardPaddingTight,
        trailing: StudioSpacing.cardPaddingTight
    )

    /// Screen edge padding
    static let studioScreen = EdgeInsets(
        top: StudioSpacing.lg,
        leading: StudioSpacing.screenMargin,
        bottom: StudioSpacing.lg,
        trailing: StudioSpacing.screenMargin
    )

    /// Horizontal only
    static func horizontal(_ value: CGFloat) -> EdgeInsets {
        EdgeInsets(top: 0, leading: value, bottom: 0, trailing: value)
    }

    /// Vertical only
    static func vertical(_ value: CGFloat) -> EdgeInsets {
        EdgeInsets(top: value, leading: 0, bottom: value, trailing: 0)
    }
}

// MARK: - View Modifiers

extension View {
    /// Apply standard card padding
    func studioCardPadding() -> some View {
        self.padding(StudioSpacing.cardPadding)
    }

    /// Apply tight card padding
    func studioCardPaddingTight() -> some View {
        self.padding(StudioSpacing.cardPaddingTight)
    }

    /// Apply screen margin padding
    func studioScreenPadding() -> some View {
        self.padding(.horizontal, StudioSpacing.screenMargin)
    }

    /// Apply section spacing
    func studioSectionSpacing() -> some View {
        self.padding(.vertical, StudioSpacing.section)
    }
}

// MARK: - Animation Constants

enum StudioAnimations {
    /// Quick interaction response
    static let quick: Animation = .easeOut(duration: 0.15)

    /// Standard interaction
    static let standard: Animation = .easeInOut(duration: 0.2)

    /// Smooth transitions
    static let smooth: Animation = .easeInOut(duration: 0.3)

    /// Spring animation for bouncy effects
    static let spring: Animation = .spring(response: 0.35, dampingFraction: 0.7)

    /// Gentle spring
    static let gentleSpring: Animation = .spring(response: 0.5, dampingFraction: 0.8)

    /// Pixel-style step animation (snap)
    static let pixelSnap: Animation = .linear(duration: 0.1)

    /// Loading pulse
    static let pulse: Animation = .easeInOut(duration: 0.8).repeatForever(autoreverses: true)

    /// Slow fade
    static let slowFade: Animation = .easeInOut(duration: 0.5)
}

// MARK: - Corner Radius (Pixel = None)

/// Pixel Afterdark uses sharp corners - no radius
enum StudioCorners {
    /// Sharp pixel corners (0)
    static let none: CGFloat = 0

    /// Minimal rounding if absolutely needed
    static let minimal: CGFloat = 2

    /// Small rounding for specific cases
    static let small: CGFloat = 4
}

// MARK: - Shadow Values (Minimal for pixel aesthetic)

enum StudioShadows {
    /// No shadow (pixel aesthetic)
    static let none = Color.clear

    /// Subtle drop shadow
    static let subtle = Color.black.opacity(0.3)

    /// Medium drop shadow
    static let medium = Color.black.opacity(0.5)

    /// Glow effect
    static let glow = Color.studioChrome.opacity(0.2)

    /// Shadow radius
    static let radiusSmall: CGFloat = 4
    static let radiusMedium: CGFloat = 8
    static let radiusLarge: CGFloat = 16
}

// MARK: - Z-Index Values

enum StudioZIndex {
    /// Default layer
    static let base: Double = 0

    /// Elevated content
    static let elevated: Double = 10

    /// Modals and sheets
    static let modal: Double = 100

    /// Overlays
    static let overlay: Double = 500

    /// Toast notifications
    static let toast: Double = 1000

    /// Loading indicators
    static let loading: Double = 1500
}
