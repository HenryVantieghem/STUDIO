//
//  SearchUsersView.swift
//  STUDIO
//
//  Pixel Afterdark User Search
//  Instagram-style search for finding people to follow
//

import SwiftUI

// MARK: - Search Users View

struct SearchUsersView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var vm = SearchViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.studioBlack.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search bar
                    searchBar

                    // Content
                    if vm.isSearching {
                        loadingView
                    } else if !vm.searchText.isEmpty && vm.searchResults.isEmpty {
                        noResultsView
                    } else if vm.hasResults {
                        searchResultsList
                    } else if vm.isShowingSuggestions {
                        suggestionsList
                    } else if vm.isLoadingSuggestions {
                        loadingView
                    } else {
                        emptyView
                    }
                }
            }
            .navigationTitle("SEARCH")
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
                await vm.loadSuggestions()
            }
            .alert("ERROR", isPresented: $vm.showError) {
                Button("OK") { vm.showError = false }
            } message: {
                Text(vm.error?.localizedDescription ?? "An error occurred")
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .light))
                .foregroundStyle(Color.studioMuted)

            TextField("", text: $vm.searchText, prompt: Text("SEARCH USERS").foregroundStyle(Color.studioMuted))
                .font(StudioTypography.bodyLarge)
                .tracking(StudioTypography.trackingNormal)
                .foregroundStyle(Color.studioPrimary)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .onChange(of: vm.searchText) { _, _ in
                    Task {
                        await vm.search()
                    }
                }

            if !vm.searchText.isEmpty {
                Button {
                    vm.clearSearch()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14, weight: .light))
                        .foregroundStyle(Color.studioMuted)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.studioSurface)
        .overlay {
            Rectangle()
                .stroke(Color.studioLine, lineWidth: 1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack {
            Spacer()
            StudioLoadingIndicator(size: 20)
            Spacer()
        }
    }

    // MARK: - Empty View

    private var emptyView: some View {
        VStack(spacing: 24) {
            Spacer()

            Rectangle()
                .fill(Color.studioSurface)
                .frame(width: 64, height: 64)
                .overlay {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 28, weight: .ultraLight))
                        .foregroundStyle(Color.studioMuted)
                }
                .overlay {
                    Rectangle()
                        .stroke(Color.studioLine, lineWidth: 1)
                }

            Text("FIND PEOPLE")
                .studioHeadlineSmall()

            Text("SEARCH BY USERNAME")
                .studioLabelSmall()

            Spacer()
        }
    }

    // MARK: - No Results View

    private var noResultsView: some View {
        VStack(spacing: 24) {
            Spacer()

            Rectangle()
                .fill(Color.studioSurface)
                .frame(width: 64, height: 64)
                .overlay {
                    Image(systemName: "person.slash")
                        .font(.system(size: 28, weight: .ultraLight))
                        .foregroundStyle(Color.studioMuted)
                }
                .overlay {
                    Rectangle()
                        .stroke(Color.studioLine, lineWidth: 1)
                }

            Text("NO RESULTS")
                .studioHeadlineSmall()

            Text("TRY A DIFFERENT SEARCH")
                .studioLabelSmall()

            Spacer()
        }
    }

    // MARK: - Search Results List

    private var searchResultsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(vm.searchResults) { result in
                    SearchUserRowView(
                        user: result.user,
                        isFollowing: result.isFollowing,
                        onFollowTap: {
                            Task {
                                await vm.toggleFollow(user: result)
                            }
                        }
                    )

                    Rectangle()
                        .fill(Color.studioLine.opacity(0.3))
                        .frame(height: 1)
                        .padding(.leading, 72)
                }
            }
            .padding(.bottom, 100)
        }
    }

    // MARK: - Suggestions List

    private var suggestionsList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                Text("SUGGESTED FOR YOU")
                    .font(StudioTypography.labelSmall)
                    .tracking(StudioTypography.trackingWide)
                    .foregroundStyle(Color.studioMuted)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                LazyVStack(spacing: 0) {
                    ForEach(vm.suggestedUsers) { result in
                        SearchUserRowView(
                            user: result.user,
                            isFollowing: result.isFollowing,
                            onFollowTap: {
                                Task {
                                    await vm.toggleFollow(user: result)
                                }
                            }
                        )

                        Rectangle()
                            .fill(Color.studioLine.opacity(0.3))
                            .frame(height: 1)
                            .padding(.leading, 72)
                    }
                }
            }
            .padding(.bottom, 100)
        }
    }
}

// MARK: - Search User Row View

struct SearchUserRowView: View {
    let user: User
    var isFollowing: Bool
    var onFollowTap: () -> Void
    @State private var isLoadingFollow = false

    var body: some View {
        NavigationLink(value: Route.userProfile(userId: user.id)) {
            HStack(spacing: 12) {
                // Avatar
                AvatarView(url: user.avatarUrl, size: .medium)

                // User info
                VStack(alignment: .leading, spacing: 2) {
                    Text(user.username.uppercased())
                        .font(StudioTypography.labelLarge)
                        .tracking(StudioTypography.trackingStandard)
                        .foregroundStyle(Color.studioPrimary)

                    if let displayName = user.displayName, !displayName.isEmpty {
                        Text(displayName.uppercased())
                            .font(StudioTypography.labelSmall)
                            .tracking(StudioTypography.trackingNormal)
                            .foregroundStyle(Color.studioMuted)
                    }

                    if user.isPrivate {
                        HStack(spacing: 4) {
                            Image(systemName: "lock")
                                .font(.system(size: 8, weight: .light))
                            Text("PRIVATE")
                                .font(StudioTypography.labelSmall)
                        }
                        .foregroundStyle(Color.studioMuted)
                    }
                }

                Spacer()

                // Follow button
                Button {
                    isLoadingFollow = true
                    onFollowTap()
                    // Reset loading after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isLoadingFollow = false
                    }
                } label: {
                    if isLoadingFollow {
                        StudioLoadingIndicator(
                            size: 10,
                            color: isFollowing ? .studioPrimary : .studioBlack
                        )
                        .frame(width: 80, height: 28)
                    } else {
                        Text(isFollowing ? "FOLLOWING" : "FOLLOW")
                            .font(StudioTypography.labelSmall)
                            .tracking(StudioTypography.trackingStandard)
                            .foregroundStyle(isFollowing ? Color.studioPrimary : Color.studioBlack)
                            .frame(width: 80, height: 28)
                    }
                }
                .background(isFollowing ? Color.studioSurface : Color.studioChrome)
                .overlay {
                    Rectangle()
                        .stroke(isFollowing ? Color.studioLine : Color.clear, lineWidth: 1)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
}

// MARK: - Preview

#Preview("Search Users") {
    SearchUsersView()
}
