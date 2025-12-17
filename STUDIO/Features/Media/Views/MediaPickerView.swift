//
//  MediaPickerView.swift
//  STUDIO
//
//  Basel Afterdark Design System
//  Dark luxury, minimal techno, retro-futuristic nightlife
//

import SwiftUI
import PhotosUI

// MARK: - Media Picker View

struct MediaPickerView: View {
    let partyId: UUID
    let onMediaSelected: (MediaSelection) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var selectedVideoURLs: [URL] = []
    @State private var isLoading = false
    @State private var error: Error?
    @State private var showError = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.studioBlack
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    // Instructions
                    if selectedItems.isEmpty {
                        VStack(spacing: 20) {
                            // Square icon container
                            Rectangle()
                                .fill(Color.studioSurface)
                                .frame(width: 100, height: 100)
                                .overlay {
                                    Image(systemName: "photo.on.rectangle.angled")
                                        .font(.system(size: 40, weight: .ultraLight))
                                        .foregroundStyle(Color.studioChrome)
                                }
                                .overlay {
                                    Rectangle()
                                        .stroke(Color.studioLine, lineWidth: 0.5)
                                }

                            Text("SELECT MEDIA")
                                .studioHeadlineMedium()

                            Text("CHOOSE MOMENTS TO SHARE WITH THE PARTY")
                                .font(StudioTypography.bodySmall)
                                .tracking(StudioTypography.trackingNormal)
                                .foregroundStyle(Color.studioMuted)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                    }

                    // Selected media preview
                    if !selectedImages.isEmpty || !selectedVideoURLs.isEmpty {
                        selectedMediaPreview
                    }

                    Spacer()

                    // Photo picker button
                    PhotosPicker(
                        selection: $selectedItems,
                        maxSelectionCount: 10,
                        matching: .any(of: [.images, .videos]),
                        photoLibrary: .shared()
                    ) {
                        HStack(spacing: 12) {
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 16, weight: .ultraLight))
                            Text(selectedItems.isEmpty ? "CHOOSE MEDIA" : "ADD MORE")
                                .font(StudioTypography.labelLarge)
                                .tracking(StudioTypography.trackingWide)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .foregroundStyle(Color.studioBlack)
                        .background(Color.studioPrimary)
                    }
                    .padding(.horizontal, 24)

                    // Upload button
                    if !selectedImages.isEmpty || !selectedVideoURLs.isEmpty {
                        Button {
                            uploadMedia()
                        } label: {
                            if isLoading {
                                ProgressView()
                                    .tint(Color.studioBlack)
                            } else {
                                HStack(spacing: 12) {
                                    Image(systemName: "arrow.up")
                                        .font(.system(size: 16, weight: .ultraLight))
                                    Text("UPLOAD \(selectedImages.count + selectedVideoURLs.count) ITEMS")
                                        .font(StudioTypography.labelLarge)
                                        .tracking(StudioTypography.trackingWide)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                            }
                        }
                        .buttonStyle(.studioPrimary)
                        .disabled(isLoading)
                        .padding(.horizontal, 24)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("ADD MEDIA")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("CANCEL") {
                        dismiss()
                    }
                    .font(StudioTypography.labelMedium)
                    .tracking(StudioTypography.trackingWide)
                    .foregroundStyle(Color.studioMuted)
                }
            }
            .onChange(of: selectedItems) { _, newItems in
                Task {
                    await loadMedia(from: newItems)
                }
            }
            .alert("ERROR", isPresented: $showError) {
                Button("OK") { showError = false }
            } message: {
                Text(error?.localizedDescription ?? "An error occurred")
            }
        }
        .tint(Color.studioChrome)
    }

    // MARK: - Selected Media Preview

    private var selectedMediaPreview: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipped()
                            .overlay {
                                Rectangle()
                                    .stroke(Color.studioLine, lineWidth: 0.5)
                            }

                        Button {
                            selectedImages.remove(at: index)
                            if index < selectedItems.count {
                                selectedItems.remove(at: index)
                            }
                        } label: {
                            Rectangle()
                                .fill(Color.studioPrimary)
                                .frame(width: 24, height: 24)
                                .overlay {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundStyle(Color.studioBlack)
                                }
                        }
                        .offset(x: 4, y: -4)
                    }
                }

                ForEach(Array(selectedVideoURLs.enumerated()), id: \.offset) { index, _ in
                    ZStack(alignment: .topTrailing) {
                        Rectangle()
                            .fill(Color.studioSurface)
                            .frame(width: 100, height: 100)
                            .overlay {
                                Image(systemName: "video")
                                    .font(.system(size: 28, weight: .ultraLight))
                                    .foregroundStyle(Color.studioChrome)
                            }
                            .overlay {
                                Rectangle()
                                    .stroke(Color.studioLine, lineWidth: 0.5)
                            }

                        Button {
                            selectedVideoURLs.remove(at: index)
                        } label: {
                            Rectangle()
                                .fill(Color.studioPrimary)
                                .frame(width: 24, height: 24)
                                .overlay {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundStyle(Color.studioBlack)
                                }
                        }
                        .offset(x: 4, y: -4)
                    }
                }
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Load Media

    private func loadMedia(from items: [PhotosPickerItem]) async {
        selectedImages = []
        selectedVideoURLs = []

        for item in items {
            // Try loading as image first
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    selectedImages.append(image)
                }
            }
            // Try loading as video
            else if let movie = try? await item.loadTransferable(type: MovieTransferable.self) {
                await MainActor.run {
                    selectedVideoURLs.append(movie.url)
                }
            }
        }
    }

    // MARK: - Upload Media

    private func uploadMedia() {
        let images = selectedImages
        let videos = selectedVideoURLs
        let selection = MediaSelection(images: images, videoURLs: videos)
        onMediaSelected(selection)
        dismiss()
    }
}

// MARK: - Media Selection

struct MediaSelection: Sendable {
    let images: [UIImage]
    let videoURLs: [URL]
}

// MARK: - Movie Transferable

struct MovieTransferable: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("mov")
            try FileManager.default.copyItem(at: received.file, to: tempURL)
            return Self(url: tempURL)
        }
    }
}
