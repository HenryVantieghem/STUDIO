//
//  EditProfileView.swift
//  STUDIO
//
//  Pixel Afterdark Design System - 8-bit retro, sharp edges
//

import SwiftUI
import PhotosUI

// MARK: - Edit Profile View

struct EditProfileView: View {
    let user: User
    let onSave: (User) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var displayName: String = ""
    @State private var username: String = ""
    @State private var bio: String = ""
    @State private var avatarUrl: String?
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isSaving = false
    @State private var isCheckingUsername = false
    @State private var usernameAvailable: Bool? = nil
    @State private var error: Error?
    @State private var showError = false

    private let profileService = ProfileService()
    private let storageService = StorageService.shared

    var isValid: Bool {
        !username.isEmpty &&
        username.count >= 3 &&
        (usernameAvailable == true || username == user.username)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.studioBlack
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        // Avatar section
                        avatarSection

                        // Form fields
                        formSection

                        // Save button
                        Button {
                            Task {
                                await saveProfile()
                            }
                        } label: {
                            if isSaving {
                                PixelLoadingIndicator()
                            } else {
                                Text("SAVE CHANGES")
                                    .font(StudioTypography.labelLarge)
                                    .tracking(StudioTypography.trackingWide)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(.studioPrimary)
                        .disabled(!isValid || isSaving)
                    }
                    .padding(24)
                }
            }
            .navigationTitle("EDIT PROFILE")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("CANCEL")
                            .font(StudioTypography.labelSmall)
                            .tracking(StudioTypography.trackingNormal)
                            .foregroundStyle(Color.studioMuted)
                    }
                }
            }
            .alert("ERROR", isPresented: $showError) {
                Button("OK") { showError = false }
            } message: {
                Text(error?.localizedDescription ?? "An error occurred")
            }
            .onAppear {
                displayName = user.displayName ?? ""
                username = user.username
                bio = user.bio ?? ""
                avatarUrl = user.avatarUrl
            }
            .onChange(of: selectedPhoto) { _, newValue in
                Task {
                    await loadSelectedImage(from: newValue)
                }
            }
            .onChange(of: username) { _, newValue in
                Task {
                    await checkUsernameAvailability(newValue)
                }
            }
        }
    }

    // MARK: - Avatar Section

    private var avatarSection: some View {
        VStack(spacing: 16) {
            ZStack {
                if let selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 150, height: 150)
                        .clipShape(Rectangle())
                        .overlay {
                            Rectangle()
                                .stroke(Color.studioChrome, lineWidth: 2)
                        }
                } else {
                    AvatarView(url: avatarUrl, size: .xxlarge, showBorder: true)
                }

                // Camera overlay - pixel style square
                PhotosPicker(selection: $selectedPhoto, matching: .images, photoLibrary: .shared()) {
                    Rectangle()
                        .fill(Color.studioBlack.opacity(0.8))
                        .frame(width: 44, height: 44)
                        .overlay {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 16, weight: .light))
                                .foregroundStyle(Color.studioChrome)
                        }
                        .overlay {
                            Rectangle()
                                .stroke(Color.studioLine, lineWidth: 0.5)
                        }
                }
                .offset(x: 55, y: 55)
            }

            Text("TAP TO CHANGE PHOTO")
                .font(StudioTypography.labelSmall)
                .tracking(StudioTypography.trackingNormal)
                .foregroundStyle(Color.studioMuted)
        }
    }

    // MARK: - Form Section

    private var formSection: some View {
        VStack(spacing: 24) {
            // Display Name
            StudioTextField(
                title: "DISPLAY NAME",
                text: $displayName,
                placeholder: "your name"
            )

            // Username
            VStack(alignment: .leading, spacing: 8) {
                Text("USERNAME")
                    .font(StudioTypography.labelSmall)
                    .tracking(StudioTypography.trackingWide)
                    .foregroundStyle(Color.studioSecondary)

                HStack(spacing: 0) {
                    Text("@")
                        .font(StudioTypography.bodyMedium)
                        .foregroundStyle(Color.studioMuted)
                        .padding(.leading, 16)

                    TextField("", text: $username, prompt: Text("username")
                        .font(StudioTypography.bodyMedium)
                        .foregroundStyle(Color.studioMuted.opacity(0.5)))
                        .font(StudioTypography.bodyMedium)
                        .autocapitalization(.none)
                        .textInputAutocapitalization(.never)
                        .foregroundStyle(Color.studioPrimary)
                        .padding(.vertical, 16)
                        .padding(.trailing, 16)

                    if isCheckingUsername {
                        PixelLoadingIndicator()
                            .padding(.trailing, 16)
                    } else if let available = usernameAvailable {
                        Image(systemName: available ? "checkmark" : "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(available ? Color.studioChrome : Color.studioError)
                            .padding(.trailing, 16)
                    }
                }
                .background(Color.studioSurface)
                .overlay {
                    Rectangle()
                        .stroke(
                            usernameAvailable == false && username != user.username
                                ? Color.studioError
                                : Color.studioLine,
                            lineWidth: 0.5
                        )
                }

                if usernameAvailable == false && username != user.username {
                    Text("USERNAME ALREADY TAKEN")
                        .font(StudioTypography.labelSmall)
                        .tracking(StudioTypography.trackingNormal)
                        .foregroundStyle(Color.studioError)
                }
            }

            // Bio
            StudioTextEditor(
                title: "BIO",
                text: $bio,
                placeholder: "tell us about yourself",
                maxLength: 150
            )
        }
    }

    // MARK: - Actions

    private func loadSelectedImage(from item: PhotosPickerItem?) async {
        guard let item else { return }

        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    selectedImage = image
                }
            }
        } catch {
            self.error = error
            showError = true
        }
    }

    private func checkUsernameAvailability(_ newUsername: String) async {
        // Skip if same as current username
        guard newUsername != user.username else {
            usernameAvailable = true
            return
        }

        // Skip if too short
        guard newUsername.count >= 3 else {
            usernameAvailable = nil
            return
        }

        isCheckingUsername = true

        // Debounce
        try? await Task.sleep(for: .milliseconds(500))

        // Check if this is still the current username
        guard username == newUsername else { return }

        do {
            usernameAvailable = try await profileService.isUsernameAvailable(newUsername)
        } catch {
            usernameAvailable = nil
        }

        isCheckingUsername = false
    }

    private func saveProfile() async {
        isSaving = true

        do {
            var newAvatarUrl: String? = nil

            // Upload new avatar if selected
            if let selectedImage {
                let result = try await storageService.uploadAvatar(image: selectedImage, userId: user.id)
                newAvatarUrl = result.publicUrl
            }

            // Update profile
            let updatedUser = try await profileService.updateProfile(
                displayName: displayName.isEmpty ? nil : displayName,
                username: username,
                bio: bio.isEmpty ? nil : bio,
                avatarUrl: newAvatarUrl
            )

            onSave(updatedUser)
            dismiss()

        } catch {
            self.error = error
            showError = true
        }

        isSaving = false
    }
}

// MARK: - Preview

#Preview {
    EditProfileView(
        user: User(
            id: UUID(),
            username: "studio54",
            displayName: "Studio 54",
            avatarUrl: nil,
            bio: "The legendary nightclub",
            createdAt: Date(),
            updatedAt: Date()
        ),
        onSave: { _ in }
    )
}
