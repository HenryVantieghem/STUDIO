//
//  MediaPreviewView.swift
//  STUDIO
//
//  Basel Afterdark Design System
//  Dark luxury, minimal techno, retro-futuristic nightlife
//

import SwiftUI
import AVKit

// MARK: - Media Preview View

struct MediaPreviewView: View {
    let image: UIImage?
    let videoURL: URL?
    let onConfirm: (String?) -> Void
    let onRetake: () -> Void

    @State private var caption = ""
    @State private var player: AVPlayer?

    @FocusState private var isCaptionFocused: Bool

    var body: some View {
        ZStack {
            Color.studioBlack
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Media preview
                mediaPreview
                    .frame(maxHeight: .infinity)

                // Bottom controls
                VStack(spacing: 16) {
                    // Caption input
                    HStack {
                        TextField("ADD A CAPTION...", text: $caption)
                            .font(StudioTypography.bodyMedium)
                            .tracking(StudioTypography.trackingNormal)
                            .foregroundStyle(Color.studioPrimary)
                            .focused($isCaptionFocused)
                            .textInputAutocapitalization(.characters)

                        if !caption.isEmpty {
                            Button {
                                caption = ""
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(Color.studioMuted)
                            }
                        }
                    }
                    .padding()
                    .background(Color.studioSurface)
                    .overlay {
                        Rectangle()
                            .stroke(Color.studioLine, lineWidth: 0.5)
                    }
                    .padding(.horizontal, 24)

                    // Action buttons
                    HStack(spacing: 12) {
                        Button {
                            onRetake()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 14, weight: .ultraLight))
                                Text("RETAKE")
                                    .font(StudioTypography.labelMedium)
                                    .tracking(StudioTypography.trackingWide)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                        }
                        .buttonStyle(.studioSecondary)

                        Button {
                            onConfirm(caption.isEmpty ? nil : caption)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .medium))
                                Text("USE THIS")
                                    .font(StudioTypography.labelMedium)
                                    .tracking(StudioTypography.trackingWide)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                        }
                        .buttonStyle(.studioPrimary)
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.vertical, 20)
                .background(Color.studioBlack)
            }
        }
        .onAppear {
            if let videoURL {
                player = AVPlayer(url: videoURL)
            }
        }
        .onTapGesture {
            isCaptionFocused = false
        }
    }

    // MARK: - Media Preview

    @ViewBuilder
    private var mediaPreview: some View {
        if let image {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
        } else if let player {
            VideoPlayer(player: player)
                .onAppear {
                    player.play()
                }
                .onDisappear {
                    player.pause()
                }
        }
    }
}

// MARK: - Multi-Media Upload View

struct MediaUploadView: View {
    let partyId: UUID
    let selection: MediaSelection
    let onComplete: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var uploadProgress: Double = 0
    @State private var isUploading = false
    @State private var error: Error?
    @State private var showError = false
    @State private var uploadedCount = 0

    private let storageService = StorageService.shared

    var totalItems: Int {
        selection.images.count + selection.videoURLs.count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.studioBlack
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    if isUploading {
                        // Upload progress
                        VStack(spacing: 20) {
                            // Progress bar
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(Color.studioSurface)
                                        .frame(height: 4)

                                    Rectangle()
                                        .fill(Color.studioChrome)
                                        .frame(width: geo.size.width * uploadProgress, height: 4)
                                }
                            }
                            .frame(height: 4)
                            .padding(.horizontal, 48)

                            Text("UPLOADING \(uploadedCount)/\(totalItems)")
                                .studioLabelMedium()

                            Text("\(Int(uploadProgress * 100))%")
                                .font(StudioTypography.displayMedium)
                                .tracking(StudioTypography.trackingNormal)
                                .foregroundStyle(Color.studioChrome)
                        }
                        .padding()
                    } else {
                        // Preview grid
                        ScrollView {
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 2),
                                GridItem(.flexible(), spacing: 2),
                                GridItem(.flexible(), spacing: 2)
                            ], spacing: 2) {
                                ForEach(Array(selection.images.enumerated()), id: \.offset) { _, image in
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 120)
                                        .clipped()
                                }

                                ForEach(Array(selection.videoURLs.enumerated()), id: \.offset) { _, _ in
                                    Rectangle()
                                        .fill(Color.studioSurface)
                                        .frame(height: 120)
                                        .overlay {
                                            Image(systemName: "video")
                                                .font(.system(size: 28, weight: .ultraLight))
                                                .foregroundStyle(Color.studioChrome)
                                        }
                                }
                            }
                        }

                        // Upload button
                        Button {
                            Task {
                                await uploadAll()
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "arrow.up")
                                    .font(.system(size: 16, weight: .ultraLight))
                                Text("UPLOAD \(totalItems) ITEMS")
                                    .font(StudioTypography.labelLarge)
                                    .tracking(StudioTypography.trackingWide)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                        }
                        .buttonStyle(.studioPrimary)
                        .padding(.horizontal, 24)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("UPLOAD MEDIA")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("CANCEL") {
                        dismiss()
                    }
                    .font(StudioTypography.labelMedium)
                    .tracking(StudioTypography.trackingWide)
                    .foregroundStyle(Color.studioMuted)
                    .disabled(isUploading)
                }
            }
            .alert("UPLOAD ERROR", isPresented: $showError) {
                Button("OK") { showError = false }
            } message: {
                Text(error?.localizedDescription ?? "Failed to upload media")
            }
        }
        .tint(Color.studioChrome)
    }

    // MARK: - Upload All

    private func uploadAll() async {
        isUploading = true
        uploadedCount = 0

        do {
            // Upload images
            for image in selection.images {
                _ = try await storageService.uploadPartyMedia(partyId: partyId, image: image)
                uploadedCount += 1
                uploadProgress = Double(uploadedCount) / Double(totalItems)
            }

            // Upload videos
            for videoURL in selection.videoURLs {
                _ = try await storageService.uploadPartyVideo(partyId: partyId, videoURL: videoURL)
                uploadedCount += 1
                uploadProgress = Double(uploadedCount) / Double(totalItems)
            }

            onComplete()
            dismiss()
        } catch {
            self.error = error
            showError = true
            isUploading = false
        }
    }
}

// MARK: - Preview

#Preview {
    MediaPreviewView(
        image: nil,
        videoURL: nil,
        onConfirm: { _ in },
        onRetake: { }
    )
}
