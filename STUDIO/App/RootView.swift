//
//  RootView.swift
//  STUDIO
//
//  Basel Afterdark Design System
//  Dark luxury, minimal techno, retro-futuristic nightlife
//

import SwiftUI

/// Root view that handles authentication state routing
struct RootView: View {
    @State private var authVM = AuthViewModel()

    var body: some View {
        Group {
            if authVM.isAuthenticated {
                if authVM.needsOnboarding {
                    StudioOnboardingView {
                        HapticManager.shared.notification(.success)
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            authVM.needsOnboarding = false
                        }
                    }
                    .transition(.opacity)
                } else {
                    MainTabView()
                        .environment(authVM)
                        .transition(.opacity)
                }
            } else {
                AuthView()
                    .environment(authVM)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authVM.isAuthenticated)
        .animation(.easeInOut(duration: 0.3), value: authVM.needsOnboarding)
        .preferredColorScheme(.dark)
        .tint(Color.studioChrome)
    }
}

/// Main tab view for authenticated users
struct MainTabView: View {
    @Environment(AuthViewModel.self) private var authVM
    @State private var selectedTab: Tab = .feed
    @State private var profilePath = NavigationPath()
    @State private var presentedSheet: Sheet?
    @State private var tabBarVisible = true

    var body: some View {
        TabView(selection: $selectedTab) {
            // Feed Tab
            FeedView()
                .tabItem {
                    Label(Tab.feed.title, systemImage: Tab.feed.icon)
                }
                .tag(Tab.feed)

            // Activity Tab
            NavigationStack {
                ActivityView()
                    .navigationDestination(for: Route.self) { route in
                        destinationView(for: route)
                    }
            }
            .tabItem {
                Label(Tab.activity.title, systemImage: Tab.activity.icon)
            }
            .tag(Tab.activity)

            // Profile Tab
            NavigationStack(path: $profilePath) {
                if let currentUser = authVM.currentUser {
                    ProfileView(userId: currentUser.id, isCurrentUser: true)
                        .navigationDestination(for: Route.self) { route in
                            destinationView(for: route)
                        }
                } else {
                    ProfilePlaceholderView()
                        .navigationDestination(for: Route.self) { route in
                            destinationView(for: route)
                        }
                }
            }
            .tabItem {
                Label(Tab.profile.title, systemImage: Tab.profile.icon)
            }
            .tag(Tab.profile)
        }
        .tint(Color.studioChrome)
        .sheet(item: $presentedSheet) { sheet in
            sheetView(for: sheet)
        }
        .onChange(of: selectedTab) { _, _ in
            HapticManager.shared.impact(.light)
        }
    }

    @ViewBuilder
    private func destinationView(for route: Route) -> some View {
        switch route {
        case .partyDetail(let partyId):
            PartyDetailByIdView(partyId: partyId)
        case .userProfile(let userId):
            ProfileView(userId: userId, isCurrentUser: userId == authVM.currentUser?.id)
        case .settings:
            SettingsView()
        case .editProfile:
            EditProfileView()
        case .followers(let userId):
            FollowersFollowingView(userId: userId, initialTab: .followers)
        case .following(let userId):
            FollowersFollowingView(userId: userId, initialTab: .following)
        default:
            ComingSoonView()
        }
    }

    @ViewBuilder
    private func sheetView(for sheet: Sheet) -> some View {
        switch sheet {
        case .createParty:
            CreatePartyView()
        case .camera(let partyId):
            CameraView(partyId: partyId)
        case .photoPicker(let partyId):
            MediaPickerView(partyId: partyId)
        case .createPoll(let partyId):
            CreatePollView(partyId: partyId)
        case .createStatus(let partyId):
            StatusPickerView(partyId: partyId)
        default:
            ComingSoonView()
        }
    }
}

// MARK: - Party Detail By ID View

/// Loads and displays party detail by ID
struct PartyDetailByIdView: View {
    let partyId: UUID
    @State private var party: Party?
    @State private var isLoading = true
    @State private var error: Error?

    var body: some View {
        Group {
            if isLoading {
                LoadingView(message: "LOADING PARTY")
            } else if let party {
                PartyDetailView(party: party)
            } else {
                ErrorView(error: error) {
                    await loadParty()
                }
            }
        }
        .task {
            await loadParty()
        }
    }

    private func loadParty() async {
        isLoading = true
        do {
            let service = PartyService()
            party = try await service.getParty(id: partyId)
        } catch {
            self.error = error
        }
        isLoading = false
    }
}

// MARK: - Coming Soon View

struct ComingSoonView: View {
    var body: some View {
        ZStack {
            Color.studioBlack.ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "sparkles")
                    .font(.system(size: 48, weight: .ultraLight))
                    .foregroundStyle(Color.studioMuted)

                Text("COMING SOON")
                    .font(StudioTypography.headlineMedium)
                    .tracking(StudioTypography.trackingWide)
                    .foregroundStyle(Color.studioPrimary)

                Text("THIS FEATURE IS UNDER CONSTRUCTION")
                    .font(StudioTypography.bodySmall)
                    .tracking(StudioTypography.trackingNormal)
                    .foregroundStyle(Color.studioMuted)
            }
        }
    }
}

// MARK: - Followers/Following View Placeholder

struct FollowersFollowingView: View {
    let userId: UUID
    let initialTab: FollowTab

    enum FollowTab {
        case followers, following
    }

    @State private var selectedTab: FollowTab
    @State private var followers: [User] = []
    @State private var following: [User] = []
    @State private var isLoading = true

    init(userId: UUID, initialTab: FollowTab) {
        self.userId = userId
        self.initialTab = initialTab
        self._selectedTab = State(initialValue: initialTab)
    }

    var body: some View {
        ZStack {
            Color.studioBlack.ignoresSafeArea()

            VStack(spacing: 0) {
                // Tab picker
                HStack(spacing: 0) {
                    tabButton(title: "FOLLOWERS", tab: .followers)
                    tabButton(title: "FOLLOWING", tab: .following)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                if isLoading {
                    Spacer()
                    PixelLoadingIndicator()
                    Spacer()
                } else {
                    let users = selectedTab == .followers ? followers : following

                    if users.isEmpty {
                        Spacer()
                        EmptyStateView(
                            icon: "person.2",
                            title: selectedTab == .followers ? "NO FOLLOWERS" : "NOT FOLLOWING ANYONE",
                            message: selectedTab == .followers ? "BE THE FIRST TO FOLLOW" : "DISCOVER PEOPLE TO FOLLOW"
                        )
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(Array(users.enumerated()), id: \.element.id) { index, user in
                                    UserRowCard(
                                        name: user.displayName ?? user.username,
                                        username: user.username,
                                        avatarUrl: user.avatarUrl
                                    )
                                    .staggeredList(index: index)
                                }
                            }
                            .padding(.top, 16)
                        }
                    }
                }
            }
        }
        .navigationTitle(selectedTab == .followers ? "FOLLOWERS" : "FOLLOWING")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadData()
        }
    }

    private func tabButton(title: String, tab: FollowTab) -> some View {
        Button {
            HapticManager.shared.impact(.light)
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 8) {
                Text(title)
                    .font(StudioTypography.labelSmall)
                    .tracking(StudioTypography.trackingNormal)
                    .foregroundStyle(selectedTab == tab ? Color.studioChrome : Color.studioMuted)

                Rectangle()
                    .fill(Color.studioChrome)
                    .frame(height: 0.5)
                    .opacity(selectedTab == tab ? 1 : 0)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }

    private func loadData() async {
        isLoading = true
        do {
            let service = FollowService()
            followers = try await service.getFollowers(userId: userId)
            following = try await service.getFollowing(userId: userId)
        } catch {
            // Handle silently
        }
        isLoading = false
    }
}

// MARK: - Placeholder Views (to be replaced)

struct FeedPlaceholderView: View {
    var body: some View {
        ZStack {
            Color.studioBlack.ignoresSafeArea()

            VStack(spacing: 32) {
                // Geometric icon
                Rectangle()
                    .fill(Color.studioSurface)
                    .frame(width: 80, height: 80)
                    .overlay {
                        Image(systemName: "square.grid.2x2")
                            .font(.system(size: 32, weight: .ultraLight))
                            .foregroundStyle(Color.studioChrome)
                    }
                    .overlay {
                        Rectangle()
                            .stroke(Color.studioLine, lineWidth: 0.5)
                    }

                Text("STUDIO")
                    .studioDisplayMedium()

                Text("YOUR FEED IS EMPTY")
                    .studioLabelMedium()

                Text("CREATE A PARTY OR WAIT FOR AN INVITE")
                    .font(StudioTypography.bodySmall)
                    .tracking(StudioTypography.trackingNormal)
                    .foregroundStyle(Color.studioMuted)
            }
        }
        .navigationTitle("FEED")
    }
}

struct ActivityPlaceholderView: View {
    var body: some View {
        ZStack {
            Color.studioBlack.ignoresSafeArea()

            VStack(spacing: 24) {
                Rectangle()
                    .fill(Color.studioSurface)
                    .frame(width: 64, height: 64)
                    .overlay {
                        Image(systemName: "bell")
                            .font(.system(size: 28, weight: .ultraLight))
                            .foregroundStyle(Color.studioMuted)
                    }
                    .overlay {
                        Rectangle()
                            .stroke(Color.studioLine, lineWidth: 0.5)
                    }

                Text("NO ACTIVITY YET")
                    .studioLabelMedium()
            }
        }
        .navigationTitle("ACTIVITY")
    }
}

struct ProfilePlaceholderView: View {
    @Environment(AuthViewModel.self) private var authVM

    var body: some View {
        ZStack {
            Color.studioBlack.ignoresSafeArea()

            VStack(spacing: 32) {
                // Avatar placeholder - SQUARE
                Rectangle()
                    .fill(Color.studioSurface)
                    .frame(width: 100, height: 100)
                    .overlay {
                        Image(systemName: "person")
                            .font(.system(size: 40, weight: .ultraLight))
                            .foregroundStyle(Color.studioMuted)
                    }
                    .overlay {
                        Rectangle()
                            .stroke(Color.studioLine, lineWidth: 0.5)
                    }

                // User info
                if let user = authVM.currentUser {
                    VStack(spacing: 8) {
                        Text((user.displayName ?? user.username).uppercased())
                            .studioHeadlineMedium()

                        Text("@\(user.username.uppercased())")
                            .font(StudioTypography.bodySmall)
                            .tracking(StudioTypography.trackingNormal)
                            .foregroundStyle(Color.studioMuted)
                    }
                }

                Spacer().frame(height: 24)

                // Sign out button
                Button {
                    Task {
                        await authVM.signOut()
                    }
                } label: {
                    Text("SIGN OUT")
                        .font(StudioTypography.labelLarge)
                        .tracking(StudioTypography.trackingWide)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                }
                .buttonStyle(.studioSecondary)
                .padding(.horizontal, 48)
            }
            .padding()
        }
        .navigationTitle("PROFILE")
    }
}

#Preview("Root View") {
    RootView()
}
