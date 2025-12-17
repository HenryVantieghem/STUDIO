//
//  MicroInteractions.swift
//  STUDIO
//
//  Delightful micro-interactions and polish for production quality
//  Pixel Afterdark Design System
//

import SwiftUI

// MARK: - Interactive Button Style

/// Button that scales and provides haptic feedback
struct InteractiveButtonStyle: ButtonStyle {
    let scale: CGFloat
    let haptic: HapticManager.ImpactStyle?

    init(scale: CGFloat = 0.96, haptic: HapticManager.ImpactStyle? = .light) {
        self.scale = scale
        self.haptic = haptic
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed, let haptic {
                    HapticManager.shared.impact(haptic)
                }
            }
    }
}

extension ButtonStyle where Self == InteractiveButtonStyle {
    static var interactive: InteractiveButtonStyle { InteractiveButtonStyle() }
    static func interactive(scale: CGFloat = 0.96, haptic: HapticManager.ImpactStyle? = .light) -> InteractiveButtonStyle {
        InteractiveButtonStyle(scale: scale, haptic: haptic)
    }
}

// MARK: - Pressable Modifier

/// Makes any view pressable with scale animation
struct PressableModifier: ViewModifier {
    @State private var isPressed = false
    let scale: CGFloat
    var action: (() -> Void)?

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? scale : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            isPressed = true
                            HapticManager.shared.impact(.soft)
                        }
                    }
                    .onEnded { _ in
                        isPressed = false
                        action?()
                    }
            )
    }
}

extension View {
    func pressable(scale: CGFloat = 0.96, action: (() -> Void)? = nil) -> some View {
        modifier(PressableModifier(scale: scale, action: action))
    }
}

// MARK: - Ripple Effect

/// Touch ripple animation
struct RippleEffect: ViewModifier {
    @State private var ripples: [Ripple] = []

    struct Ripple: Identifiable {
        let id = UUID()
        var position: CGPoint
        var scale: CGFloat = 0
        var opacity: Double = 0.5
    }

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { geometry in
                    ZStack {
                        ForEach(ripples) { ripple in
                            Circle()
                                .fill(Color.studioChrome.opacity(ripple.opacity))
                                .frame(width: 100, height: 100)
                                .scaleEffect(ripple.scale)
                                .position(ripple.position)
                        }
                    }
                    .allowsHitTesting(false)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { location in
                createRipple(at: location)
            }
    }

    private func createRipple(at position: CGPoint) {
        var ripple = Ripple(position: position)
        ripples.append(ripple)

        withAnimation(.easeOut(duration: 0.6)) {
            if let index = ripples.firstIndex(where: { $0.id == ripple.id }) {
                ripples[index].scale = 3
                ripples[index].opacity = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            ripples.removeAll { $0.id == ripple.id }
        }
    }
}

extension View {
    func rippleEffect() -> some View {
        modifier(RippleEffect())
    }
}

// MARK: - Success Checkmark Animation

struct SuccessCheckmark: View {
    @State private var showCheck = false
    @State private var showCircle = false

    var body: some View {
        ZStack {
            // Circle
            Circle()
                .stroke(Color.green, lineWidth: 3)
                .frame(width: 80, height: 80)
                .scaleEffect(showCircle ? 1 : 0)
                .opacity(showCircle ? 1 : 0)

            // Checkmark
            Image(systemName: "checkmark")
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(Color.green)
                .scaleEffect(showCheck ? 1 : 0)
                .opacity(showCheck ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                showCircle = true
            }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.2)) {
                showCheck = true
            }
            HapticManager.shared.notification(.success)
        }
    }
}

// MARK: - Loading Dots Animation

struct LoadingDots: View {
    @State private var animating = false
    let color: Color
    let size: CGFloat

    init(color: Color = .studioChrome, size: CGFloat = 8) {
        self.color = color
        self.size = size
    }

    var body: some View {
        HStack(spacing: size * 0.8) {
            ForEach(0..<3, id: \.self) { index in
                Rectangle()
                    .fill(color)
                    .frame(width: size, height: size)
                    .opacity(animating ? 0.3 : 1.0)
                    .animation(
                        .easeInOut(duration: 0.6)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.2),
                        value: animating
                    )
            }
        }
        .onAppear {
            animating = true
        }
    }
}

// MARK: - Skeleton Loading View

struct SkeletonView: View {
    let width: CGFloat?
    let height: CGFloat

    @State private var shimmerOffset: CGFloat = -200

    init(width: CGFloat? = nil, height: CGFloat = 20) {
        self.width = width
        self.height = height
    }

    var body: some View {
        Rectangle()
            .fill(Color.studioSurface)
            .frame(width: width, height: height)
            .overlay {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.studioLine.opacity(0.5),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: shimmerOffset)
            }
            .clipped()
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    shimmerOffset = 400
                }
            }
    }
}

// MARK: - Skeleton Card

struct SkeletonCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Image placeholder
            SkeletonView(height: 180)

            // Title
            SkeletonView(width: 200, height: 20)

            // Subtitle
            SkeletonView(width: 120, height: 14)

            // Stats row
            HStack(spacing: 16) {
                SkeletonView(width: 60, height: 14)
                SkeletonView(width: 60, height: 14)
            }
        }
        .padding(16)
        .background(Color.studioDeepBlack)
        .overlay {
            Rectangle()
                .stroke(Color.studioLine, lineWidth: 1)
        }
    }
}

// MARK: - Pull To Refresh Indicator

struct StudioRefreshIndicator: View {
    let isRefreshing: Bool

    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.studioSurface)
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .light))
                        .foregroundStyle(Color.studioChrome)
                        .rotationEffect(.degrees(rotation))
                }
                .overlay {
                    Rectangle()
                        .stroke(Color.studioLine, lineWidth: 1)
                }
        }
        .onChange(of: isRefreshing) { _, refreshing in
            if refreshing {
                withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            } else {
                rotation = 0
            }
        }
    }
}

// MARK: - Toast Notification

struct ToastView: View {
    let message: String
    let type: ToastType
    @Binding var isShowing: Bool

    enum ToastType {
        case success, error, info

        var icon: String {
            switch self {
            case .success: return "checkmark"
            case .error: return "xmark"
            case .info: return "info"
            }
        }

        var color: Color {
            switch self {
            case .success: return .green
            case .error: return .studioError
            case .info: return .studioChrome
            }
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(type.color.opacity(0.2))
                .frame(width: 32, height: 32)
                .overlay {
                    Image(systemName: type.icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(type.color)
                }

            Text(message.uppercased())
                .font(StudioTypography.labelSmall)
                .tracking(StudioTypography.trackingNormal)
                .foregroundStyle(Color.studioPrimary)

            Spacer()

            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isShowing = false
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .light))
                    .foregroundStyle(Color.studioMuted)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color.studioSurface)
        .overlay {
            Rectangle()
                .stroke(type.color.opacity(0.5), lineWidth: 1)
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

// MARK: - Toast Modifier

struct ToastModifier: ViewModifier {
    @Binding var isShowing: Bool
    let message: String
    let type: ToastView.ToastType
    let duration: Double

    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content

            if isShowing {
                ToastView(message: message, type: type, isShowing: $isShowing)
                    .padding(.horizontal, 16)
                    .padding(.top, 60)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                isShowing = false
                            }
                        }
                    }
            }
        }
    }
}

extension View {
    func toast(isShowing: Binding<Bool>, message: String, type: ToastView.ToastType = .info, duration: Double = 3.0) -> some View {
        modifier(ToastModifier(isShowing: isShowing, message: message, type: type, duration: duration))
    }
}

// MARK: - Number Counter Animation

struct AnimatedCounter: View {
    let value: Int
    let font: Font

    @State private var displayValue: Int = 0

    var body: some View {
        Text("\(displayValue)")
            .font(font)
            .contentTransition(.numericText())
            .onChange(of: value) { _, newValue in
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    displayValue = newValue
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    displayValue = value
                }
            }
    }
}

// MARK: - Swipe Actions Container

struct SwipeActionsView<Content: View>: View {
    @ViewBuilder let content: () -> Content
    var onDelete: (() -> Void)?
    var onEdit: (() -> Void)?

    @State private var offset: CGFloat = 0
    @State private var showActions = false

    var body: some View {
        ZStack(alignment: .trailing) {
            // Actions
            HStack(spacing: 0) {
                if let onEdit {
                    Button {
                        HapticManager.shared.impact(.light)
                        onEdit()
                        resetOffset()
                    } label: {
                        Rectangle()
                            .fill(Color.studioChrome)
                            .frame(width: 80)
                            .overlay {
                                Image(systemName: "pencil")
                                    .font(.system(size: 20, weight: .light))
                                    .foregroundStyle(Color.studioBlack)
                            }
                    }
                    .buttonStyle(.plain)
                }

                if let onDelete {
                    Button {
                        HapticManager.shared.notification(.warning)
                        onDelete()
                        resetOffset()
                    } label: {
                        Rectangle()
                            .fill(Color.studioError)
                            .frame(width: 80)
                            .overlay {
                                Image(systemName: "trash")
                                    .font(.system(size: 20, weight: .light))
                                    .foregroundStyle(Color.studioBlack)
                            }
                    }
                    .buttonStyle(.plain)
                }
            }

            // Content
            content()
                .offset(x: offset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if value.translation.width < 0 {
                                offset = value.translation.width
                            }
                        }
                        .onEnded { value in
                            let actionWidth: CGFloat = (onEdit != nil ? 80 : 0) + (onDelete != nil ? 80 : 0)
                            if -value.translation.width > actionWidth / 2 {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    offset = -actionWidth
                                    showActions = true
                                }
                            } else {
                                resetOffset()
                            }
                        }
                )
        }
    }

    private func resetOffset() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            offset = 0
            showActions = false
        }
    }
}

// MARK: - Confetti Burst

struct ConfettiBurst: View {
    @Binding var isActive: Bool
    @State private var particles: [ConfettiParticle] = []

    struct ConfettiParticle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var rotation: Double
        var color: Color
    }

    private let colors: [Color] = [
        .studioChrome,
        Color(hex: "FFD700"),
        Color(hex: "C0C0C0"),
        .white
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Rectangle()
                        .fill(particle.color)
                        .frame(width: 8, height: 8)
                        .rotationEffect(.degrees(particle.rotation))
                        .position(x: particle.x, y: particle.y)
                }
            }
        }
        .allowsHitTesting(false)
        .onChange(of: isActive) { _, active in
            if active {
                burst()
            }
        }
    }

    private func burst() {
        particles = []

        for _ in 0..<30 {
            let particle = ConfettiParticle(
                x: UIScreen.main.bounds.width / 2,
                y: UIScreen.main.bounds.height / 2,
                rotation: Double.random(in: 0...360),
                color: colors.randomElement()!
            )
            particles.append(particle)
        }

        // Animate outward
        for i in particles.indices {
            let angle = Double.random(in: 0...360) * .pi / 180
            let distance = CGFloat.random(in: 100...300)
            let targetX = particles[i].x + cos(angle) * distance
            let targetY = particles[i].y + sin(angle) * distance

            withAnimation(.easeOut(duration: 1.0)) {
                particles[i].x = targetX
                particles[i].y = targetY
                particles[i].rotation += Double.random(in: -360...360)
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            particles = []
            isActive = false
        }
    }
}

// MARK: - Preview

#Preview("Skeleton Card") {
    ZStack {
        Color.studioBlack.ignoresSafeArea()

        VStack(spacing: 16) {
            SkeletonCard()
            SkeletonCard()
        }
        .padding()
    }
}

#Preview("Loading Dots") {
    ZStack {
        Color.studioBlack.ignoresSafeArea()
        LoadingDots()
    }
}

#Preview("Success Checkmark") {
    ZStack {
        Color.studioBlack.ignoresSafeArea()
        SuccessCheckmark()
    }
}

#Preview("Toast") {
    @Previewable @State var showToast = true

    ZStack {
        Color.studioBlack.ignoresSafeArea()

        Text("CONTENT")
            .foregroundStyle(Color.studioPrimary)
    }
    .toast(isShowing: $showToast, message: "Action completed successfully", type: .success)
}
