//
//  VIPExclusivityFeatures.swift
//  STUDIO
//
//  Studio 54 inspired VIP and exclusivity features
//  Velvet rope, VIP tiers, exclusive access
//  Basel Afterdark Design System
//

import SwiftUI

// MARK: - VIP Tier

/// VIP membership tiers inspired by Studio 54
enum VIPTier: String, Codable, CaseIterable, Sendable {
    case regular = "regular"
    case silver = "silver"
    case gold = "gold"
    case platinum = "platinum"
    case legend = "legend"  // Inner circle - like Bianca Jagger level

    var displayName: String {
        switch self {
        case .regular: return "GUEST"
        case .silver: return "SILVER"
        case .gold: return "GOLD"
        case .platinum: return "PLATINUM"
        case .legend: return "LEGEND"
        }
    }

    var color: Color {
        switch self {
        case .regular: return .studioMuted
        case .silver: return Color(red: 0.75, green: 0.75, blue: 0.78)
        case .gold: return Color(red: 1.0, green: 0.84, blue: 0.0)
        case .platinum: return Color(red: 0.9, green: 0.9, blue: 0.95)
        case .legend: return Color(red: 1.0, green: 0.4, blue: 0.6)  // Iconic pink
        }
    }

    var icon: String {
        switch self {
        case .regular: return "person.fill"
        case .silver: return "star"
        case .gold: return "star.fill"
        case .platinum: return "crown"
        case .legend: return "crown.fill"
        }
    }

    var perks: [String] {
        switch self {
        case .regular:
            return ["Access to public parties"]
        case .silver:
            return ["Priority RSVP", "Silver badge", "Early notifications"]
        case .gold:
            return ["VIP room access", "Gold badge", "Skip the line", "Exclusive events"]
        case .platinum:
            return ["Platinum badge", "Host VIP events", "Personal concierge", "Private rooms"]
        case .legend:
            return ["Legend status", "All-access pass", "Inner circle invites", "Lifetime perks"]
        }
    }

    var minXP: Int {
        switch self {
        case .regular: return 0
        case .silver: return 500
        case .gold: return 2000
        case .platinum: return 5000
        case .legend: return 15000
        }
    }
}

// MARK: - VIP Badge View

/// Displays user's VIP tier badge
struct VIPBadgeView: View {
    let tier: VIPTier
    let size: BadgeSize

    enum BadgeSize {
        case small, medium, large

        var iconSize: CGFloat {
            switch self {
            case .small: return 12
            case .medium: return 16
            case .large: return 24
            }
        }

        var fontSize: Font {
            switch self {
            case .small: return StudioTypography.labelSmall
            case .medium: return StudioTypography.labelMedium
            case .large: return StudioTypography.labelLarge
            }
        }

        var padding: EdgeInsets {
            switch self {
            case .small: return EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
            case .medium: return EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
            case .large: return EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
            }
        }
    }

    @State private var isGlowing = false

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: tier.icon)
                .font(.system(size: size.iconSize, weight: .light))

            Text(tier.displayName)
                .font(size.fontSize)
                .tracking(StudioTypography.trackingWide)
        }
        .foregroundStyle(tier == .regular ? Color.studioMuted : tier.color)
        .padding(size.padding)
        .background(tier == .regular ? Color.studioSurface : tier.color.opacity(0.15))
        .overlay {
            Rectangle()
                .stroke(tier.color.opacity(tier == .regular ? 0.3 : 0.6), lineWidth: 1)
        }
        .shadow(color: tier == .regular ? .clear : tier.color.opacity(isGlowing ? 0.5 : 0.2), radius: 8)
        .onAppear {
            if tier != .regular {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    isGlowing = true
                }
            }
        }
    }
}

// MARK: - Velvet Rope Entry

/// Animated velvet rope entry screen
struct VelvetRopeEntryView: View {
    let partyTitle: String
    let isVIP: Bool
    var onEnter: (() -> Void)?

    @State private var ropeOpen = false
    @State private var showContent = false
    @State private var spotlightPosition: CGFloat = 0

    var body: some View {
        ZStack {
            // Dark background
            Color.studioBlack.ignoresSafeArea()

            // Animated spotlight
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(0.1), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .offset(x: spotlightPosition, y: -100)
                .blur(radius: 50)
                .onAppear {
                    withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                        spotlightPosition = 100
                    }
                }

            VStack(spacing: 40) {
                Spacer()

                // Party title
                VStack(spacing: 8) {
                    Text("WELCOME TO")
                        .font(StudioTypography.labelMedium)
                        .tracking(StudioTypography.trackingWide)
                        .foregroundStyle(Color.studioMuted)
                        .opacity(showContent ? 1 : 0)

                    Text(partyTitle.uppercased())
                        .font(StudioTypography.displayLarge)
                        .foregroundStyle(Color.studioPrimary)
                        .opacity(showContent ? 1 : 0)
                        .scaleEffect(showContent ? 1 : 0.8)
                }

                // Velvet rope visual
                VelvetRopeVisual(isOpen: $ropeOpen)
                    .frame(height: 120)

                // VIP badge if applicable
                if isVIP {
                    VIPBadgeView(tier: .gold, size: .large)
                        .opacity(showContent ? 1 : 0)
                }

                // Entry message
                Text(isVIP ? "VIP ACCESS GRANTED" : "YOU'RE ON THE LIST")
                    .font(StudioTypography.labelMedium)
                    .tracking(StudioTypography.trackingWide)
                    .foregroundStyle(Color.studioChrome)
                    .opacity(showContent ? 1 : 0)

                Spacer()

                // Enter button
                Button {
                    HapticManager.shared.notification(.success)
                    onEnter?()
                } label: {
                    Text("ENTER")
                        .font(StudioTypography.labelLarge)
                        .tracking(StudioTypography.trackingWide)
                        .foregroundStyle(Color.studioBlack)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.studioChrome)
                }
                .buttonStyle(.plain)
                .opacity(ropeOpen ? 1 : 0)
                .offset(y: ropeOpen ? 0 : 20)
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            // Sequence the animations
            withAnimation(.easeOut(duration: 0.8)) {
                showContent = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                HapticManager.shared.impact(.medium)
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                    ropeOpen = true
                }
            }
        }
    }
}

// MARK: - Velvet Rope Visual

/// The actual velvet rope component
struct VelvetRopeVisual: View {
    @Binding var isOpen: Bool

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let postWidth: CGFloat = 20
            let postHeight: CGFloat = 100
            let ropeY: CGFloat = 40

            ZStack {
                // Left post
                VStack(spacing: 0) {
                    // Finial (top decoration)
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "FFD700"), Color(hex: "B8860B")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: postWidth + 8, height: postWidth + 8)

                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "FFD700"), Color(hex: "B8860B")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: postWidth, height: postHeight)
                }
                .position(x: 40, y: geometry.size.height / 2)

                // Right post
                VStack(spacing: 0) {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "FFD700"), Color(hex: "B8860B")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: postWidth + 8, height: postWidth + 8)

                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "FFD700"), Color(hex: "B8860B")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: postWidth, height: postHeight)
                }
                .position(x: width - 40, y: geometry.size.height / 2)

                // Velvet rope
                if !isOpen {
                    // Rope when closed
                    RopeShape()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.6, green: 0.1, blue: 0.2),
                                    Color(red: 0.8, green: 0.2, blue: 0.3),
                                    Color(red: 0.6, green: 0.1, blue: 0.2)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: width - 100, height: 30)
                        .position(x: width / 2, y: ropeY)
                        .shadow(color: Color(red: 0.6, green: 0.1, blue: 0.2).opacity(0.5), radius: 4)
                } else {
                    // Left rope drooping when open
                    RopeDropShape()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.6, green: 0.1, blue: 0.2),
                                    Color(red: 0.8, green: 0.2, blue: 0.3)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 50, height: 60)
                        .position(x: 65, y: ropeY + 20)
                        .shadow(color: Color(red: 0.6, green: 0.1, blue: 0.2).opacity(0.5), radius: 4)
                }
            }
        }
    }
}

// MARK: - Rope Shapes

struct RopeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.midY - 10))
        path.addQuadCurve(
            to: CGPoint(x: rect.width, y: rect.midY - 10),
            control: CGPoint(x: rect.midX, y: rect.height)
        )
        return path
    }
}

struct RopeDropShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addQuadCurve(
            to: CGPoint(x: rect.width * 0.3, y: rect.height),
            control: CGPoint(x: rect.width * 0.1, y: rect.height * 0.5)
        )
        return path
    }
}

// MARK: - VIP Perks View

/// Shows VIP tier perks and benefits
struct VIPPerksView: View {
    let tier: VIPTier
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Tier badge
                    VIPBadgeView(tier: tier, size: .large)
                        .padding(.top, 20)

                    // Perks list
                    VStack(alignment: .leading, spacing: 16) {
                        Text("YOUR PERKS")
                            .font(StudioTypography.labelMedium)
                            .tracking(StudioTypography.trackingWide)
                            .foregroundStyle(Color.studioMuted)

                        ForEach(tier.perks, id: \.self) { perk in
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(tier.color)

                                Text(perk.uppercased())
                                    .font(StudioTypography.bodyMedium)
                                    .foregroundStyle(Color.studioPrimary)

                                Spacer()
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(tier.color.opacity(0.1))
                            .overlay {
                                Rectangle()
                                    .stroke(tier.color.opacity(0.3), lineWidth: 1)
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    // Next tier preview
                    if let nextTier = nextTier(from: tier) {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("NEXT TIER: \(nextTier.displayName)")
                                .font(StudioTypography.labelMedium)
                                .tracking(StudioTypography.trackingWide)
                                .foregroundStyle(Color.studioMuted)

                            Text("\(nextTier.minXP - tier.minXP) XP TO UNLOCK")
                                .font(StudioTypography.bodyMedium)
                                .foregroundStyle(nextTier.color)

                            // Progress bar
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(Color.studioSurface)

                                    Rectangle()
                                        .fill(tier.color)
                                        .frame(width: geometry.size.width * 0.6) // Example progress
                                }
                            }
                            .frame(height: 8)
                            .overlay {
                                Rectangle()
                                    .stroke(Color.studioLine, lineWidth: 1)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    }

                    Spacer(minLength: 40)
                }
            }
            .background(Color.studioBlack)
            .navigationTitle("VIP STATUS")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("DONE") {
                        dismiss()
                    }
                    .font(StudioTypography.labelMedium)
                    .foregroundStyle(Color.studioChrome)
                }
            }
        }
    }

    private func nextTier(from current: VIPTier) -> VIPTier? {
        let allTiers = VIPTier.allCases
        guard let currentIndex = allTiers.firstIndex(of: current),
              currentIndex < allTiers.count - 1 else {
            return nil
        }
        return allTiers[currentIndex + 1]
    }
}

// MARK: - Exclusive Party Indicator

/// Shows when a party is exclusive/VIP only
struct ExclusivePartyBadge: View {
    let requiredTier: VIPTier

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "lock.fill")
                .font(.system(size: 10, weight: .light))

            Text(requiredTier.displayName + " ONLY")
                .font(StudioTypography.labelSmall)
                .tracking(StudioTypography.trackingNormal)
        }
        .foregroundStyle(requiredTier.color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(requiredTier.color.opacity(0.15))
        .overlay {
            Rectangle()
                .stroke(requiredTier.color.opacity(0.5), lineWidth: 1)
        }
    }
}

// MARK: - VIP Access Denied View

/// Shown when user doesn't have required VIP tier
struct VIPAccessDeniedView: View {
    let requiredTier: VIPTier
    let currentTier: VIPTier
    var onUpgrade: (() -> Void)?

    @State private var showRope = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Velvet rope closed
            VelvetRopeVisual(isOpen: .constant(false))
                .frame(height: 120)
                .opacity(showRope ? 1 : 0)

            VStack(spacing: 16) {
                Text("VIP ACCESS REQUIRED")
                    .font(StudioTypography.headlineLarge)
                    .foregroundStyle(Color.studioPrimary)

                Text("\(requiredTier.displayName) TIER OR HIGHER")
                    .font(StudioTypography.labelMedium)
                    .tracking(StudioTypography.trackingWide)
                    .foregroundStyle(requiredTier.color)

                Text("Your current tier: \(currentTier.displayName)")
                    .font(StudioTypography.bodyMedium)
                    .foregroundStyle(Color.studioMuted)
                    .padding(.top, 8)
            }

            Spacer()

            // Upgrade button
            if currentTier.minXP < requiredTier.minXP {
                Button {
                    HapticManager.shared.impact(.medium)
                    onUpgrade?()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.up.circle")
                            .font(.system(size: 16, weight: .light))
                        Text("VIEW UPGRADE PATH")
                            .font(StudioTypography.labelLarge)
                            .tracking(StudioTypography.trackingWide)
                    }
                    .foregroundStyle(requiredTier.color)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(requiredTier.color.opacity(0.15))
                    .overlay {
                        Rectangle()
                            .stroke(requiredTier.color.opacity(0.5), lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
            }

            Spacer(minLength: 40)
        }
        .background(Color.studioBlack)
        .onAppear {
            HapticManager.shared.notification(.warning)
            withAnimation(.easeOut(duration: 0.6)) {
                showRope = true
            }
        }
    }
}

// MARK: - Guest List View

/// Animated guest list with VIP sorting
struct GuestListView: View {
    let guests: [PartyGuest]
    @State private var showList = false

    var sortedGuests: [PartyGuest] {
        // Sort by VIP tier (highest first), then alphabetically
        guests.sorted { g1, g2 in
            if let u1 = g1.user, let u2 = g2.user {
                return u1.username < u2.username
            }
            return false
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(sortedGuests.enumerated()), id: \.element.id) { index, guest in
                    GuestListRow(guest: guest)
                        .staggeredList(index: index)
                }
            }
            .padding(.vertical, 8)
        }
        .background(Color.studioBlack)
    }
}

struct GuestListRow: View {
    let guest: PartyGuest

    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            AvatarView(url: guest.user?.avatarUrl.flatMap { URL(string: $0) }, size: .medium)

            VStack(alignment: .leading, spacing: 4) {
                Text(guest.user?.username.uppercased() ?? "GUEST")
                    .font(StudioTypography.labelMedium)
                    .foregroundStyle(Color.studioPrimary)

                Text(guest.status.rawValue.uppercased())
                    .font(StudioTypography.labelSmall)
                    .foregroundStyle(statusColor(guest.status))
            }

            Spacer()

            // VIP indicator (example - would need VIP tier in user model)
            // VIPBadgeView(tier: .gold, size: .small)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.studioSurface.opacity(0.5))
        .overlay {
            Rectangle()
                .stroke(Color.studioLine.opacity(0.5), lineWidth: 0.5)
        }
    }

    private func statusColor(_ status: GuestStatus) -> Color {
        switch status {
        case .accepted: return .green
        case .pending: return .studioMuted
        case .declined: return .studioError
        case .maybe: return .yellow
        }
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Preview

#Preview("VIP Badge") {
    VStack(spacing: 20) {
        ForEach(VIPTier.allCases, id: \.self) { tier in
            VIPBadgeView(tier: tier, size: .medium)
        }
    }
    .padding()
    .background(Color.studioBlack)
}

#Preview("Velvet Rope Entry") {
    VelvetRopeEntryView(partyTitle: "Basel Afterdark", isVIP: true)
}

#Preview("VIP Perks") {
    VIPPerksView(tier: .gold)
}

#Preview("Access Denied") {
    VIPAccessDeniedView(requiredTier: .platinum, currentTier: .silver)
}
