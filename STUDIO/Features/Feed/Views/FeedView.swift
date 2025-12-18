//
//  FeedView.swift
//  STUDIO
//
//  Basel Afterdark Design System
//  Dark luxury, minimal techno, retro-futuristic nightlife
//

import SwiftUI

// MARK: - Feed View

struct FeedView: View {
    @State private var vm = FeedViewModel()
    @State private var showCreateParty = false
    @State private var animateHeader = false

    // Social state
    @State private var showActivity = false
    @State private var showSearch = false
    @State private var unreadActivityCount = 0

    private let followService = FollowService()

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.studioBlack.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Pending invitations banner
                    if vm.hasPendingInvitations {
                        invitationsBanner
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // Tab picker
                    tabPicker
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .padding(.bottom, 12)

                    // Content
                    if vm.isLoading && vm.currentTabParties.isEmpty {
                        loadingView
                    } else if vm.currentTabParties.isEmpty {
                        emptyStateView
                    } else {
                        partyList
                    }
                }
            }
            .navigationTitle("STUDIO")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    socialHeaderButtons
                }
                ToolbarItem(placement: .primaryAction) {
                    createPartyButton
                }
            }
            .refreshable {
                await vm.refreshFeed()
            }
            .task {
                await vm.loadFeed()
                await loadUnreadCount()
                withAnimation(.easeOut(duration: 0.8)) {
                    animateHeader = true
                }
            }
            .sheet(isPresented: $showCreateParty) {
                CreatePartyView()
            }
            .sheet(isPresented: $showActivity) {
                ActivityView()
            }
            .sheet(isPresented: $showSearch) {
                SearchUsersView()
            }
            .alert("ERROR", isPresented: $vm.showError) {
                Button("OK") { vm.showError = false }
            } message: {
                Text(vm.error?.localizedDescription ?? "An error occurred")
            }
            .navigationDestination(for: Party.self) { party in
                PartyDetailView(party: party)
            }
        }
        .tint(Color.studioChrome)
    }

    // MARK: - Social Header Buttons

    private var socialHeaderButtons: some View {
        HStack(spacing: 16) {
            // Search button
            Button {
                showSearch = true
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .light))
                    .foregroundStyle(Color.studioPrimary)
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())

            // Activity/Bell button with badge
            Button {
                showActivity = true
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell")
                        .font(.system(size: 16, weight: .light))
                        .foregroundStyle(Color.studioPrimary)

                    // Unread badge
                    if unreadActivityCount > 0 {
                        Rectangle()
                            .fill(Color.studioChrome)
                            .frame(width: 8, height: 8)
                            .offset(x: 4, y: -4)
                    }
                }
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
        }
    }

    // MARK: - Create Party Button (Brutalist)

    private var createPartyButton: some View {
        Button {
            showCreateParty = true
        } label: {
            ZStack {
                // Shadow layer (offset for brutalist depth)
                Rectangle()
                    .fill(Color.studioChrome)
                    .frame(width: 44, height: 44)
                    .offset(x: 3, y: 3)

                // Main button
                Rectangle()
                    .fill(Color.studioBlack)
                    .frame(width: 44, height: 44)
                    .overlay {
                        // Thick border
                        Rectangle()
                            .stroke(Color.studioChrome, lineWidth: 2)
                    }
                    .overlay {
                        // Plus icon
                        VStack(spacing: 0) {
                            Rectangle()
                                .fill(Color.studioChrome)
                                .frame(width: 2, height: 16)

                        }
                        .overlay {
                            Rectangle()
                                .fill(Color.studioChrome)
                                .frame(width: 16, height: 2)
                        }
                    }
            }
            .frame(width: 50, height: 50)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }

    // MARK: - Load Unread Count

    private func loadUnreadCount() async {
        do {
            unreadActivityCount = try await followService.getUnreadCount()
        } catch {
            // Silently fail
        }
    }

    // MARK: - Tab Picker

    private var tabPicker: some View {
        HStack(spacing: 0) {
            ForEach(FeedViewModel.FeedTab.allCases) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        vm.selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 12, weight: .light))
                            Text(tab.rawValue.uppercased())
                                .font(StudioTypography.labelSmall)
                                .tracking(StudioTypography.trackingNormal)
                        }
                        .foregroundStyle(vm.selectedTab == tab ? Color.studioChrome : Color.studioMuted)

                        // Indicator line
                        Rectangle()
                            .fill(Color.studioChrome)
                            .frame(height: 0.5)
                            .opacity(vm.selectedTab == tab ? 1 : 0)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
            }
        }
        .padding(.vertical, 12)
        .background(Color.studioSurface)
        .overlay {
            Rectangle()
                .stroke(Color.studioLine, lineWidth: 0.5)
        }
    }

    // MARK: - Invitations Banner

    private var invitationsBanner: some View {
        Button {
            // Navigate to invitations
        } label: {
            HStack(spacing: 16) {
                Rectangle()
                    .fill(Color.studioSurface)
                    .frame(width: 44, height: 44)
                    .overlay {
                        Image(systemName: "envelope")
                            .font(.system(size: 18, weight: .ultraLight))
                            .foregroundStyle(Color.studioChrome)
                    }
                    .overlay {
                        Rectangle()
                            .stroke(Color.studioLine, lineWidth: 0.5)
                    }

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(vm.pendingInvitations.count) PENDING INVITATION\(vm.pendingInvitations.count == 1 ? "" : "S")")
                        .font(StudioTypography.labelSmall)
                        .tracking(StudioTypography.trackingNormal)
                        .foregroundStyle(Color.studioPrimary)

                    if let firstInvite = vm.pendingInvitations.first,
                       let party = firstInvite.party {
                        Text(party.title.uppercased())
                            .font(StudioTypography.labelSmall)
                            .tracking(StudioTypography.trackingNormal)
                            .foregroundStyle(Color.studioMuted)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .light))
                    .foregroundStyle(Color.studioMuted)
            }
            .padding(16)
            .background(Color.studioSurface)
            .overlay {
                Rectangle()
                    .stroke(Color.studioLine, lineWidth: 0.5)
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 32) {
            Spacer()

            LoadingView(message: "LOADING PARTIES")

            Spacer()
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 24) {
                Image(systemName: vm.selectedTab.icon)
                    .font(.system(size: 48, weight: .ultraLight))
                    .foregroundStyle(Color.studioMuted)

                VStack(spacing: 12) {
                    Text("NO PARTIES YET")
                        .studioHeadlineSmall()

                    Text(vm.emptyStateMessage.uppercased())
                        .font(StudioTypography.bodySmall)
                        .tracking(StudioTypography.trackingNormal)
                        .foregroundStyle(Color.studioMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 48)
                }
            }

            if vm.selectedTab == .active {
                Button {
                    showCreateParty = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .light))
                        Text("START A PARTY")
                            .font(StudioTypography.labelLarge)
                            .tracking(StudioTypography.trackingWide)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                }
                .buttonStyle(.studioPrimary)
                .padding(.horizontal, 48)
                .padding(.top, 8)
            }

            Spacer()
        }
    }

    // MARK: - Party List

    private var partyList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(vm.currentTabParties) { party in
                    VStack(spacing: 0) {
                        // Instagram-style party post
                        PartyPostView(party: party)

                        // Divider between posts
                        Rectangle()
                            .fill(Color.studioLine)
                            .frame(height: 8)
                            .background(Color.studioDeepBlack)
                    }
                }

                // Load more for memories tab
                if vm.selectedTab == .memories && vm.hasPastParties && !vm.useMockData {
                    Button {
                        Task {
                            await vm.loadMorePastParties()
                        }
                    } label: {
                        HStack(spacing: 12) {
                            if vm.isLoadingMore {
                                ProgressView()
                                    .tint(Color.studioChrome)
                            } else {
                                Image(systemName: "arrow.down")
                                    .font(.system(size: 12, weight: .light))
                                Text("LOAD MORE MEMORIES")
                                    .font(StudioTypography.labelMedium)
                                    .tracking(StudioTypography.trackingWide)
                            }
                        }
                        .foregroundStyle(Color.studioChrome)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(Color.studioSurface)
                        .overlay {
                            Rectangle()
                                .stroke(Color.studioLine, lineWidth: 0.5)
                        }
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }

                // Bottom spacing
                Spacer(minLength: 100)
            }
            .padding(.top, 8)
        }
    }
}

// MARK: - Party Card

struct PartyCard: View {
    let party: Party
    let isActive: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with cover image or geometric pattern
            ZStack(alignment: .bottomLeading) {
                // Background
                if let coverUrl = party.coverImageUrl {
                    StudioAsyncImage(url: coverUrl, contentMode: .fill)
                        .frame(height: 200)
                        .clipped()
                } else {
                    // Geometric pattern background
                    ZStack {
                        Color.studioSurface

                        // Grid pattern
                        GeometryReader { geo in
                            Path { path in
                                let spacing: CGFloat = 40
                                for x in stride(from: 0, to: geo.size.width, by: spacing) {
                                    path.move(to: CGPoint(x: x, y: 0))
                                    path.addLine(to: CGPoint(x: x, y: geo.size.height))
                                }
                                for y in stride(from: 0, to: geo.size.height, by: spacing) {
                                    path.move(to: CGPoint(x: 0, y: y))
                                    path.addLine(to: CGPoint(x: geo.size.width, y: y))
                                }
                            }
                            .stroke(Color.studioLine.opacity(0.3), lineWidth: 0.5)
                        }
                    }
                    .frame(height: 200)
                }

                // Overlay gradient for text readability
                LinearGradient(
                    colors: [.clear, Color.studioBlack.opacity(0.9)],
                    startPoint: .center,
                    endPoint: .bottom
                )

                // Live indicator for active parties
                if isActive {
                    HStack(spacing: 8) {
                        Rectangle()
                            .fill(Color.studioChrome)
                            .frame(width: 6, height: 6)

                        Text("LIVE")
                            .font(StudioTypography.labelSmall)
                            .tracking(StudioTypography.trackingWide)
                            .foregroundStyle(Color.studioChrome)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.studioBlack.opacity(0.8))
                    .overlay {
                        Rectangle()
                            .stroke(Color.studioLine, lineWidth: 0.5)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(16)
                }

                // Title and info
                VStack(alignment: .leading, spacing: 8) {
                    Text(party.title.uppercased())
                        .font(StudioTypography.headlineMedium)
                        .tracking(StudioTypography.trackingWide)
                        .foregroundStyle(Color.studioPrimary)
                        .lineLimit(2)

                    HStack(spacing: 16) {
                        if let partyDate = party.partyDate {
                            HStack(spacing: 6) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 10, weight: .light))
                                Text(formatDate(partyDate).uppercased())
                                    .font(StudioTypography.labelSmall)
                                    .tracking(StudioTypography.trackingNormal)
                            }
                            .foregroundStyle(Color.studioSecondary)
                        }

                        if let location = party.location {
                            HStack(spacing: 6) {
                                Image(systemName: "location")
                                    .font(.system(size: 10, weight: .light))
                                Text(location.uppercased())
                                    .font(StudioTypography.labelSmall)
                                    .tracking(StudioTypography.trackingNormal)
                                    .lineLimit(1)
                            }
                            .foregroundStyle(Color.studioSecondary)
                        }
                    }
                }
                .padding(20)
            }

            // Footer
            HStack(spacing: 20) {
                // Hosts avatars - square
                hostsAvatars

                Spacer()

                // Stats
                statsView
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.studioSurface)
        }
        .overlay {
            Rectangle()
                .stroke(Color.studioLine, lineWidth: 0.5)
        }
    }

    private var hostsAvatars: some View {
        HStack(spacing: -8) {
            if let hosts = party.hosts, !hosts.isEmpty {
                ForEach(Array(hosts.prefix(3).enumerated()), id: \.element.id) { index, host in
                    ZStack {
                        Rectangle()
                            .fill(Color.studioBlack)
                            .frame(width: 32, height: 32)

                        if let user = host.user {
                            if let avatarUrl = user.avatarUrl {
                                StudioAsyncImage(url: avatarUrl, contentMode: .fill)
                                    .frame(width: 28, height: 28)
                            } else {
                                Text(user.initials)
                                    .font(StudioTypography.labelSmall)
                                    .foregroundStyle(Color.studioSecondary)
                            }
                        } else {
                            Image(systemName: "person")
                                .font(.system(size: 12, weight: .ultraLight))
                                .foregroundStyle(Color.studioMuted)
                        }
                    }
                    .overlay {
                        Rectangle()
                            .stroke(Color.studioSurface, lineWidth: 2)
                    }
                    .zIndex(Double(3 - index))
                }

                if hosts.count > 3 {
                    ZStack {
                        Rectangle()
                            .fill(Color.studioSurface)
                            .frame(width: 32, height: 32)

                        Text("+\(hosts.count - 3)")
                            .font(StudioTypography.labelSmall)
                            .foregroundStyle(Color.studioMuted)
                    }
                    .overlay {
                        Rectangle()
                            .stroke(Color.studioLine, lineWidth: 0.5)
                    }
                }
            }
        }
    }

    private var statsView: some View {
        HStack(spacing: 20) {
            if let mediaCount = party.mediaCount, mediaCount > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "photo")
                        .font(.system(size: 10, weight: .light))
                    Text("\(mediaCount)")
                        .font(StudioTypography.labelSmall)
                }
                .foregroundStyle(Color.studioMuted)
            }

            if let commentCount = party.commentCount, commentCount > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "bubble.left")
                        .font(.system(size: 10, weight: .light))
                    Text("\(commentCount)")
                        .font(StudioTypography.labelSmall)
                }
                .foregroundStyle(Color.studioMuted)
            }

            // Arrow indicator
            Image(systemName: "arrow.right")
                .font(.system(size: 10, weight: .light))
                .foregroundStyle(Color.studioMuted)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return "Today, " + date.formatted(date: .omitted, time: .shortened)
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow, " + date.formatted(date: .omitted, time: .shortened)
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            return date.formatted(.dateTime.weekday(.wide)) + ", " + date.formatted(date: .omitted, time: .shortened)
        } else {
            return date.formatted(date: .abbreviated, time: .shortened)
        }
    }
}

// MARK: - User Extension

extension User {
    var initials: String {
        let name = displayName ?? username
        let components = name.split(separator: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1) + components[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
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

#Preview("Feed View") {
    FeedView()
}
