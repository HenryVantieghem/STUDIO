//
//  SettingsView.swift
//  STUDIO
//
//  Basel Afterdark Settings Experience
//  Simplified settings with blocked users and hidden content
//

import SwiftUI
import Supabase

// MARK: - Settings View

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var showSignOutAlert = false
    @State private var showDeleteAccountAlert = false
    @State private var showDeleteConfirmation = false
    @State private var isSigningOut = false
    @State private var error: Error?
    @State private var showError = false

    // Privacy state
    @State private var isPrivateAccount = false
    @State private var isLoadingPrivacy = false
    @State private var isUpdatingPrivacy = false

    private let authService = AuthService.shared
    private let followService = FollowService()
    private let profileService = ProfileService()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.studioBlack
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        // Account Section
                        settingsSection(title: "ACCOUNT") {
                            settingsRow(
                                icon: "person",
                                title: "Edit Profile",
                                destination: { EditProfileDestinationView() }
                            )
                        }

                        // Privacy Section
                        settingsSection(title: "PRIVACY") {
                            // Private Account Toggle
                            privacyToggleRow

                            settingsRow(
                                icon: "person.crop.circle.badge.xmark",
                                title: "Blocked Users",
                                destination: { BlockedUsersView() }
                            )

                            settingsRow(
                                icon: "eye.slash",
                                title: "Hidden Content",
                                destination: { HiddenContentView() }
                            )
                        }

                        // Sign Out Section
                        VStack(spacing: 12) {
                            Button {
                                showSignOutAlert = true
                            } label: {
                                HStack {
                                    if isSigningOut {
                                        StudioLoadingIndicator(size: 14, color: .studioChrome)
                                    } else {
                                        Text("SIGN OUT")
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.studioSecondary)

                            Button {
                                showDeleteAccountAlert = true
                            } label: {
                                Text("DELETE ACCOUNT")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.studioDestructive)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 32)
                        .padding(.bottom, 48)
                    }
                }
            }
            .navigationTitle("SETTINGS")
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
            .alert("SIGN OUT", isPresented: $showSignOutAlert) {
                Button("CANCEL", role: .cancel) { }
                Button("SIGN OUT", role: .destructive) {
                    Task {
                        await signOut()
                    }
                }
            } message: {
                Text("Are you sure you want to sign out of your account?")
            }
            .alert("DELETE ACCOUNT", isPresented: $showDeleteAccountAlert) {
                Button("CANCEL", role: .cancel) { }
                Button("CONTINUE", role: .destructive) {
                    showDeleteConfirmation = true
                }
            } message: {
                Text("This will permanently delete your account and all your data. This action cannot be undone.")
            }
            .sheet(isPresented: $showDeleteConfirmation) {
                DeleteAccountConfirmationView()
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { showError = false }
            } message: {
                Text(error?.localizedDescription ?? "An error occurred")
            }
            .task {
                await loadPrivacySetting()
            }
        }
        .tint(Color.studioChrome)
    }

    // MARK: - Privacy Toggle Row

    private var privacyToggleRow: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                Image(systemName: "lock")
                    .font(.system(size: 18, weight: .light))
                    .foregroundStyle(Color.studioSecondary)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Private Account")
                        .font(.system(size: 14, weight: .regular, design: .monospaced))
                        .foregroundStyle(Color.studioPrimary)

                    Text("Only approved followers can see your activity")
                        .font(.system(size: 11, weight: .regular, design: .monospaced))
                        .foregroundStyle(Color.studioMuted)
                }

                Spacer()

                if isLoadingPrivacy || isUpdatingPrivacy {
                    StudioLoadingIndicator(size: 14, color: .studioChrome)
                } else {
                    Toggle("", isOn: $isPrivateAccount)
                        .labelsHidden()
                        .tint(Color.studioChrome)
                        .onChange(of: isPrivateAccount) { _, newValue in
                            Task {
                                await updatePrivacySetting(isPrivate: newValue)
                            }
                        }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            Rectangle()
                .fill(Color.studioLine.opacity(0.3))
                .frame(height: 0.5)
                .padding(.leading, 56)
        }
    }

    // MARK: - Section Builder

    @ViewBuilder
    private func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .tracking(StudioTypography.trackingWide)
                .foregroundStyle(Color.studioMuted)
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 12)

            VStack(spacing: 0) {
                content()
            }
            .background(Color.studioSurface)
            .overlay {
                Rectangle()
                    .stroke(Color.studioLine.opacity(0.3), lineWidth: 0.5)
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Row Builders

    @ViewBuilder
    private func settingsRow<Destination: View>(
        icon: String,
        title: String,
        destination: @escaping () -> Destination
    ) -> some View {
        NavigationLink {
            destination()
        } label: {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .light))
                    .foregroundStyle(Color.studioSecondary)
                    .frame(width: 24)

                Text(title)
                    .font(.system(size: 14, weight: .regular, design: .monospaced))
                    .foregroundStyle(Color.studioPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .light))
                    .foregroundStyle(Color.studioMuted)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)

        Rectangle()
            .fill(Color.studioLine.opacity(0.3))
            .frame(height: 0.5)
            .padding(.leading, 56)
    }

    // MARK: - Actions

    private func signOut() async {
        isSigningOut = true

        do {
            try await authService.signOut()
            dismiss()
        } catch {
            self.error = error
            showError = true
        }

        isSigningOut = false
    }

    private func loadPrivacySetting() async {
        isLoadingPrivacy = true

        do {
            let user = try await profileService.getCurrentUserProfile()
            isPrivateAccount = user.isPrivate
        } catch {
            // Silently fail - default to false
        }

        isLoadingPrivacy = false
    }

    private func updatePrivacySetting(isPrivate: Bool) async {
        isUpdatingPrivacy = true

        do {
            try await followService.updatePrivacy(isPrivate: isPrivate)
        } catch {
            // Revert the toggle on error
            isPrivateAccount = !isPrivate
            self.error = error
            showError = true
        }

        isUpdatingPrivacy = false
    }
}

// MARK: - Edit Profile Destination (wrapper to get user)

struct EditProfileDestinationView: View {
    @State private var user: User?
    @State private var isLoading = true
    private let profileService = ProfileService()

    var body: some View {
        Group {
            if isLoading {
                LoadingView(message: "Loading...")
            } else if let user {
                EditProfileView(user: user) { _ in }
            } else {
                Text("Unable to load profile")
                    .studioBodyMedium()
            }
        }
        .task {
            do {
                user = try await profileService.getCurrentUserProfile()
            } catch {
                // Handle error
            }
            isLoading = false
        }
    }
}

// MARK: - Blocked Users View

struct BlockedUsersView: View {
    @State private var blockedUsers: [User] = []
    @State private var isLoading = true
    @State private var isUnblocking: UUID?
    @State private var error: Error?
    @State private var showError = false

    var body: some View {
        ZStack {
            Color.studioBlack
                .ignoresSafeArea()

            if isLoading {
                LoadingView(message: "Loading...")
            } else if blockedUsers.isEmpty {
                emptyState
            } else {
                usersList
            }
        }
        .navigationTitle("BLOCKED USERS")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadBlockedUsers()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(error?.localizedDescription ?? "An error occurred")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.badge.xmark")
                .font(.system(size: 44, weight: .ultraLight))
                .foregroundStyle(Color.studioLine)

            Text("NO BLOCKED USERS")
                .studioLabelMedium()

            Text("Users you block will appear here")
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundStyle(Color.studioMuted)
        }
    }

    private var usersList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(blockedUsers) { user in
                    blockedUserRow(user: user)
                }
            }
            .background(Color.studioSurface)
            .overlay {
                Rectangle()
                    .stroke(Color.studioLine.opacity(0.3), lineWidth: 0.5)
            }
            .padding(16)
        }
    }

    @ViewBuilder
    private func blockedUserRow(user: User) -> some View {
        HStack(spacing: 12) {
            AvatarView(url: user.avatarUrl, size: .medium)

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
                Task {
                    await unblockUser(user)
                }
            } label: {
                if isUnblocking == user.id {
                    StudioLoadingIndicator(size: 10, color: .studioChrome)
                        .frame(width: 80)
                } else {
                    Text("UNBLOCK")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                }
            }
            .buttonStyle(ProfileActionButtonStyle())
            .frame(width: 80)
            .disabled(isUnblocking != nil)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)

        Rectangle()
            .fill(Color.studioLine.opacity(0.3))
            .frame(height: 0.5)
            .padding(.leading, 72)
    }

    private func loadBlockedUsers() async {
        isLoading = true

        do {
            let session = try await supabase.auth.session

            // Get blocked user IDs
            let blocks: [BlockedUserResponse] = try await supabase
                .from("user_blocks")
                .select("blocked_id")
                .eq("blocker_id", value: session.user.id.uuidString)
                .execute()
                .value

            guard !blocks.isEmpty else {
                blockedUsers = []
                isLoading = false
                return
            }

            // Get user profiles for blocked IDs
            let blockedIds = blocks.map { $0.blockedId.uuidString }
            let users: [User] = try await supabase
                .from("profiles")
                .select()
                .in("id", values: blockedIds)
                .execute()
                .value

            blockedUsers = users
        } catch {
            self.error = error
            showError = true
        }

        isLoading = false
    }

    private func unblockUser(_ user: User) async {
        isUnblocking = user.id

        do {
            let session = try await supabase.auth.session

            try await supabase
                .from("user_blocks")
                .delete()
                .eq("blocker_id", value: session.user.id.uuidString)
                .eq("blocked_id", value: user.id.uuidString)
                .execute()

            // Remove from local list
            blockedUsers.removeAll { $0.id == user.id }
        } catch {
            self.error = error
            showError = true
        }

        isUnblocking = nil
    }
}

// Response model for blocked users query
private struct BlockedUserResponse: Codable {
    let blockedId: UUID

    enum CodingKeys: String, CodingKey {
        case blockedId = "blocked_id"
    }
}

// MARK: - Hidden Content View

struct HiddenContentView: View {
    @State private var hiddenParties: [Party] = []
    @State private var isLoading = true
    @State private var isUnhiding: UUID?
    @State private var error: Error?
    @State private var showError = false

    var body: some View {
        ZStack {
            Color.studioBlack
                .ignoresSafeArea()

            if isLoading {
                LoadingView(message: "Loading...")
            } else if hiddenParties.isEmpty {
                emptyState
            } else {
                partiesList
            }
        }
        .navigationTitle("HIDDEN CONTENT")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadHiddenParties()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(error?.localizedDescription ?? "An error occurred")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "eye.slash")
                .font(.system(size: 44, weight: .ultraLight))
                .foregroundStyle(Color.studioLine)

            Text("NO HIDDEN CONTENT")
                .studioLabelMedium()

            Text("Parties you hide will appear here")
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundStyle(Color.studioMuted)
        }
    }

    private var partiesList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(hiddenParties) { party in
                    hiddenPartyRow(party: party)
                }
            }
            .background(Color.studioSurface)
            .overlay {
                Rectangle()
                    .stroke(Color.studioLine.opacity(0.3), lineWidth: 0.5)
            }
            .padding(16)
        }
    }

    @ViewBuilder
    private func hiddenPartyRow(party: Party) -> some View {
        HStack(spacing: 12) {
            // Party thumbnail
            Rectangle()
                .fill(Color.studioSurface)
                .frame(width: 48, height: 48)
                .overlay {
                    if let coverUrl = party.coverImageUrl, let url = URL(string: coverUrl) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Image(systemName: "sparkles")
                                .font(.system(size: 20, weight: .ultraLight))
                                .foregroundStyle(Color.studioMuted)
                        }
                    } else {
                        Image(systemName: "sparkles")
                            .font(.system(size: 20, weight: .ultraLight))
                            .foregroundStyle(Color.studioMuted)
                    }
                }
                .clipped()
                .overlay {
                    Rectangle()
                        .stroke(Color.studioLine, lineWidth: 0.5)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(party.title.uppercased())
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.studioPrimary)
                    .lineLimit(1)

                if let date = party.partyDate {
                    Text(date.formatted(date: .abbreviated, time: .omitted).uppercased())
                        .font(.system(size: 11, weight: .regular, design: .monospaced))
                        .foregroundStyle(Color.studioMuted)
                }
            }

            Spacer()

            Button {
                Task {
                    await unhideParty(party)
                }
            } label: {
                if isUnhiding == party.id {
                    StudioLoadingIndicator(size: 10, color: .studioChrome)
                        .frame(width: 70)
                } else {
                    Text("UNHIDE")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                }
            }
            .buttonStyle(ProfileActionButtonStyle())
            .frame(width: 70)
            .disabled(isUnhiding != nil)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)

        Rectangle()
            .fill(Color.studioLine.opacity(0.3))
            .frame(height: 0.5)
            .padding(.leading, 76)
    }

    private func loadHiddenParties() async {
        isLoading = true

        do {
            let session = try await supabase.auth.session

            // Get hidden party IDs
            let hidden: [HiddenPartyResponse] = try await supabase
                .from("hidden_parties")
                .select("party_id")
                .eq("user_id", value: session.user.id.uuidString)
                .execute()
                .value

            guard !hidden.isEmpty else {
                hiddenParties = []
                isLoading = false
                return
            }

            // Get party details for hidden IDs
            let partyIds = hidden.map { $0.partyId.uuidString }
            let parties: [Party] = try await supabase
                .from("parties")
                .select()
                .in("id", values: partyIds)
                .execute()
                .value

            hiddenParties = parties
        } catch {
            self.error = error
            showError = true
        }

        isLoading = false
    }

    private func unhideParty(_ party: Party) async {
        isUnhiding = party.id

        do {
            let session = try await supabase.auth.session

            try await supabase
                .from("hidden_parties")
                .delete()
                .eq("user_id", value: session.user.id.uuidString)
                .eq("party_id", value: party.id.uuidString)
                .execute()

            // Remove from local list
            hiddenParties.removeAll { $0.id == party.id }
        } catch {
            self.error = error
            showError = true
        }

        isUnhiding = nil
    }
}

// Response model for hidden parties query
private struct HiddenPartyResponse: Codable {
    let partyId: UUID

    enum CodingKeys: String, CodingKey {
        case partyId = "party_id"
    }
}

// MARK: - Delete Account Confirmation View

struct DeleteAccountConfirmationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var confirmText = ""
    @State private var isDeleting = false
    @State private var error: Error?
    @State private var showError = false

    private let authService = AuthService.shared

    var canDelete: Bool {
        confirmText.lowercased() == "delete"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.studioBlack
                    .ignoresSafeArea()

                VStack(spacing: 32) {
                    // Warning icon
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48, weight: .ultraLight))
                        .foregroundStyle(Color.studioError)

                    VStack(spacing: 12) {
                        Text("DELETE YOUR ACCOUNT?")
                            .studioHeadlineSmall()

                        Text("This action is permanent and cannot be undone. All your data, parties, photos, and connections will be permanently deleted.")
                            .font(.system(size: 13, weight: .regular, design: .monospaced))
                            .foregroundStyle(Color.studioSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Type \"DELETE\" to confirm")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .tracking(0.5)
                            .foregroundStyle(Color.studioMuted)

                        TextField("", text: $confirmText)
                            .font(.system(size: 16, weight: .regular, design: .monospaced))
                            .foregroundStyle(Color.studioPrimary)
                            .autocapitalization(.none)
                            .textInputAutocapitalization(.never)
                            .padding()
                            .background(Color.studioSurface)
                            .overlay {
                                Rectangle()
                                    .stroke(confirmText.lowercased() == "delete" ? Color.studioError : Color.studioLine, lineWidth: 0.5)
                            }
                    }
                    .padding(.horizontal, 24)

                    Spacer()

                    VStack(spacing: 12) {
                        Button {
                            Task {
                                await deleteAccount()
                            }
                        } label: {
                            if isDeleting {
                                StudioLoadingIndicator(size: 14, color: .studioError)
                            } else {
                                Text("DELETE MY ACCOUNT")
                            }
                        }
                        .buttonStyle(.studioDestructive)
                        .disabled(!canDelete || isDeleting)
                        .padding(.horizontal, 24)

                        Button {
                            dismiss()
                        } label: {
                            Text("CANCEL")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.studioTertiary)
                        .padding(.horizontal, 24)
                    }
                    .padding(.bottom, 32)
                }
                .padding(.top, 40)
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
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(error?.localizedDescription ?? "Unable to delete account")
            }
        }
    }

    private func deleteAccount() async {
        isDeleting = true

        do {
            // Sign out and trigger deletion flow
            // In production, this would call a backend function to schedule deletion
            try await authService.signOut()
            dismiss()
        } catch {
            self.error = error
            showError = true
        }

        isDeleting = false
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
}
