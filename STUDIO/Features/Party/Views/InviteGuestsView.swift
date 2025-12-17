//
//  InviteGuestsView.swift
//  STUDIO
//
//  Created by Claude on 12/16/25.
//

import SwiftUI

// MARK: - Invite Guests View

struct InviteGuestsView: View {
    let partyId: UUID
    let onInvitesSent: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""
    @State private var searchResults: [User] = []
    @State private var selectedUsers: Set<UUID> = []
    @State private var isSearching = false
    @State private var isSending = false
    @State private var error: Error?
    @State private var showError = false

    private let partyService = PartyService()
    private let socialService = SocialService()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.studioBlack
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search bar
                    searchBar

                    // Selected users
                    if !selectedUsers.isEmpty {
                        selectedUsersRow
                    }

                    Divider()
                        .background(Color.studioDeepBlack)

                    // Results or suggestions
                    if isSearching {
                        LoadingView(message: "Searching...")
                    } else if searchResults.isEmpty && !searchText.isEmpty {
                        EmptyStateView(
                            icon: "person.fill.questionmark",
                            title: "No Users Found",
                            message: "Try a different search term"
                        )
                    } else {
                        userList
                    }
                }
            }
            .navigationTitle("Invite Guests")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(Color.studioSmoke)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            await sendInvitations()
                        }
                    } label: {
                        if isSending {
                            ProgressView()
                                .tint(Color.studioGold)
                        } else {
                            Text("Send (\(selectedUsers.count))")
                        }
                    }
                    .disabled(selectedUsers.isEmpty || isSending)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { showError = false }
            } message: {
                Text(error?.localizedDescription ?? "An error occurred")
            }
        }
        .tint(Color.studioGold)
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.studioSmoke)

            TextField("Search by username", text: $searchText)
                .foregroundStyle(Color.studioPlatinum)
                .autocapitalization(.none)
                .textInputAutocapitalization(.never)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    searchResults = []
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.studioSmoke)
                }
            }
        }
        .padding()
        .background(Color.studioDeepBlack)
        .onChange(of: searchText) { _, newValue in
            Task {
                await search(query: newValue)
            }
        }
    }

    // MARK: - Selected Users Row

    private var selectedUsersRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(selectedUsers), id: \.self) { userId in
                    if let user = searchResults.first(where: { $0.id == userId }) {
                        selectedUserChip(user: user)
                    }
                }
            }
            .padding()
        }
        .background(Color.studioDeepBlack.opacity(0.5))
    }

    private func selectedUserChip(user: User) -> some View {
        HStack(spacing: 8) {
            AvatarView(url: user.avatarUrl, size: .tiny)

            Text(user.username)
                .font(.subheadline)
                .foregroundStyle(Color.studioPlatinum)

            Button {
                selectedUsers.remove(user.id)
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundStyle(Color.studioSmoke)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.studioDeepBlack)
        .clipShape(Capsule())
    }

    // MARK: - User List

    private var userList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(searchResults) { user in
                    userRow(user: user)
                    Divider()
                        .background(Color.studioDeepBlack)
                }
            }
        }
    }

    private func userRow(user: User) -> some View {
        Button {
            toggleSelection(user: user)
        } label: {
            HStack(spacing: 12) {
                AvatarView(url: user.avatarUrl, size: .medium)

                VStack(alignment: .leading, spacing: 2) {
                    Text(user.displayName ?? user.username)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.studioPlatinum)

                    Text("@\(user.username)")
                        .font(.caption)
                        .foregroundStyle(Color.studioSmoke)
                }

                Spacer()

                // Selection indicator
                Image(systemName: selectedUsers.contains(user.id) ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(
                        selectedUsers.contains(user.id) ? Color.studioGold : Color.studioSmoke
                    )
            }
            .padding()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func toggleSelection(user: User) {
        if selectedUsers.contains(user.id) {
            selectedUsers.remove(user.id)
        } else {
            selectedUsers.insert(user.id)
        }
    }

    private func search(query: String) async {
        guard !query.isEmpty else {
            searchResults = []
            return
        }

        isSearching = true

        do {
            searchResults = try await socialService.searchUsers(query: query)
        } catch {
            self.error = error
            showError = true
        }

        isSearching = false
    }

    private func sendInvitations() async {
        guard !selectedUsers.isEmpty else { return }

        isSending = true

        do {
            for userId in selectedUsers {
                try await partyService.inviteGuest(partyId: partyId, userId: userId)
            }

            onInvitesSent()
            dismiss()
        } catch {
            self.error = error
            showError = true
        }

        isSending = false
    }
}

// MARK: - Preview

#Preview {
    InviteGuestsView(partyId: UUID(), onInvitesSent: {})
}
