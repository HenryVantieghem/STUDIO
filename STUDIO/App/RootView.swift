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
                    PermissionsOnboardingView {
                        authVM.needsOnboarding = false
                    }
                } else {
                    MainTabView()
                        .environment(authVM)
                }
            } else {
                AuthView()
                    .environment(authVM)
            }
        }
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

    var body: some View {
        TabView(selection: $selectedTab) {
            // Feed Tab
            FeedView()
                .tabItem {
                    Label(Tab.feed.title, systemImage: Tab.feed.icon)
                }
                .tag(Tab.feed)

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
        .sheet(item: $presentedSheet) { sheet in
            sheetView(for: sheet)
        }
    }

    @ViewBuilder
    private func destinationView(for route: Route) -> some View {
        switch route {
        case .partyDetail(let partyId):
            Text("PARTY DETAIL: \(partyId.uuidString)")
                .studioBodyMedium()
        case .userProfile(let userId):
            ProfileView(userId: userId, isCurrentUser: userId == authVM.currentUser?.id)
        case .settings:
            SettingsView()
        default:
            Text("COMING SOON")
                .studioBodyMedium()
        }
    }

    @ViewBuilder
    private func sheetView(for sheet: Sheet) -> some View {
        switch sheet {
        case .createParty:
            CreatePartyView()
        default:
            Text("SHEET")
                .studioBodyMedium()
        }
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
