//
//  AddMediaSheet.swift
//  STUDIO
//
//  Combined camera + gallery media picker sheet
//  Basel Afterdark Design System
//

import SwiftUI
import PhotosUI
import AVFoundation
import UIKit

// MARK: - Add Media Sheet

/// Combined camera preview + gallery picker for adding party media
struct AddMediaSheet: View {
    let partyId: UUID
    var onMediaAdded: ((MediaType, Data, String?) -> Void)?

    @Environment(\.dismiss) private var dismiss

    // Camera state
    @State private var showCamera = false
    @State private var cameraPermissionDenied = false

    // Photo picker state
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var selectedImage: UIImage?

    // Capture state
    @State private var capturedImage: UIImage?
    @State private var caption = ""

    // Upload state
    @State private var isUploading = false
    @State private var error: Error?
    @State private var showError = false

    // Mode
    @State private var mediaType: MediaType = .photo

    var body: some View {
        NavigationStack {
            ZStack {
                Color.studioBlack.ignoresSafeArea()

                VStack(spacing: 0) {
                    if let image = capturedImage ?? selectedImage {
                        // Preview mode
                        previewView(image: image)
                    } else {
                        // Selection mode
                        selectionView
                    }
                }
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

                if capturedImage != nil || selectedImage != nil {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            Task {
                                await uploadMedia()
                            }
                        } label: {
                            if isUploading {
                                ProgressView()
                                    .tint(Color.studioChrome)
                            } else {
                                Text("POST")
                                    .font(StudioTypography.labelMedium)
                                    .tracking(StudioTypography.trackingWide)
                                    .foregroundStyle(Color.studioChrome)
                            }
                        }
                        .disabled(isUploading)
                    }
                }
            }
            .alert("ERROR", isPresented: $showError) {
                Button("OK") { showError = false }
            } message: {
                Text(error?.localizedDescription ?? "Failed to upload media")
            }
            .alert("CAMERA ACCESS", isPresented: $cameraPermissionDenied) {
                Button("SETTINGS") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("CANCEL", role: .cancel) { }
            } message: {
                Text("Please enable camera access in Settings to capture photos")
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraCaptureView { image in
                    capturedImage = image
                    showCamera = false
                }
            }
            .onChange(of: selectedItem) { _, newValue in
                Task {
                    await loadSelectedImage(newValue)
                }
            }
        }
        .tint(Color.studioChrome)
    }

    // MARK: - Selection View

    private var selectionView: some View {
        VStack(spacing: 0) {
            // Camera capture area
            cameraSection

            // Divider
            Rectangle()
                .fill(Color.studioLine)
                .frame(height: 0.5)

            // Gallery section
            gallerySection
        }
    }

    // MARK: - Camera Section

    private var cameraSection: some View {
        VStack(spacing: 20) {
            Spacer()

            // Camera icon placeholder
            ZStack {
                Rectangle()
                    .fill(Color.studioSurface)
                    .frame(width: 120, height: 120)

                Image(systemName: "camera.fill")
                    .font(.system(size: 48, weight: .ultraLight))
                    .foregroundStyle(Color.studioMuted)
            }
            .overlay {
                Rectangle()
                    .stroke(Color.studioLine, lineWidth: 0.5)
            }

            // Capture button
            Button {
                checkCameraPermission()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 16, weight: .regular))
                    Text("CAPTURE")
                        .font(StudioTypography.labelLarge)
                        .tracking(StudioTypography.trackingWide)
                }
                .foregroundStyle(Color.studioBlack)
                .frame(width: 200, height: 56)
                .background(Color.studioChrome)
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .frame(height: 280)
        .background(Color.studioDeepBlack)
    }

    // MARK: - Gallery Section

    private var gallerySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("RECENT PHOTOS")
                    .font(StudioTypography.labelSmall)
                    .tracking(StudioTypography.trackingWide)
                    .foregroundStyle(Color.studioMuted)

                Spacer()

                // Photos picker button
                PhotosPicker(
                    selection: $selectedItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    HStack(spacing: 6) {
                        Text("VIEW ALL")
                            .font(StudioTypography.labelSmall)
                            .tracking(StudioTypography.trackingNormal)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .light))
                    }
                    .foregroundStyle(Color.studioChrome)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            // Photo grid with PhotosPicker
            PhotosPicker(
                selection: $selectedItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                // Placeholder grid
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 2),
                    GridItem(.flexible(), spacing: 2),
                    GridItem(.flexible(), spacing: 2),
                    GridItem(.flexible(), spacing: 2)
                ], spacing: 2) {
                    ForEach(0..<8, id: \.self) { _ in
                        Rectangle()
                            .fill(Color.studioSurface)
                            .aspectRatio(1, contentMode: .fit)
                            .overlay {
                                Image(systemName: "photo")
                                    .font(.system(size: 20, weight: .ultraLight))
                                    .foregroundStyle(Color.studioLine)
                            }
                    }
                }
                .padding(.horizontal, 16)
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color.studioBlack)
    }

    // MARK: - Preview View

    private func previewView(image: UIImage) -> some View {
        VStack(spacing: 0) {
            // Image preview
            ZStack {
                Color.studioDeepBlack

                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            }
            .frame(maxWidth: .infinity)
            .frame(height: UIScreen.main.bounds.width)

            // Divider
            Rectangle()
                .fill(Color.studioLine)
                .frame(height: 0.5)

            // Caption input
            VStack(alignment: .leading, spacing: 12) {
                Text("CAPTION (OPTIONAL)")
                    .font(StudioTypography.labelSmall)
                    .tracking(StudioTypography.trackingWide)
                    .foregroundStyle(Color.studioMuted)

                TextField("", text: $caption, prompt: Text("Add a caption...")
                    .font(StudioTypography.bodyMedium)
                    .foregroundStyle(Color.studioMuted))
                    .font(StudioTypography.bodyMedium)
                    .foregroundStyle(Color.studioPrimary)
                    .textInputAutocapitalization(.sentences)
                    .padding()
                    .background(Color.studioSurface)
                    .overlay {
                        Rectangle()
                            .stroke(Color.studioLine, lineWidth: 0.5)
                    }
            }
            .padding(16)

            // Clear selection button
            Button {
                clearSelection()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .light))
                    Text("CHOOSE DIFFERENT")
                        .font(StudioTypography.labelSmall)
                        .tracking(StudioTypography.trackingNormal)
                }
                .foregroundStyle(Color.studioMuted)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .background(Color.studioBlack)
    }

    // MARK: - Camera Permission

    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            Task {
                let granted = await AVCaptureDevice.requestAccess(for: .video)
                if granted {
                    showCamera = true
                } else {
                    cameraPermissionDenied = true
                }
            }
        case .authorized:
            showCamera = true
        case .denied, .restricted:
            cameraPermissionDenied = true
        @unknown default:
            break
        }
    }

    // MARK: - Load Selected Image

    private func loadSelectedImage(_ item: PhotosPickerItem?) async {
        guard let item = item else { return }

        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                selectedImageData = data
                if let uiImage = UIImage(data: data) {
                    selectedImage = uiImage
                }
            }
        } catch {
            self.error = error
            self.showError = true
        }
    }

    // MARK: - Clear Selection

    private func clearSelection() {
        capturedImage = nil
        selectedImage = nil
        selectedImageData = nil
        selectedItem = nil
        caption = ""
    }

    // MARK: - Upload Media

    private func uploadMedia() async {
        guard let image = capturedImage ?? selectedImage else { return }

        isUploading = true

        // Compress image
        let mediaService = MediaService()
        guard let compressedData = mediaService.compressImage(image) else {
            error = MediaUploadError.compressionFailed
            showError = true
            isUploading = false
            return
        }

        // Call callback with data
        onMediaAdded?(.photo, compressedData, caption.isEmpty ? nil : caption)

        isUploading = false
        dismiss()
    }
}

// MARK: - Media Upload Error

enum MediaUploadError: LocalizedError {
    case compressionFailed
    case uploadFailed

    var errorDescription: String? {
        switch self {
        case .compressionFailed:
            return "Failed to compress image"
        case .uploadFailed:
            return "Failed to upload media"
        }
    }
}

// MARK: - Camera Capture View

/// Full screen camera capture view
struct CameraCaptureView: View {
    var onCapture: (UIImage) -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var cameraModel = CameraModel()

    var body: some View {
        ZStack {
            Color.studioBlack.ignoresSafeArea()

            // Camera preview
            CameraPreviewView(session: cameraModel.session)
                .ignoresSafeArea()

            // Controls overlay
            VStack {
                // Top bar
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .light))
                            .foregroundStyle(Color.studioPrimary)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    // Flash toggle
                    Button {
                        cameraModel.toggleFlash()
                    } label: {
                        Image(systemName: cameraModel.flashMode == .on ? "bolt.fill" : "bolt.slash")
                            .font(.system(size: 18, weight: .light))
                            .foregroundStyle(Color.studioPrimary)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                Spacer()

                // Capture button
                HStack {
                    Spacer()

                    Button {
                        cameraModel.capturePhoto { image in
                            if let image = image {
                                onCapture(image)
                            }
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .stroke(Color.studioPrimary, lineWidth: 3)
                                .frame(width: 72, height: 72)

                            Circle()
                                .fill(Color.studioPrimary)
                                .frame(width: 60, height: 60)
                        }
                    }
                    .buttonStyle(.plain)

                    Spacer()
                }
                .padding(.bottom, 40)
            }
        }
        .task {
            await cameraModel.configure()
        }
        .onDisappear {
            cameraModel.stop()
        }
    }
}

// MARK: - Camera Model

/// Camera session manager
class CameraModel: NSObject, ObservableObject {
    let session = AVCaptureSession()
    private var photoOutput = AVCapturePhotoOutput()
    private var captureCompletion: ((UIImage?) -> Void)?

    @Published var flashMode: AVCaptureDevice.FlashMode = .off

    func configure() async {
        guard await AVCaptureDevice.requestAccess(for: .video) else { return }

        session.beginConfiguration()

        // Video input
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            session.commitConfiguration()
            return
        }

        session.addInput(input)

        // Photo output
        guard session.canAddOutput(photoOutput) else {
            session.commitConfiguration()
            return
        }

        session.addOutput(photoOutput)
        session.commitConfiguration()

        // Start session
        Task {
            session.startRunning()
        }
    }

    func stop() {
        session.stopRunning()
    }

    func toggleFlash() {
        flashMode = flashMode == .off ? .on : .off
    }

    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        captureCompletion = completion

        let settings = AVCapturePhotoSettings()
        settings.flashMode = flashMode

        photoOutput.capturePhoto(with: settings, delegate: self)
    }
}

extension CameraModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil,
              let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            captureCompletion?(nil)
            return
        }

        captureCompletion?(image)
    }
}

// MARK: - Camera Preview View

/// UIKit camera preview wrapper
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        context.coordinator.previewLayer = previewLayer

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.previewLayer?.frame = uiView.bounds
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var previewLayer: AVCaptureVideoPreviewLayer?
    }
}

// MARK: - Preview

#Preview("Add Media Sheet") {
    AddMediaSheet(partyId: UUID())
}
