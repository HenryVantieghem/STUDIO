//
//  Color+Extensions.swift
//  STUDIO
//
//  Pixel Afterdark Design System
//  Retro 8-bit × Nightlife × Pure Monochrome
//

import SwiftUI

// MARK: - Pixel Afterdark Color System

extension Color {
    // MARK: - Background Colors

    /// Primary background - pure black (#000000)
    static let studioBlack = Color(red: 0/255, green: 0/255, blue: 0/255)

    /// Surface/elevated background - near black (#0A0A0A)
    static let studioSurface = Color(red: 10/255, green: 10/255, blue: 10/255)

    /// Deep surface for layering (#050505)
    static let studioDeepBlack = Color(red: 5/255, green: 5/255, blue: 5/255)

    // MARK: - Text Colors

    /// Primary text - off-white (#E0E0E0) - matches the flyer
    static let studioPrimary = Color(red: 224/255, green: 224/255, blue: 224/255)

    /// Secondary text - light gray (#B0B0B0)
    static let studioSecondary = Color(red: 176/255, green: 176/255, blue: 176/255)

    /// Muted text - mid gray (#707070)
    static let studioMuted = Color(red: 112/255, green: 112/255, blue: 112/255)

    // MARK: - Accent Colors

    /// Chrome accent - silver (#D0D0D0)
    static let studioChrome = Color(red: 208/255, green: 208/255, blue: 208/255)

    /// Line/border color - dark gray (#2A2A2A)
    static let studioLine = Color(red: 42/255, green: 42/255, blue: 42/255)

    /// Highlight - medium gray (#909090)
    static let studioHighlight = Color(red: 144/255, green: 144/255, blue: 144/255)

    // MARK: - Legacy Compatibility

    static let studioPlatinum: Color = .studioPrimary
    static let studioSmoke: Color = .studioMuted
    static let studioGold: Color = .studioChrome
    static let studioSilver: Color = .studioChrome
    static let studioVelvet = Color(red: 90/255, green: 40/255, blue: 50/255)

    // MARK: - Semantic Colors (Monochrome)

    /// Success - bright white
    static let studioSuccess = Color(red: 240/255, green: 240/255, blue: 240/255)

    /// Warning - chrome
    static let studioWarning = Color(red: 200/255, green: 200/255, blue: 200/255)

    /// Error - warmer gray
    static let studioError = Color(red: 180/255, green: 160/255, blue: 160/255)

    /// Info - primary text
    static let studioInfo: Color = .studioPrimary

    // MARK: - Status Colors (Grayscale Intensity)

    /// Level 1 - Lowest (#3A3A3A)
    static let vibeLevel1 = Color(red: 58/255, green: 58/255, blue: 58/255)

    /// Level 2 - Low (#5A5A5A)
    static let vibeLevel2 = Color(red: 90/255, green: 90/255, blue: 90/255)

    /// Level 3 - Medium (#808080)
    static let vibeLevel3 = Color(red: 128/255, green: 128/255, blue: 128/255)

    /// Level 4 - High (#A8A8A8)
    static let vibeLevel4 = Color(red: 168/255, green: 168/255, blue: 168/255)

    /// Level 5 - Maximum (#E0E0E0)
    static let vibeLevel5: Color = .studioPrimary

    // Legacy vibe colors
    static let vibeChill = vibeLevel1
    static let vibeGroovy = vibeLevel2
    static let vibeElevated = vibeLevel4
    static let vibeGone = vibeLevel5
}

// MARK: - Gradients

extension LinearGradient {
    /// Chrome shimmer gradient
    static let studioMetallic = LinearGradient(
        colors: [
            Color(red: 120/255, green: 120/255, blue: 120/255),
            Color(red: 200/255, green: 200/255, blue: 200/255),
            Color(red: 150/255, green: 150/255, blue: 150/255)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Surface gradient
    static let studioSurfaceGradient = LinearGradient(
        colors: [
            Color(red: 15/255, green: 15/255, blue: 15/255),
            Color(red: 5/255, green: 5/255, blue: 5/255)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Mirror reflection
    static let studioMirror = LinearGradient(
        colors: [
            Color(red: 80/255, green: 80/255, blue: 80/255),
            Color(red: 160/255, green: 160/255, blue: 160/255),
            Color(red: 100/255, green: 100/255, blue: 100/255)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Intensity meter
    static let intensityMeter = LinearGradient(
        colors: [.vibeLevel1, .vibeLevel2, .vibeLevel3, .vibeLevel4, .vibeLevel5],
        startPoint: .leading,
        endPoint: .trailing
    )

    // Legacy
    static let studioGoldShimmer = studioMetallic
    static let drunkMeter = intensityMeter
}

// MARK: - ShapeStyle Extensions

extension ShapeStyle where Self == Color {
    static var studioBackground: Color { .studioBlack }
    static var studioCardBackground: Color { .studioSurface }
    static var studioPrimaryText: Color { .studioPrimary }
    static var studioSecondaryText: Color { .studioSecondary }
    static var studioAccent: Color { .studioChrome }
}
