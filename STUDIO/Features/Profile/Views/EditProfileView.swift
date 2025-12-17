//
//  EditProfileView.swift
//  STUDIO
//
//  Created by Claude on 12/16/25.
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
                                ProgressView()
                                    .tint(Color.studioBlack)
                            } else {
                                Text("Save Changes")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(.glassProminent)
                        .disabled(!isValid || isSaving)
                    }
                    .padding()
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(Color.studioSmoke)
                }
            }
            .alert("Error", isPresented: $showError) {
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
        .tint(Color.studioGold)
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
                        .clipShape(Circle())
                        .overlay {
                            Circle()
                                .stroke(Color.studioGold, lineWidth: 3)
                        }
                } else {
                    AvatarView(url: avatarUrl, size: .xxlarge, showBorder: true)
                }

                // Camera overlay
                PhotosPicker(selection: $selectedPhoto, matching: .images, photoLibrary: .shared()) {
                    Circle()
                        .fill(Color.studioDeepBlack.opacity(0.7))
                        .frame(width: 44, height: 44)
                        .overlay {
                            Image(systemName: "camera.fill")
                                .foregroundStyle(Color.studioGold)
                        }
                }
                .offset(x: 55, y: 55)
            }

            Text("Tap to change photo")
                .font(.caption)
                .foregroundStyle(Color.studioSmoke)
        }
    }

    // MARK: - Form Section

    private var formSection: some View {
        VStack(spacing: 20) {
            // Display Name
            VStack(alignment: .leading, spacing: 8) {
                Text("Display Name")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.studioSmoke)

                TextField("Your name", text: $displayName)
                    .padding()
                    .background(Color.studioDeepBlack)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(Color.studioPlatinum)
            }

            // Username
            VStack(alignment: .leading, spacing: 8) {
                Text("Username")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.studioSmoke)

                HStack {
                    Text("@")
                        .foregroundStyle(Color.studioSmoke)

                    TextField("username", text: $username)
                        .autocapitalization(.none)
                        .textInputAutocapitalization(.never)
                        .foregroundStyle(Color.studioPlatinum)

                    Spacer()

                    if isCheckingUsername {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else if let available = usernameAvailable {
                        Image(systemName: available ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(available ? Color.studioSuccess : Color.studioError)
                    }
                }
                .padding()
                .background(Color.studioDeepBlack)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                if usernameAvailable == false && username != user.username {
                    Text("Username already taken")
                        .font(.caption)
                        .foregroundStyle(Color.studioError)
                }
            }

            // Bio
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Bio")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.studioSmoke)

                    Spacer()

                    Text("\(bio.count)/150")
                        .font(.caption)
                        .foregroundStyle(bio.count > 150 ? Color.studioError : Color.studioSmoke)
                }

                TextField("Tell us about yourself", text: $bio, axis: .vertical)
                    .lineLimit(3...5)
                    .padding()
                    .background(Color.studioDeepBlack)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(Color.studioPlatinum)
                    .onChange(of: bio) { _, newValue in
                        if newValue.count > 150 {
                            bio = String(newValue.prefix(150))
                        }
                    }
            }
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
