//
//  CameraView.swift
//  STUDIO
//
//  Basel Afterdark Design System
//  Dark luxury, minimal techno, retro-futuristic nightlife
//

import SwiftUI
import AVFoundation

// MARK: - Camera View

struct CameraView: View {
    let partyId: UUID
    let onCapture: (CameraCapture) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var cameraManager = CameraManager()
    @State private var showPreview = false
    @State private var capturedImage: UIImage?
    @State private var capturedVideoURL: URL?

    var body: some View {
        ZStack {
            Color.studioBlack
                .ignoresSafeArea()

            if cameraManager.isAuthorized {
                // Camera preview
                CameraPreviewView(cameraManager: cameraManager)
                    .ignoresSafeArea()

                // Controls overlay
                VStack {
                    // Top bar
                    topBar

                    Spacer()

                    // Bottom controls
                    bottomControls
                }
            } else if let error = cameraManager.error {
                // Permission denied view
                permissionDeniedView(error: error)
            } else {
                // Loading
                ProgressView()
                    .tint(Color.studioChrome)
            }
        }
        .task {
            await cameraManager.checkAuthorization()
        }
        .onAppear {
            cameraManager.startSession()
        }
        .onDisappear {
            cameraManager.stopSession()
        }
        .onChange(of: cameraManager.capturedImage) { _, image in
            if let image {
                capturedImage = image
                showPreview = true
            }
        }
        .onChange(of: cameraManager.capturedVideoURL) { _, url in
            if let url {
                capturedVideoURL = url
                showPreview = true
            }
        }
        .fullScreenCover(isPresented: $showPreview) {
            if let image = capturedImage {
                MediaPreviewView(
                    image: image,
                    videoURL: nil,
                    onConfirm: { caption in
                        onCapture(CameraCapture(image: image, videoURL: nil, caption: caption))
                        dismiss()
                    },
                    onRetake: {
                        capturedImage = nil
                        cameraManager.clearCapture()
                        showPreview = false
                    }
                )
            } else if let videoURL = capturedVideoURL {
                MediaPreviewView(
                    image: nil,
                    videoURL: videoURL,
                    onConfirm: { caption in
                        onCapture(CameraCapture(image: nil, videoURL: videoURL, caption: caption))
                        dismiss()
                    },
                    onRetake: {
                        capturedVideoURL = nil
                        cameraManager.clearCapture()
                        showPreview = false
                    }
                )
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            // Close button
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .padding()
            }

            Spacer()

            // Flash toggle
            Button {
                cameraManager.toggleFlash()
            } label: {
                Image(systemName: flashIcon)
                    .font(.title2)
                    .foregroundStyle(.white)
                    .padding()
            }
        }
        .padding(.horizontal)
    }

    private var flashIcon: String {
        switch cameraManager.flashMode {
        case .auto: return "bolt.badge.automatic"
        case .on: return "bolt.fill"
        case .off: return "bolt.slash"
        @unknown default: return "bolt.badge.automatic"
        }
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        HStack(alignment: .center, spacing: 40) {
            // Gallery button placeholder - SQUARE
            Rectangle()
                .fill(Color.studioSurface)
                .frame(width: 50, height: 50)
                .overlay {
                    Rectangle()
                        .stroke(Color.studioLine, lineWidth: 0.5)
                }

            // Capture button
            captureButton

            // Switch camera - SQUARE
            Button {
                cameraManager.switchCamera()
            } label: {
                Image(systemName: "camera.rotate")
                    .font(.system(size: 20, weight: .ultraLight))
                    .foregroundStyle(Color.studioPrimary)
                    .frame(width: 50, height: 50)
                    .background(Color.studioSurface)
                    .overlay {
                        Rectangle()
                            .stroke(Color.studioLine, lineWidth: 0.5)
                    }
            }
        }
        .padding(.bottom, 40)
    }

    private var captureButton: some View {
        Button {
            if cameraManager.isRecording {
                cameraManager.stopRecording()
            } else {
                cameraManager.capturePhoto()
            }
        } label: {
            ZStack {
                // Outer ring - SQUARE
                Rectangle()
                    .stroke(Color.studioPrimary, lineWidth: 2)
                    .frame(width: 80, height: 80)

                // Inner button - SQUARE
                Rectangle()
                    .fill(cameraManager.isRecording ? Color.red : Color.studioPrimary)
                    .frame(width: 68, height: 68)

                // Recording indicator - SQUARE
                if cameraManager.isRecording {
                    Rectangle()
                        .fill(Color.studioBlack)
                        .frame(width: 24, height: 24)
                }
            }
        }
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    cameraManager.startRecording()
                }
        )
    }

    // MARK: - Permission Denied View

    private func permissionDeniedView(error: CameraManager.CameraError) -> some View {
        VStack(spacing: 24) {
            // Square icon container
            Rectangle()
                .fill(Color.studioSurface)
                .frame(width: 100, height: 100)
                .overlay {
                    Image(systemName: "camera")
                        .font(.system(size: 40, weight: .ultraLight))
                        .foregroundStyle(Color.studioMuted)
                }
                .overlay {
                    Rectangle()
                        .stroke(Color.studioLine, lineWidth: 0.5)
                }

            Text("CAMERA ACCESS REQUIRED")
                .studioHeadlineMedium()

            Text(error.localizedDescription.uppercased())
                .font(StudioTypography.bodySmall)
                .tracking(StudioTypography.trackingNormal)
                .foregroundStyle(Color.studioMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(spacing: 12) {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("OPEN SETTINGS")
                        .font(StudioTypography.labelLarge)
                        .tracking(StudioTypography.trackingWide)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                }
                .buttonStyle(.studioPrimary)

                Button {
                    dismiss()
                } label: {
                    Text("CANCEL")
                        .font(StudioTypography.labelLarge)
                        .tracking(StudioTypography.trackingWide)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                }
                .buttonStyle(.studioSecondary)
            }
            .padding(.horizontal, 32)
        }
        .padding()
    }
}

// MARK: - Camera Capture Result

struct CameraCapture: Sendable {
    let image: UIImage?
    let videoURL: URL?
    let caption: String?
}
