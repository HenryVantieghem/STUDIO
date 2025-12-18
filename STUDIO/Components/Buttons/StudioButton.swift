//
//  StudioButton.swift
//  STUDIO
//
//  Pixel Afterdark Button Styles
//  8-bit retro aesthetic with pixel borders
//  ✨ With haptic feedback and interruptible animations
//

import SwiftUI

// MARK: - Pixel Font Reference

private let pixelFontName = "VT323"

// MARK: - Button Sizes (Fixed values - Dynamic Type handled by system)

/// Base sizes for button styling
enum StudioButtonSizes {
    static let primaryFont: CGFloat = 18
    static let secondaryFont: CGFloat = 18
    static let tertiaryFont: CGFloat = 16
    static let ghostFont: CGFloat = 14
    static let pillFont: CGFloat = 14
    static let heroFont: CGFloat = 22
    static let buttonHeight: CGFloat = 48
    static let heroHeight: CGFloat = 56
}

// MARK: - Haptic Button Wrapper

/// Internal wrapper that triggers haptics on press
private struct HapticButtonContent<Content: View>: View {
    let configuration: ButtonStyleConfiguration
    let isEnabled: Bool
    let content: (ButtonStyleConfiguration) -> Content

    var body: some View {
        content(configuration)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed && isEnabled {
                    HapticManager.shared.lightTap()
                }
            }
    }
}

// MARK: - Studio Button Styles

/// Primary button style - Filled with pixel border
struct StudioPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.custom(pixelFontName, size: StudioButtonSizes.primaryFont))
            .tracking(StudioTypography.trackingStandard)
            .textCase(.uppercase)
            .foregroundStyle(isEnabled ? Color.studioBlack : Color.studioMuted)
            .frame(maxWidth: .infinity)
            .frame(minHeight: StudioButtonSizes.buttonHeight)
            .background {
                if isEnabled {
                    Color.studioPrimary
                } else {
                    Color.studioMuted.opacity(0.2)
                }
            }
            .overlay {
                // Pixel border effect - double line
                Rectangle()
                    .stroke(Color.studioBlack, lineWidth: 2)
                    .padding(2)
            }
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed && isEnabled {
                    HapticManager.shared.mediumTap()
                }
            }
    }
}

/// Secondary button style - Bordered pixel style
struct StudioSecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.custom(pixelFontName, size: StudioButtonSizes.secondaryFont))
            .tracking(StudioTypography.trackingStandard)
            .textCase(.uppercase)
            .foregroundStyle(isEnabled ? Color.studioPrimary : Color.studioMuted)
            .frame(maxWidth: .infinity)
            .frame(minHeight: StudioButtonSizes.buttonHeight)
            .background(Color.studioBlack)
            .overlay {
                // Pixel border - single line
                Rectangle()
                    .stroke(
                        isEnabled ? Color.studioPrimary : Color.studioLine,
                        lineWidth: 2
                    )
            }
            .opacity(configuration.isPressed ? 0.6 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed && isEnabled {
                    HapticManager.shared.lightTap()
                }
            }
    }
}

/// Tertiary/text button style - Minimal pixel text
struct StudioTertiaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.custom(pixelFontName, size: StudioButtonSizes.tertiaryFont))
            .tracking(StudioTypography.trackingNormal)
            .textCase(.uppercase)
            .foregroundStyle(isEnabled ? Color.studioSecondary : Color.studioMuted)
            .opacity(configuration.isPressed ? 0.5 : 1.0)
            .animation(.spring(response: 0.15, dampingFraction: 0.8), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed && isEnabled {
                    HapticManager.shared.softTap()
                }
            }
    }
}

/// Ghost button style - Very subtle pixel outline
struct StudioGhostButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.custom(pixelFontName, size: StudioButtonSizes.ghostFont))
            .tracking(StudioTypography.trackingNormal)
            .textCase(.uppercase)
            .foregroundStyle(isEnabled ? Color.studioMuted : Color.studioMuted.opacity(0.5))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.clear)
            .overlay {
                Rectangle()
                    .stroke(Color.studioLine, lineWidth: 1)
            }
            .opacity(configuration.isPressed ? 0.5 : 1.0)
            .animation(.spring(response: 0.15, dampingFraction: 0.8), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed && isEnabled {
                    HapticManager.shared.softTap()
                }
            }
    }
}

/// Pill button style - For filters and tags (pixel style)
struct StudioPillButtonStyle: ButtonStyle {
    var isSelected: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.custom(pixelFontName, size: StudioButtonSizes.pillFont))
            .tracking(StudioTypography.trackingNormal)
            .textCase(.uppercase)
            .foregroundStyle(isSelected ? Color.studioBlack : Color.studioSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? Color.studioPrimary : Color.clear)
            .overlay {
                Rectangle()
                    .stroke(
                        isSelected ? Color.clear : Color.studioLine,
                        lineWidth: 1
                    )
            }
            .opacity(configuration.isPressed ? 0.6 : 1.0)
            .animation(.spring(response: 0.15, dampingFraction: 0.8), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    HapticManager.shared.selectionChanged()
                }
            }
    }
}

/// Icon button style - Square pixel button
struct StudioIconButtonStyle: ButtonStyle {
    var size: CGFloat = 44

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .light))
            .foregroundStyle(Color.studioSecondary)
            .frame(width: size, height: size)
            .background(Color.studioSurface)
            .overlay {
                Rectangle()
                    .stroke(Color.studioLine, lineWidth: 1)
            }
            .opacity(configuration.isPressed ? 0.5 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.15, dampingFraction: 0.7), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    HapticManager.shared.lightTap()
                }
            }
    }
}

/// Destructive button style - Warning pixel style
struct StudioDestructiveButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.custom(pixelFontName, size: StudioButtonSizes.primaryFont))
            .tracking(StudioTypography.trackingStandard)
            .textCase(.uppercase)
            .foregroundStyle(isEnabled ? Color.studioError : Color.studioMuted)
            .frame(maxWidth: .infinity)
            .frame(minHeight: StudioButtonSizes.buttonHeight)
            .background(Color.studioBlack)
            .overlay {
                Rectangle()
                    .stroke(
                        isEnabled ? Color.studioError.opacity(0.6) : Color.studioLine,
                        lineWidth: 2
                    )
            }
            .opacity(configuration.isPressed ? 0.6 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed && isEnabled {
                    HapticManager.shared.warning()
                }
            }
    }
}

/// Large hero button style - For splash/landing screens
struct StudioHeroButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.custom(pixelFontName, size: StudioButtonSizes.heroFont))
            .tracking(StudioTypography.trackingWide)
            .textCase(.uppercase)
            .foregroundStyle(isEnabled ? Color.studioBlack : Color.studioMuted)
            .frame(maxWidth: .infinity)
            .frame(minHeight: StudioButtonSizes.heroHeight)
            .background {
                if isEnabled {
                    Color.studioPrimary
                } else {
                    Color.studioMuted.opacity(0.2)
                }
            }
            .overlay {
                // Double pixel border for hero emphasis
                ZStack {
                    Rectangle()
                        .stroke(Color.studioBlack, lineWidth: 2)
                    Rectangle()
                        .stroke(Color.studioBlack, lineWidth: 1)
                        .padding(4)
                }
            }
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed && isEnabled {
                    HapticManager.shared.heavyTap()
                }
            }
    }
}

// MARK: - ButtonStyle Extensions

extension ButtonStyle where Self == StudioPrimaryButtonStyle {
    static var studioPrimary: StudioPrimaryButtonStyle { StudioPrimaryButtonStyle() }
}

extension ButtonStyle where Self == StudioSecondaryButtonStyle {
    static var studioSecondary: StudioSecondaryButtonStyle { StudioSecondaryButtonStyle() }
}

extension ButtonStyle where Self == StudioTertiaryButtonStyle {
    static var studioTertiary: StudioTertiaryButtonStyle { StudioTertiaryButtonStyle() }
}

extension ButtonStyle where Self == StudioGhostButtonStyle {
    static var studioGhost: StudioGhostButtonStyle { StudioGhostButtonStyle() }
}

extension ButtonStyle where Self == StudioDestructiveButtonStyle {
    static var studioDestructive: StudioDestructiveButtonStyle { StudioDestructiveButtonStyle() }
}

extension ButtonStyle where Self == StudioHeroButtonStyle {
    static var studioHero: StudioHeroButtonStyle { StudioHeroButtonStyle() }
}

// MARK: - Preview

#Preview("Pixel Button Styles") {
    VStack(spacing: 24) {
        Text("BUTTONS")
            .studioLabelSmall()

        Button("ENTER THE PARTY") {}
            .buttonStyle(.studioPrimary)

        Button("GET ON THE LIST") {}
            .buttonStyle(.studioSecondary)

        Button("FORGOT PASSWORD") {}
            .buttonStyle(.studioTertiary)

        Button("CANCEL RSVP") {}
            .buttonStyle(.studioGhost)

        Button("DELETE ACCOUNT") {}
            .buttonStyle(.studioDestructive)

        Button("START YOUR NIGHT") {}
            .buttonStyle(.studioHero)

        Rectangle()
            .fill(Color.studioLine)
            .frame(height: 1)

        Text("FILTERS")
            .studioLabelSmall()

        HStack(spacing: 8) {
            Button("ALL") {}
                .buttonStyle(StudioPillButtonStyle(isSelected: true))

            Button("PHOTOS") {}
                .buttonStyle(StudioPillButtonStyle())

            Button("VIDEOS") {}
                .buttonStyle(StudioPillButtonStyle())
        }

        Rectangle()
            .fill(Color.studioLine)
            .frame(height: 1)

        Text("ICONS")
            .studioLabelSmall()

        HStack(spacing: 12) {
            Button {} label: {
                Image(systemName: "heart")
            }
            .buttonStyle(StudioIconButtonStyle())

            Button {} label: {
                Image(systemName: "bubble.right")
            }
            .buttonStyle(StudioIconButtonStyle())

            Button {} label: {
                Image(systemName: "square.and.arrow.up")
            }
            .buttonStyle(StudioIconButtonStyle())
        }
    }
    .padding(24)
    .background(Color.studioBlack)
}
