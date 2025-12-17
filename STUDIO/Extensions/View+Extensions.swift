//
//  View+Extensions.swift
//  STUDIO
//
//  Pixel Afterdark View Extensions
//  8-bit retro modifiers and utilities
//

import SwiftUI

// MARK: - Pixel Font Reference

private let pixelFontName = "VT323"

// MARK: - Pixel Card Modifiers

extension View {
    /// Apply pixel card styling with sharp corners
    func studioCard(padding: CGFloat = 16) -> some View {
        self
            .padding(padding)
            .background(Color.studioSurface)
            .overlay {
                Rectangle()
                    .stroke(Color.studioLine, lineWidth: 2)
            }
    }

    /// Apply pixel border accent
    func pixelBorder(color: Color = .studioLine, lineWidth: CGFloat = 2) -> some View {
        self
            .overlay {
                Rectangle()
                    .stroke(color, lineWidth: lineWidth)
            }
    }

    /// Double pixel border effect
    func doublePixelBorder(color: Color = .studioLine) -> some View {
        self
            .overlay {
                ZStack {
                    Rectangle()
                        .stroke(color, lineWidth: 2)
                    Rectangle()
                        .stroke(color.opacity(0.5), lineWidth: 1)
                        .padding(4)
                }
            }
    }

    /// Hide keyboard
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    /// Apply pixel navigation bar styling
    func studioNavigationBar() -> some View {
        self
            .navigationBarTitleDisplayMode(.inline)
            .tint(.studioPrimary)
    }

    /// Conditional modifier
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Pixel Background Modifier

extension View {
    /// Full screen pixel background
    func pixelBackground() -> some View {
        self
            .background(Color.studioBlack)
            .ignoresSafeArea()
    }
}

// MARK: - Loading Overlay Modifier

struct LoadingOverlay: ViewModifier {
    let isLoading: Bool

    func body(content: Content) -> some View {
        content
            .overlay {
                if isLoading {
                    ZStack {
                        Color.studioBlack.opacity(0.85)
                            .ignoresSafeArea()

                        VStack(spacing: 16) {
                            // Pixel loading indicator
                            PixelLoadingIndicator()

                            Text("LOADING")
                                .font(.custom(pixelFontName, size: 18))
                                .tracking(StudioTypography.trackingStandard)
                                .textCase(.uppercase)
                                .foregroundStyle(Color.studioPrimary)
                        }
                        .padding(24)
                        .background(Color.studioSurface)
                        .overlay {
                            Rectangle()
                                .stroke(Color.studioLine, lineWidth: 2)
                        }
                    }
                }
            }
    }
}

/// Pixel-style loading indicator
struct PixelLoadingIndicator: View {
    @State private var activeIndex = 0
    let timer = Timer.publish(every: 0.15, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<4, id: \.self) { index in
                Rectangle()
                    .fill(index == activeIndex ? Color.studioPrimary : Color.studioMuted)
                    .frame(width: 8, height: 8)
            }
        }
        .onReceive(timer) { _ in
            activeIndex = (activeIndex + 1) % 4
        }
    }
}

extension View {
    func loadingOverlay(_ isLoading: Bool) -> some View {
        modifier(LoadingOverlay(isLoading: isLoading))
    }
}

// MARK: - Pixel Shimmer Effect

struct PixelShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { geo in
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    .clear,
                                    Color.studioPrimary.opacity(0.1),
                                    .clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .offset(x: phase * geo.size.width - geo.size.width)
                }
            }
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 2
                }
            }
    }
}

extension View {
    func pixelShimmer() -> some View {
        modifier(PixelShimmerModifier())
    }
}

// MARK: - Animation Extensions (Pixel-friendly)

extension View {
    /// Scale and fade entrance
    func scaleIn(from scale: CGFloat = 0.9, duration: Double = 0.2) -> some View {
        modifier(ScaleInModifier(startScale: scale, duration: duration))
    }

    /// Slide up entrance
    func slideUp(offset: CGFloat = 30, duration: Double = 0.25) -> some View {
        modifier(SlideUpModifier(offset: offset, duration: duration))
    }

    /// Pixel pulse for attention
    func pixelPulse() -> some View {
        modifier(PixelPulseModifier())
    }

    /// Staggered appearance for lists
    func staggeredAppearance(index: Int, baseDelay: Double = 0.05) -> some View {
        modifier(StaggeredAppearanceModifier(index: index, baseDelay: baseDelay))
    }
}

// MARK: - Animation Modifiers

struct ScaleInModifier: ViewModifier {
    let startScale: CGFloat
    let duration: Double
    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isVisible ? 1 : startScale)
            .opacity(isVisible ? 1 : 0)
            .onAppear {
                withAnimation(.easeOut(duration: duration)) {
                    isVisible = true
                }
            }
    }
}

struct SlideUpModifier: ViewModifier {
    let offset: CGFloat
    let duration: Double
    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .offset(y: isVisible ? 0 : offset)
            .opacity(isVisible ? 1 : 0)
            .onAppear {
                withAnimation(.easeOut(duration: duration)) {
                    isVisible = true
                }
            }
    }
}

struct PixelPulseModifier: ViewModifier {
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .opacity(isPulsing ? 1.0 : 0.6)
            .animation(
                .easeInOut(duration: 0.5)
                .repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
            }
    }
}

struct StaggeredAppearanceModifier: ViewModifier {
    let index: Int
    let baseDelay: Double
    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 15)
            .onAppear {
                withAnimation(.easeOut(duration: 0.3).delay(Double(index) * baseDelay)) {
                    isVisible = true
                }
            }
    }
}

// MARK: - Transition Extensions

extension AnyTransition {
    /// Pixel slide from bottom
    static var pixelSlideUp: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .opacity
        )
    }

    /// Pixel scale entrance
    static var pixelScale: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.9).combined(with: .opacity),
            removal: .opacity
        )
    }
}

// MARK: - Keyboard Dismiss

struct DismissKeyboardOnTap: ViewModifier {
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                TapGesture().onEnded { _ in
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil,
                        from: nil,
                        for: nil
                    )
                }
            )
    }
}

extension View {
    func dismissKeyboardOnTap() -> some View {
        modifier(DismissKeyboardOnTap())
    }
}

// MARK: - Accessibility Extensions

extension View {
    func accessibilityDescribed(label: String, hint: String? = nil) -> some View {
        self
            .accessibilityLabel(label)
            .if(hint != nil) { view in
                view.accessibilityHint(hint!)
            }
    }

    func accessibilityButton(label: String, hint: String? = nil) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityAddTraits(.isButton)
            .if(hint != nil) { view in
                view.accessibilityHint(hint!)
            }
    }

    func accessibilityHeader(_ label: String) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityAddTraits(.isHeader)
    }

    func accessibilityHide() -> some View {
        self.accessibilityHidden(true)
    }
}

// MARK: - Reduced Motion Support

extension View {
    func animationIfAllowed<V: Equatable>(_ animation: Animation?, value: V) -> some View {
        modifier(ReducedMotionAnimationModifier(animation: animation, value: value))
    }
}

struct ReducedMotionAnimationModifier<V: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let animation: Animation?
    let value: V

    func body(content: Content) -> some View {
        content.animation(reduceMotion ? nil : animation, value: value)
    }
}
