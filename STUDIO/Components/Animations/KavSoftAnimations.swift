//
//  KavSoftAnimations.swift
//  STUDIO
//
//  Kavsoft-inspired premium SwiftUI animations
//  Hero transitions, parallax scroll, card flips, morphing effects
//  Basel Afterdark Design System
//

import SwiftUI

// MARK: - Hero Animation Namespace

/// Shared namespace for hero animations across the app
struct HeroAnimationNamespace {
    static let shared = Namespace().wrappedValue
}

// MARK: - Hero Card View

/// Card that expands into a full detail view with matched geometry
struct HeroPartyCard: View {
    let party: Party
    let namespace: Namespace.ID
    @Binding var selectedParty: Party?

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                selectedParty = party
            }
            HapticManager.shared.impact(.medium)
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                // Cover image
                ZStack {
                    Rectangle()
                        .fill(Color.studioSurface)

                    if let coverUrl = party.coverImageUrl,
                       let url = URL(string: coverUrl) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            PixelLoadingIndicator()
                        }
                    } else {
                        Image(systemName: "sparkles")
                            .font(.system(size: 40, weight: .ultraLight))
                            .foregroundStyle(Color.studioMuted)
                    }
                }
                .frame(height: 180)
                .clipped()
                .matchedGeometryEffect(id: "cover-\(party.id)", in: namespace)

                VStack(alignment: .leading, spacing: 8) {
                    Text(party.title.uppercased())
                        .font(StudioTypography.headlineMedium)
                        .foregroundStyle(Color.studioPrimary)
                        .matchedGeometryEffect(id: "title-\(party.id)", in: namespace)

                    if let date = party.partyDate {
                        Text(date.formatted(.dateTime.month().day().hour().minute()))
                            .font(StudioTypography.labelSmall)
                            .foregroundStyle(Color.studioMuted)
                            .matchedGeometryEffect(id: "date-\(party.id)", in: namespace)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .background(Color.studioDeepBlack)
            .overlay {
                Rectangle()
                    .stroke(Color.studioLine, lineWidth: 1)
            }
            .matchedGeometryEffect(id: "card-\(party.id)", in: namespace)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Hero Detail View

/// Expanded detail view for hero animation
struct HeroPartyDetailView: View {
    let party: Party
    let namespace: Namespace.ID
    @Binding var selectedParty: Party?
    @State private var contentOpacity: Double = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Hero image
                ZStack(alignment: .topLeading) {
                    Rectangle()
                        .fill(Color.studioSurface)

                    if let coverUrl = party.coverImageUrl,
                       let url = URL(string: coverUrl) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            PixelLoadingIndicator()
                        }
                    }

                    // Gradient overlay
                    LinearGradient(
                        colors: [.clear, Color.studioBlack],
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    // Close button
                    Button {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            selectedParty = nil
                        }
                        HapticManager.shared.impact(.light)
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .light))
                            .foregroundStyle(Color.studioPrimary)
                            .frame(width: 40, height: 40)
                            .background(Color.studioBlack.opacity(0.8))
                            .overlay {
                                Rectangle()
                                    .stroke(Color.studioLine, lineWidth: 1)
                            }
                    }
                    .padding()
                    .opacity(contentOpacity)
                }
                .frame(height: 350)
                .clipped()
                .matchedGeometryEffect(id: "cover-\(party.id)", in: namespace)

                // Content
                VStack(alignment: .leading, spacing: 16) {
                    Text(party.title.uppercased())
                        .font(StudioTypography.displayMedium)
                        .foregroundStyle(Color.studioPrimary)
                        .matchedGeometryEffect(id: "title-\(party.id)", in: namespace)

                    if let date = party.partyDate {
                        Text(date.formatted(.dateTime.month().day().hour().minute()))
                            .font(StudioTypography.labelMedium)
                            .foregroundStyle(Color.studioMuted)
                            .matchedGeometryEffect(id: "date-\(party.id)", in: namespace)
                    }

                    if let description = party.description {
                        Text(description)
                            .font(StudioTypography.bodyMedium)
                            .foregroundStyle(Color.studioSecondary)
                            .opacity(contentOpacity)
                    }

                    // Additional content
                    VStack(spacing: 16) {
                        HStack(spacing: 16) {
                            StatCard(title: "GUESTS", value: "\(party.guests?.count ?? 0)", icon: "person.2")
                            StatCard(title: "HOSTS", value: "\(party.hosts?.count ?? 0)", icon: "star")
                        }

                        Button("ENTER PARTY") {
                            HapticManager.shared.impact(.medium)
                        }
                        .buttonStyle(.studioPrimary)
                    }
                    .opacity(contentOpacity)
                    .padding(.top, 16)
                }
                .padding(20)
            }
        }
        .background(Color.studioBlack)
        .matchedGeometryEffect(id: "card-\(party.id)", in: namespace)
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeOut(duration: 0.3).delay(0.2)) {
                contentOpacity = 1
            }
        }
    }
}

// MARK: - Parallax Scroll Effect

/// Parallax header that scales and fades with scroll
struct ParallaxHeader<Content: View>: View {
    let height: CGFloat
    let multiplier: CGFloat
    @ViewBuilder let content: () -> Content

    init(
        height: CGFloat = 300,
        multiplier: CGFloat = 0.5,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.height = height
        self.multiplier = multiplier
        self.content = content
    }

    var body: some View {
        GeometryReader { geometry in
            let minY = geometry.frame(in: .global).minY
            let scrollOffset = minY > 0 ? -minY : 0
            let parallaxOffset = minY > 0 ? minY * multiplier : 0

            content()
                .frame(
                    width: geometry.size.width,
                    height: height + (minY > 0 ? minY : 0)
                )
                .offset(y: parallaxOffset + scrollOffset)
                .opacity(1 - Double(-scrollOffset) / 200)
        }
        .frame(height: height)
    }
}

// MARK: - Scroll Linked Animation

/// View modifier that animates based on scroll position
struct ScrollLinkedAnimation: ViewModifier {
    let threshold: CGFloat
    let animation: Animation

    @State private var isVisible = false

    func body(content: Content) -> some View {
        GeometryReader { geometry in
            let minY = geometry.frame(in: .global).minY
            let screenHeight = UIScreen.main.bounds.height
            let shouldShow = minY < screenHeight - threshold

            content
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 30)
                .onChange(of: shouldShow) { _, newValue in
                    withAnimation(animation) {
                        isVisible = newValue
                    }
                }
                .onAppear {
                    if shouldShow {
                        withAnimation(animation) {
                            isVisible = true
                        }
                    }
                }
        }
    }
}

extension View {
    func scrollLinkedAnimation(threshold: CGFloat = 100) -> some View {
        modifier(ScrollLinkedAnimation(
            threshold: threshold,
            animation: .spring(response: 0.5, dampingFraction: 0.8)
        ))
    }
}

// MARK: - Card Flip Animation

/// Flippable card with 3D rotation
struct FlippableCard<Front: View, Back: View>: View {
    @Binding var isFlipped: Bool
    @ViewBuilder let front: () -> Front
    @ViewBuilder let back: () -> Back

    var body: some View {
        ZStack {
            front()
                .rotation3DEffect(
                    .degrees(isFlipped ? 180 : 0),
                    axis: (x: 0, y: 1, z: 0),
                    perspective: 0.5
                )
                .opacity(isFlipped ? 0 : 1)

            back()
                .rotation3DEffect(
                    .degrees(isFlipped ? 0 : -180),
                    axis: (x: 0, y: 1, z: 0),
                    perspective: 0.5
                )
                .opacity(isFlipped ? 1 : 0)
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isFlipped.toggle()
            }
            HapticManager.shared.impact(.light)
        }
    }
}

// MARK: - Morphing Shape Animation

/// Animated shape that morphs between states
struct MorphingShape: View {
    let progress: CGFloat
    let color: Color

    var body: some View {
        Canvas { context, size in
            let rect = CGRect(origin: .zero, size: size)
            let path = createMorphingPath(in: rect, progress: progress)

            context.fill(path, with: .color(color))
        }
    }

    private func createMorphingPath(in rect: CGRect, progress: CGFloat) -> Path {
        var path = Path()

        let cornerRadius = interpolate(from: 0, to: rect.width / 2, progress: progress)

        path.addRoundedRect(
            in: rect,
            cornerSize: CGSize(width: cornerRadius, height: cornerRadius)
        )

        return path
    }

    private func interpolate(from: CGFloat, to: CGFloat, progress: CGFloat) -> CGFloat {
        from + (to - from) * progress
    }
}

// MARK: - Elastic Button

/// Button with elastic press animation
struct ElasticButton<Label: View>: View {
    let action: () -> Void
    @ViewBuilder let label: () -> Label

    @State private var isPressed = false

    var body: some View {
        label()
            .scaleEffect(isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
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
                        action()
                        HapticManager.shared.impact(.light)
                    }
            )
    }
}

// MARK: - Staggered List Animation

/// Animates list items with staggered delay
struct StaggeredListModifier: ViewModifier {
    let index: Int
    let baseDelay: Double

    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 20)
            .onAppear {
                withAnimation(
                    .spring(response: 0.5, dampingFraction: 0.8)
                    .delay(Double(index) * baseDelay)
                ) {
                    isVisible = true
                }
            }
    }
}

extension View {
    func staggeredList(index: Int, baseDelay: Double = 0.05) -> some View {
        modifier(StaggeredListModifier(index: index, baseDelay: baseDelay))
    }
}

// MARK: - Bounce Animation

/// Adds bouncy entrance animation
struct BounceInModifier: ViewModifier {
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0

    let delay: Double

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(
                    .spring(response: 0.6, dampingFraction: 0.6)
                    .delay(delay)
                ) {
                    scale = 1.0
                    opacity = 1.0
                }
            }
    }
}

extension View {
    func bounceIn(delay: Double = 0) -> some View {
        modifier(BounceInModifier(delay: delay))
    }
}

// MARK: - Shake Animation

/// Shake animation for errors or attention
struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX:
            amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)),
            y: 0))
    }
}

extension View {
    func shake(trigger: Bool) -> some View {
        modifier(ShakeModifier(trigger: trigger))
    }
}

struct ShakeModifier: ViewModifier {
    let trigger: Bool
    @State private var shakeAmount: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .modifier(ShakeEffect(animatableData: shakeAmount))
            .onChange(of: trigger) { _, _ in
                withAnimation(.linear(duration: 0.5)) {
                    shakeAmount = 1
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    shakeAmount = 0
                }
            }
    }
}

// MARK: - Pulse Animation

/// Continuous pulse for drawing attention
struct PulseModifier: ViewModifier {
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.05 : 1.0)
            .opacity(isPulsing ? 1.0 : 0.8)
            .animation(
                .easeInOut(duration: 1.0)
                .repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
            }
    }
}

extension View {
    func pulse() -> some View {
        modifier(PulseModifier())
    }
}

// MARK: - Typewriter Effect

/// Animates text appearing character by character
struct TypewriterText: View {
    let text: String
    let speed: Double

    @State private var displayedText = ""
    @State private var currentIndex = 0

    init(_ text: String, speed: Double = 0.05) {
        self.text = text
        self.speed = speed
    }

    var body: some View {
        Text(displayedText)
            .onAppear {
                animateText()
            }
    }

    private func animateText() {
        displayedText = ""
        currentIndex = 0

        Timer.scheduledTimer(withTimeInterval: speed, repeats: true) { timer in
            if currentIndex < text.count {
                let index = text.index(text.startIndex, offsetBy: currentIndex)
                displayedText += String(text[index])
                currentIndex += 1
            } else {
                timer.invalidate()
            }
        }
    }
}

// MARK: - Slide In Directions

enum SlideDirection {
    case leading, trailing, top, bottom

    var offset: CGSize {
        switch self {
        case .leading: return CGSize(width: -50, height: 0)
        case .trailing: return CGSize(width: 50, height: 0)
        case .top: return CGSize(width: 0, height: -50)
        case .bottom: return CGSize(width: 0, height: 50)
        }
    }
}

struct SlideInModifier: ViewModifier {
    let direction: SlideDirection
    let delay: Double

    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(isVisible ? .zero : direction.offset)
            .onAppear {
                withAnimation(
                    .spring(response: 0.5, dampingFraction: 0.8)
                    .delay(delay)
                ) {
                    isVisible = true
                }
            }
    }
}

extension View {
    func slideIn(from direction: SlideDirection, delay: Double = 0) -> some View {
        modifier(SlideInModifier(direction: direction, delay: delay))
    }
}

// MARK: - Glow Animation

/// Animated glow effect
struct GlowModifier: ViewModifier {
    let color: Color
    let radius: CGFloat

    @State private var isGlowing = false

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(isGlowing ? 0.8 : 0.3), radius: radius)
            .animation(
                .easeInOut(duration: 1.5)
                .repeatForever(autoreverses: true),
                value: isGlowing
            )
            .onAppear {
                isGlowing = true
            }
    }
}

extension View {
    func animatedGlow(color: Color = .studioChrome, radius: CGFloat = 10) -> some View {
        modifier(GlowModifier(color: color, radius: radius))
    }
}

// MARK: - Preview

#Preview("Hero Card") {
    @Previewable @Namespace var namespace
    @Previewable @State var selectedParty: Party?

    ZStack {
        Color.studioBlack.ignoresSafeArea()

        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(0..<5) { i in
                    let party = Party(
                        id: UUID(),
                        title: "Party \(i + 1)",
                        description: "An amazing party"
                    )

                    HeroPartyCard(
                        party: party,
                        namespace: namespace,
                        selectedParty: $selectedParty
                    )
                    .staggeredList(index: i)
                }
            }
            .padding()
        }

        if let party = selectedParty {
            HeroPartyDetailView(
                party: party,
                namespace: namespace,
                selectedParty: $selectedParty
            )
        }
    }
}

#Preview("Parallax Header") {
    ScrollView {
        VStack(spacing: 0) {
            ParallaxHeader(height: 300) {
                ZStack {
                    Color.studioSurface
                    Image(systemName: "sparkles")
                        .font(.system(size: 60, weight: .ultraLight))
                        .foregroundStyle(Color.studioMuted)
                }
            }

            VStack(spacing: 16) {
                ForEach(0..<10) { i in
                    Text("CONTENT ROW \(i + 1)")
                        .font(StudioTypography.bodyMedium)
                        .foregroundStyle(Color.studioPrimary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.studioSurface)
                        .scrollLinkedAnimation()
                }
            }
            .padding()
        }
    }
    .background(Color.studioBlack)
}

#Preview("Card Flip") {
    @Previewable @State var isFlipped = false

    ZStack {
        Color.studioBlack.ignoresSafeArea()

        FlippableCard(isFlipped: $isFlipped) {
            // Front
            VStack {
                Text("TAP TO FLIP")
                    .font(StudioTypography.headlineMedium)
                    .foregroundStyle(Color.studioPrimary)
            }
            .frame(width: 200, height: 280)
            .background(Color.studioSurface)
            .overlay {
                Rectangle()
                    .stroke(Color.studioLine, lineWidth: 1)
            }
        } back: {
            // Back
            VStack {
                Text("BACK SIDE")
                    .font(StudioTypography.headlineMedium)
                    .foregroundStyle(Color.studioBlack)
            }
            .frame(width: 200, height: 280)
            .background(Color.studioChrome)
        }
    }
}

#Preview("Elastic Button") {
    ZStack {
        Color.studioBlack.ignoresSafeArea()

        ElasticButton {
            print("Tapped!")
        } label: {
            Text("PRESS ME")
                .font(StudioTypography.labelLarge)
                .foregroundStyle(Color.studioBlack)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(Color.studioChrome)
        }
    }
}

#Preview("Typewriter") {
    ZStack {
        Color.studioBlack.ignoresSafeArea()

        TypewriterText("WELCOME TO STUDIO 54...")
            .font(StudioTypography.headlineLarge)
            .foregroundStyle(Color.studioPrimary)
    }
}
