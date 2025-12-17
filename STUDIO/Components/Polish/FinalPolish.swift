//
//  FinalPolish.swift
//  STUDIO
//
//  The 1% details that make the app feel premium
//  Keyboard, accessibility, safe areas, scroll indicators
//  Pixel Afterdark Design System
//

import SwiftUI
import Combine

// MARK: - Keyboard Avoiding View

/// Container that automatically adjusts for keyboard
struct KeyboardAvoidingView<Content: View>: View {
    @ViewBuilder let content: () -> Content

    @State private var keyboardHeight: CGFloat = 0

    var body: some View {
        content()
            .padding(.bottom, keyboardHeight)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: keyboardHeight)
            .onReceive(Publishers.keyboardHeight) { height in
                keyboardHeight = height
            }
    }
}

// MARK: - Keyboard Publisher

extension Publishers {
    static var keyboardHeight: AnyPublisher<CGFloat, Never> {
        let willShow = NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .map { notification -> CGFloat in
                (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height ?? 0
            }

        let willHide = NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .map { _ -> CGFloat in 0 }

        return MergeMany(willShow, willHide)
            .eraseToAnyPublisher()
    }
}

// MARK: - Keyboard Dismiss on Tap

struct KeyboardDismissModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onTapGesture {
                hideKeyboard()
            }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

extension View {
    func dismissKeyboardOnTap() -> some View {
        modifier(KeyboardDismissModifier())
    }
}

// MARK: - Accessibility Helpers

/// Adds comprehensive accessibility support
struct AccessibilityModifier: ViewModifier {
    let label: String
    let hint: String?
    let traits: AccessibilityTraits

    init(label: String, hint: String? = nil, traits: AccessibilityTraits = []) {
        self.label = label
        self.hint = hint
        self.traits = traits
    }

    func body(content: Content) -> some View {
        content
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(traits)
    }
}

extension View {
    func studioAccessibility(
        label: String,
        hint: String? = nil,
        traits: AccessibilityTraits = []
    ) -> some View {
        modifier(AccessibilityModifier(label: label, hint: hint, traits: traits))
    }
}

// MARK: - Safe Area Padding

/// Adds safe area padding that respects dynamic island and home indicator
struct SafeAreaPaddingModifier: ViewModifier {
    let edges: Edge.Set
    let extraPadding: CGFloat

    func body(content: Content) -> some View {
        GeometryReader { geometry in
            content
                .padding(.top, edges.contains(.top) ? geometry.safeAreaInsets.top + extraPadding : 0)
                .padding(.bottom, edges.contains(.bottom) ? geometry.safeAreaInsets.bottom + extraPadding : 0)
                .padding(.leading, edges.contains(.leading) ? geometry.safeAreaInsets.leading + extraPadding : 0)
                .padding(.trailing, edges.contains(.trailing) ? geometry.safeAreaInsets.trailing + extraPadding : 0)
        }
    }
}

extension View {
    func studioSafeAreaPadding(_ edges: Edge.Set = .all, extra: CGFloat = 0) -> some View {
        modifier(SafeAreaPaddingModifier(edges: edges, extraPadding: extra))
    }
}

// MARK: - Styled Scroll View

/// ScrollView with styled indicators and pull-to-refresh
struct StyledScrollView<Content: View>: View {
    let axis: Axis.Set
    let showsIndicators: Bool
    @ViewBuilder let content: () -> Content
    var onRefresh: (() async -> Void)?

    init(
        _ axis: Axis.Set = .vertical,
        showsIndicators: Bool = false,
        onRefresh: (() async -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.axis = axis
        self.showsIndicators = showsIndicators
        self.onRefresh = onRefresh
        self.content = content
    }

    var body: some View {
        ScrollView(axis, showsIndicators: showsIndicators) {
            content()
        }
        .scrollIndicators(.hidden)
        .scrollContentBackground(.hidden)
        .refreshable {
            await onRefresh?()
        }
    }
}

// MARK: - Reduce Motion Support

/// Respects user's reduce motion preference
struct ReduceMotionModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    let animation: Animation
    let reducedAnimation: Animation

    func body(content: Content) -> some View {
        content
            .animation(reduceMotion ? reducedAnimation : animation, value: UUID())
    }
}

extension View {
    func studioAnimation(_ animation: Animation, reduced: Animation = .none) -> some View {
        modifier(ReduceMotionModifier(animation: animation, reducedAnimation: reduced))
    }
}

// MARK: - High Contrast Support

/// Adjusts colors for high contrast mode
struct HighContrastModifier: ViewModifier {
    @Environment(\.accessibilityHighContrast) var highContrast

    func body(content: Content) -> some View {
        content
            .environment(\.colorScheme, .dark)
    }
}

// MARK: - Focus State Helper

/// Custom text field with proper focus handling
struct FocusableTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    var isSecure: Bool = false

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(StudioTypography.labelSmall)
                .tracking(StudioTypography.trackingWide)
                .foregroundStyle(isFocused ? Color.studioChrome : Color.studioMuted)

            Group {
                if isSecure {
                    SecureField("", text: $text, prompt: Text(placeholder)
                        .foregroundStyle(Color.studioMuted.opacity(0.5)))
                } else {
                    TextField("", text: $text, prompt: Text(placeholder)
                        .foregroundStyle(Color.studioMuted.opacity(0.5)))
                }
            }
            .font(StudioTypography.bodyMedium)
            .foregroundStyle(Color.studioPrimary)
            .padding(16)
            .background(Color.studioDeepBlack)
            .overlay {
                Rectangle()
                    .stroke(isFocused ? Color.studioChrome : Color.studioLine, lineWidth: isFocused ? 1 : 0.5)
            }
            .focused($isFocused)
        }
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

// MARK: - Smooth Scroll to Top

/// Button that scrolls to top of content
struct ScrollToTopButton: View {
    let scrollProxy: ScrollViewProxy
    let topID: String

    @State private var isVisible = false

    var body: some View {
        Button {
            HapticManager.shared.impact(.light)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                scrollProxy.scrollTo(topID, anchor: .top)
            }
        } label: {
            Image(systemName: "arrow.up")
                .font(.system(size: 14, weight: .light))
                .foregroundStyle(Color.studioBlack)
                .frame(width: 44, height: 44)
                .background(Color.studioChrome)
                .overlay {
                    Rectangle()
                        .stroke(Color.studioLine, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .opacity(isVisible ? 1 : 0)
        .scaleEffect(isVisible ? 1 : 0.8)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isVisible)
    }

    func show() {
        isVisible = true
    }

    func hide() {
        isVisible = false
    }
}

// MARK: - Scroll Position Tracker

/// Tracks scroll position for showing/hiding elements
struct ScrollPositionTracker: ViewModifier {
    let coordinateSpace: String
    @Binding var offset: CGFloat

    func body(content: Content) -> some View {
        content
            .background {
                GeometryReader { geometry in
                    Color.clear
                        .preference(
                            key: ScrollOffsetPreferenceKey.self,
                            value: geometry.frame(in: .named(coordinateSpace)).minY
                        )
                }
            }
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                offset = value
            }
    }
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

extension View {
    func trackScrollPosition(coordinateSpace: String, offset: Binding<CGFloat>) -> some View {
        modifier(ScrollPositionTracker(coordinateSpace: coordinateSpace, offset: offset))
    }
}

// MARK: - Device Adaptive Layout

/// Adapts layout based on device size class
struct DeviceAdaptiveModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass

    func body(content: Content) -> some View {
        content
    }

    var isCompact: Bool {
        horizontalSizeClass == .compact
    }

    var isLandscape: Bool {
        verticalSizeClass == .compact
    }
}

// MARK: - Haptic on Appear

/// Triggers haptic when view appears
struct HapticOnAppearModifier: ViewModifier {
    let style: HapticManager.ImpactStyle

    func body(content: Content) -> some View {
        content
            .onAppear {
                HapticManager.shared.impact(style)
            }
    }
}

extension View {
    func hapticOnAppear(_ style: HapticManager.ImpactStyle = .light) -> some View {
        modifier(HapticOnAppearModifier(style: style))
    }
}

// MARK: - Prevent Screenshot (for sensitive content)

/// Prevents screenshot of sensitive content
struct PreventScreenshotModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .overlay {
                SecureContainerView()
                    .allowsHitTesting(false)
            }
    }
}

struct SecureContainerView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let secureField = UITextField()
        secureField.isSecureTextEntry = true
        return secureField.subviews.first ?? UIView()
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

extension View {
    func preventScreenshot() -> some View {
        modifier(PreventScreenshotModifier())
    }
}

// MARK: - Status Bar Style

/// Controls status bar appearance
struct StatusBarModifier: ViewModifier {
    let hidden: Bool

    func body(content: Content) -> some View {
        content
            .statusBarHidden(hidden)
    }
}

extension View {
    func studioStatusBar(hidden: Bool = false) -> some View {
        modifier(StatusBarModifier(hidden: hidden))
    }
}

// MARK: - Preview

#Preview("Keyboard Avoiding") {
    KeyboardAvoidingView {
        VStack {
            Spacer()
            FocusableTextField(
                title: "Email",
                text: .constant(""),
                placeholder: "Enter your email"
            )
            .padding()
        }
    }
    .background(Color.studioBlack)
}

#Preview("Styled Scroll") {
    StyledScrollView {
        VStack(spacing: 16) {
            ForEach(0..<20) { i in
                Text("ITEM \(i)")
                    .font(StudioTypography.bodyMedium)
                    .foregroundStyle(Color.studioPrimary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.studioSurface)
            }
        }
        .padding()
    }
    .background(Color.studioBlack)
}
