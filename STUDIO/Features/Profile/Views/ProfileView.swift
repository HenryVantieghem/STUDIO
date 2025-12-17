//
//  ProfileView.swift
//  STUDIO
//
//  Basel Afterdark Profile Experience
//  Instagram-inspired layout with dark luxury aesthetic
//

import SwiftUI

// MARK: - Profile View

struct ProfileView: View {
    let userId: UUID
    var isCurrentUser: Bool = false

    @Environment(\.dismiss) private var dismiss
    @State private var vm: ProfileViewModel
    @State private var selectedTab: ProfileContentTab = .parties
    @State private var showEditProfile = false
    @State private var showSettings = false
    @State private var showShareProfile = false
    @State private var showFollowers = false
    @State private var showFollowing = false

    init(userId: UUID, isCurrentUser: Bool = false) {
        self.userId = userId
        self.isCurrentUser = isCurrentUser
        _vm = State(initialValue: ProfileViewModel(userId: userId, isCurrentUser: isCurrentUser))
    }

    var body: some View {
        ZStack {
            Color.studioBlack
                .ignoresSafeArea()

            if vm.isLoading && vm.user == nil {
                LoadingView(message: "Loading profile...")
            } else if let user = vm.user {
                ScrollView {
                    VStack(spacing: 0) {
                        // Profile Header
                        profileHeader(user: user)
                            .padding(.horizontal, 24)
                            .padding(.top, 16)

                        // Action Buttons
                        actionButtons
                            .padding(.horizontal, 24)
                            .padding(.top, 20)

                        // Content Tab Bar
                        contentTabBar
                            .padding(.top, 24)

                        // Content Grid
                        contentGrid
                            .padding(.top, 2)
                    }
                    .padding(.bottom, 100)
                }
                .refreshable {
                    await vm.refresh()
                }
            } else {
                EmptyStateView(
                    icon: "person.fill.questionmark",
                    title: "PROFILE NOT FOUND",
                    message: "This user's profile could not be loaded"
                )
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                if let user = vm.user {
                    Text(user.username.uppercased())
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .tracking(StudioTypography.trackingWide)
                        .foregroundStyle(Color.studioPrimary)
                }
            }

            if isCurrentUser {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 18, weight: .light))
                            .foregroundStyle(Color.studioPrimary)
                    }
                }
            }
        }
        .sheet(isPresented: $showEditProfile) {
            if let user = vm.user {
                EditProfileView(user: user) { updatedUser in
                    vm.updateUser(updatedUser)
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showShareProfile) {
            if let user = vm.user {
                ShareProfileSheet(user: user)
            }
        }
        .sheet(isPresented: $showFollowers) {
            FollowersFollowingView(userId: userId, initialTab: .followers)
        }
        .sheet(isPresented: $showFollowing) {
            FollowersFollowingView(userId: userId, initialTab: .following)
        }
        .alert("Error", isPresented: $vm.showError) {
            Button("OK") { vm.showError = false }
        } message: {
            Text(vm.error?.localizedDescription ?? "An error occurred")
        }
        .task {
            await vm.loadProfile()
        }
    }

    // MARK: - Profile Header

    private func profileHeader(user: User) -> some View {
        VStack(spacing: 16) {
            // Top row: Avatar + Stats
            HStack(alignment: .center, spacing: 24) {
                // Avatar with story ring indicator
                ZStack {
                    // Story ring (outer)
                    Circle()
                        .stroke(
                            LinearGradient.studioMetallic,
                            lineWidth: 2
                        )
                        .frame(width: 96, height: 96)

                    // Avatar
                    CircularAvatarView(url: user.avatarUrl, size: .xlarge, showBorder: false)
                }

                // Stats row
                HStack(spacing: 0) {
                    statItem(
                        value: vm.stats.totalParties,
                        label: "PARTIES"
                    )

                    Spacer()

                    Button {
                        showFollowers = true
                    } label: {
                        statItem(
                            value: vm.stats.followersCount,
                            label: "FOLLOWERS"
                        )
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button {
                        showFollowing = true
                    } label: {
                        statItem(
                            value: vm.stats.followingCount,
                            label: "FOLLOWING"
                        )
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity)
            }

            // Name and Bio
            VStack(alignment: .leading, spacing: 6) {
                // Display name
                if let displayName = user.displayName, !displayName.isEmpty {
                    Text(displayName)
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color.studioPrimary)
                }

                // Bio
                if let bio = user.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.system(size: 13, weight: .regular, design: .monospaced))
                        .foregroundStyle(Color.studioSecondary)
                        .lineLimit(3)
                }

                // Achievement badges (if any)
                if !vm.achievements.isEmpty {
                    achievementBadges
                        .padding(.top, 4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func statItem(value: Int, label: String) -> some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.system(size: 18, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.studioPrimary)

            Text(label)
                .font(.system(size: 10, weight: .regular, design: .monospaced))
                .tracking(0.5)
                .foregroundStyle(Color.studioMuted)
        }
    }

    private var achievementBadges: some View {
        HStack(spacing: 8) {
            ForEach(vm.featuredAchievements.prefix(3)) { achievement in
                HStack(spacing: 4) {
                    Image(systemName: achievement.achievementType.icon)
                        .font(.system(size: 10, weight: .light))
                    Text(achievement.achievementType.displayTitle)
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                }
                .foregroundStyle(Color.studioChrome)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.studioSurface)
                .overlay {
                    Rectangle()
                        .stroke(Color.studioLine, lineWidth: 0.5)
                }
            }
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 8) {
            if isCurrentUser {
                // Edit Profile
                Button {
                    showEditProfile = true
                } label: {
                    Text("EDIT PROFILE")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(ProfileActionButtonStyle())

                // Share Profile
                Button {
                    showShareProfile = true
                } label: {
                    Text("SHARE PROFILE")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(ProfileActionButtonStyle())

                // Settings icon
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 14, weight: .light))
                }
                .buttonStyle(ProfileIconButtonStyle())
            } else {
                // Follow/Unfollow
                Button {
                    Task {
                        await vm.toggleFollow()
                    }
                } label: {
                    if vm.isFollowLoading {
                        StudioLoadingIndicator(size: 12, color: vm.isFollowing ? .studioPrimary : .studioBlack)
                    } else {
                        Text(vm.isFollowing ? "FOLLOWING" : "FOLLOW")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(vm.isFollowing ? ProfileActionButtonStyle() : ProfilePrimaryActionButtonStyle())

                // Message
                Button {
                    // Open messages
                } label: {
                    Text("MESSAGE")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(ProfileActionButtonStyle())
            }
        }
    }

    // MARK: - Content Tab Bar

    private var contentTabBar: some View {
        HStack(spacing: 0) {
            ForEach(ProfileContentTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 20, weight: selectedTab == tab ? .regular : .ultraLight))
                            .foregroundStyle(selectedTab == tab ? Color.studioPrimary : Color.studioMuted)

                        // Indicator line
                        Rectangle()
                            .fill(selectedTab == tab ? Color.studioPrimary : Color.clear)
                            .frame(height: 1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
            }
        }
        .background(Color.studioBlack)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.studioLine)
                .frame(height: 0.5)
        }
    }

    // MARK: - Content Grid

    private var contentGrid: some View {
        Group {
            switch selectedTab {
            case .parties:
                partiesGrid
            case .achievements:
                achievementsGrid
            case .tagged:
                taggedMediaGrid
            }
        }
    }

    private var partiesGrid: some View {
        Group {
            if vm.allParties.isEmpty {
                emptyContentView(
                    icon: "square.grid.2x2",
                    title: "NO PARTIES YET",
                    message: isCurrentUser ? "HOST YOUR FIRST PARTY" : "NO PARTIES TO SHOW"
                )
            } else {
                LazyVGrid(columns: gridColumns, spacing: 2) {
                    ForEach(vm.allParties) { party in
                        NavigationLink(value: Route.partyDetail(partyId: party.id)) {
                            PartyGridCell(party: party)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var achievementsGrid: some View {
        Group {
            if vm.achievements.isEmpty {
                emptyContentView(
                    icon: "trophy",
                    title: "NO ACHIEVEMENTS",
                    message: isCurrentUser ? "WIN POLLS TO EARN AWARDS" : "NO ACHIEVEMENTS YET"
                )
            } else {
                LazyVGrid(columns: gridColumns, spacing: 2) {
                    ForEach(vm.achievements) { achievement in
                        AchievementGridCell(achievement: achievement)
                    }
                }
            }
        }
    }

    private var taggedMediaGrid: some View {
        Group {
            if vm.taggedMedia.isEmpty {
                emptyContentView(
                    icon: "person.crop.rectangle",
                    title: "NO TAGGED MEDIA",
                    message: isCurrentUser ? "PHOTOS YOU'RE IN WILL APPEAR HERE" : "NO TAGGED PHOTOS"
                )
            } else {
                LazyVGrid(columns: gridColumns, spacing: 2) {
                    ForEach(vm.taggedMedia) { media in
                        MediaGridCell(media: media)
                    }
                }
            }
        }
    }

    private var gridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 2),
            GridItem(.flexible(), spacing: 2),
            GridItem(.flexible(), spacing: 2)
        ]
    }

    private func emptyContentView(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 44, weight: .ultraLight))
                .foregroundStyle(Color.studioLine)

            Text(title)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .tracking(StudioTypography.trackingWide)
                .foregroundStyle(Color.studioSecondary)

            Text(message)
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .foregroundStyle(Color.studioMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 80)
    }
}

// MARK: - Profile Action Button Style

struct ProfileActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold, design: .monospaced))
            .tracking(0.5)
            .foregroundStyle(Color.studioPrimary)
            .frame(height: 36)
            .background(Color.studioSurface)
            .overlay {
                Rectangle()
                    .stroke(Color.studioLine, lineWidth: 0.5)
            }
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}

struct ProfilePrimaryActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold, design: .monospaced))
            .tracking(0.5)
            .foregroundStyle(Color.studioBlack)
            .frame(height: 36)
            .background(Color.studioChrome)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}

struct ProfileIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Color.studioPrimary)
            .frame(width: 36, height: 36)
            .background(Color.studioSurface)
            .overlay {
                Rectangle()
                    .stroke(Color.studioLine, lineWidth: 0.5)
            }
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}

// MARK: - Grid Cells

struct PartyGridCell: View {
    let party: Party

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background
                Color.studioSurface

                // Cover image
                if let coverUrl = party.coverImageUrl, let url = URL(string: coverUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Color.studioSurface
                    }
                } else {
                    // Placeholder
                    Image(systemName: "sparkles")
                        .font(.system(size: 24, weight: .ultraLight))
                        .foregroundStyle(Color.studioLine)
                }

                // Active indicator
                if party.isActive {
                    VStack {
                        HStack {
                            Spacer()
                            Circle()
                                .fill(Color.studioPrimary)
                                .frame(width: 8, height: 8)
                                .padding(8)
                        }
                        Spacer()
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.width)
            .clipped()
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

struct AchievementGridCell: View {
    let achievement: UserAchievement

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.studioSurface

                VStack(spacing: 8) {
                    Image(systemName: achievement.achievementType.icon)
                        .font(.system(size: 28, weight: .ultraLight))
                        .foregroundStyle(Color.studioChrome)

                    Text(achievement.achievementType.displayTitle)
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .tracking(0.5)
                        .foregroundStyle(Color.studioSecondary)
                        .lineLimit(1)
                }
            }
            .frame(width: geo.size.width, height: geo.size.width)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

struct MediaGridCell: View {
    let media: PartyMedia

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.studioSurface

                if let url = URL(string: media.mediaUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Color.studioSurface
                    }
                }

                // Video indicator
                if media.mediaType == .video {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Image(systemName: "play.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.studioPrimary)
                                .padding(6)
                        }
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.width)
            .clipped()
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

// MARK: - Share Profile Sheet

struct ShareProfileSheet: View {
    let user: User
    @Environment(\.dismiss) private var dismiss

    var profileURL: URL {
        URL(string: "https://studio.app/@\(user.username)")!
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.studioBlack
                    .ignoresSafeArea()

                VStack(spacing: 32) {
                    // QR Code placeholder
                    Rectangle()
                        .fill(Color.studioPrimary)
                        .frame(width: 200, height: 200)
                        .overlay {
                            VStack(spacing: 8) {
                                Image(systemName: "qrcode")
                                    .font(.system(size: 80, weight: .ultraLight))
                                    .foregroundStyle(Color.studioBlack)

                                Text("@\(user.username)")
                                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                                    .foregroundStyle(Color.studioBlack)
                            }
                        }

                    Text("SHARE YOUR PROFILE")
                        .studioHeadlineSmall()

                    // Share options
                    VStack(spacing: 12) {
                        ShareLink(item: profileURL) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 16, weight: .light))
                                Text("SHARE LINK")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(ProfileActionButtonStyle())

                        Button {
                            UIPasteboard.general.string = profileURL.absoluteString
                        } label: {
                            HStack {
                                Image(systemName: "doc.on.doc")
                                    .font(.system(size: 16, weight: .light))
                                Text("COPY LINK")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(ProfileActionButtonStyle())
                    }
                    .padding(.horizontal, 48)

                    Spacer()
                }
                .padding(.top, 40)
            }
            .navigationTitle("SHARE")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .light))
                            .foregroundStyle(Color.studioSecondary)
                    }
                }
            }
        }
    }
}

// MARK: - Followers/Following View

struct FollowersFollowingView: View {
    let userId: UUID
    var initialTab: FollowTab = .followers

    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: FollowTab
    @State private var followers: [User] = []
    @State private var following: [User] = []
    @State private var isLoading = true
    @State private var searchText = ""

    private let profileService = ProfileService()

    init(userId: UUID, initialTab: FollowTab = .followers) {
        self.userId = userId
        self.initialTab = initialTab
        _selectedTab = State(initialValue: initialTab)
    }

    var filteredUsers: [User] {
        let users = selectedTab == .followers ? followers : following
        if searchText.isEmpty {
            return users
        }
        return users.filter {
            $0.username.localizedCaseInsensitiveContains(searchText) ||
            ($0.displayName?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.studioBlack
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Tab selector
                    HStack(spacing: 0) {
                        ForEach(FollowTab.allCases, id: \.self) { tab in
                            Button {
                                withAnimation {
                                    selectedTab = tab
                                }
                            } label: {
                                VStack(spacing: 8) {
                                    Text(tab.title)
                                        .font(.system(size: 14, weight: selectedTab == tab ? .semibold : .regular, design: .monospaced))
                                        .foregroundStyle(selectedTab == tab ? Color.studioPrimary : Color.studioMuted)

                                    Rectangle()
                                        .fill(selectedTab == tab ? Color.studioPrimary : Color.clear)
                                        .frame(height: 1)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(Color.studioLine)
                            .frame(height: 0.5)
                    }

                    // Search bar
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 14, weight: .light))
                            .foregroundStyle(Color.studioMuted)

                        TextField("Search", text: $searchText)
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundStyle(Color.studioPrimary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.studioSurface)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    // Users list
                    if isLoading {
                        Spacer()
                        StudioLoadingIndicator(size: 24)
                        Spacer()
                    } else if filteredUsers.isEmpty {
                        Spacer()
                        Text(searchText.isEmpty ? "NO \(selectedTab.title)" : "NO RESULTS")
                            .studioLabelMedium()
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(filteredUsers) { user in
                                    UserRowView(user: user)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)

                                    Rectangle()
                                        .fill(Color.studioLine.opacity(0.3))
                                        .frame(height: 0.5)
                                        .padding(.leading, 76)
                                }
                            }
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .light))
                            .foregroundStyle(Color.studioSecondary)
                    }
                }
            }
            .task {
                await loadData()
            }
            .onChange(of: selectedTab) { _, _ in
                Task {
                    await loadData()
                }
            }
        }
    }

    private func loadData() async {
        isLoading = true

        do {
            if selectedTab == .followers && followers.isEmpty {
                followers = try await profileService.getFollowers(userId: userId)
            } else if selectedTab == .following && following.isEmpty {
                following = try await profileService.getFollowing(userId: userId)
            }
        } catch {
            // Handle error silently
        }

        isLoading = false
    }
}

enum FollowTab: CaseIterable {
    case followers
    case following

    var title: String {
        switch self {
        case .followers: return "FOLLOWERS"
        case .following: return "FOLLOWING"
        }
    }
}

struct UserRowView: View {
    let user: User
    @State private var isFollowing = false

    var body: some View {
        HStack(spacing: 12) {
            CircularAvatarView(url: user.avatarUrl, size: .medium)

            VStack(alignment: .leading, spacing: 2) {
                Text(user.username)
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.studioPrimary)

                if let displayName = user.displayName {
                    Text(displayName)
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .foregroundStyle(Color.studioMuted)
                }
            }

            Spacer()

            Button {
                isFollowing.toggle()
            } label: {
                Text(isFollowing ? "FOLLOWING" : "FOLLOW")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
            }
            .buttonStyle(isFollowing ? ProfileActionButtonStyle() : ProfilePrimaryActionButtonStyle())
            .frame(width: 90)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ProfileView(userId: UUID(), isCurrentUser: true)
    }
}
