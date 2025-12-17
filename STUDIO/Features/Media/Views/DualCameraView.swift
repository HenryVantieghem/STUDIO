//
//  DualCameraView.swift
//  STUDIO
//
//  BeReal-style dual camera capture view
//  Shows back camera full-screen with front camera PiP
//  Basel Afterdark Design System
//

import SwiftUI

// MARK: - Dual Camera View

struct DualCameraView: View {
    var onCapture: ((DualCaptureResult) -> Void)?
    var onDismiss: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var cameraManager = DualCameraManager()
    @State private var showPreview = false
    @State private var caption = ""
    @State private var animatePulse = false
    @State private var showFlash = false

    var body: some View {
        ZStack {
            Color.studioBlack.ignoresSafeArea()

            if showPreview, let composite = cameraManager.compositeImage {
                // Preview captured image
                capturePreview(composite)
            } else {
                // Live camera view
                liveCameraView
            }

            // Flash overlay
            if showFlash {
                Color.white
                    .ignoresSafeArea()
                    .opacity(showFlash ? 0.8 : 0)
                    .animation(.easeOut(duration: 0.1), value: showFlash)
            }
        }
        .task {
            await cameraManager.checkAuthorization()
        }
        .onAppear {
            cameraManager.startSessions()
        }
        .onDisappear {
            cameraManager.stopSessions()
        }
    }

    // MARK: - Live Camera View

    private var liveCameraView: some View {
        GeometryReader { geo in
            ZStack {
                // Back camera (full screen)
                DualCameraBackPreview(cameraManager: cameraManager)
                    .ignoresSafeArea()

                // Front camera PiP
                frontCameraPiP(in: geo)

                // Controls overlay
                VStack {
                    // Top bar
                    topControls

                    Spacer()

                    // "STUDIO" branding
                    Text("STUDIO")
                        .font(StudioTypography.displayMedium)
                        .tracking(StudioTypography.trackingExtraWide)
                        .foregroundStyle(Color.studioPrimary.opacity(0.3))
                        .padding(.bottom, 8)

                    // Capture button
                    captureButton

                    // Bottom hint
                    Text("TAP TO CAPTURE BOTH CAMERAS")
                        .font(StudioTypography.labelSmall)
                        .tracking(StudioTypography.trackingNormal)
                        .foregroundStyle(Color.studioMuted)
                        .padding(.top, 12)
                        .padding(.bottom, 40)
                }
            }
        }
    }

    // MARK: - Front Camera PiP

    private func frontCameraPiP(in geo: GeometryProxy) -> some View {
        let pipWidth: CGFloat = geo.size.width * 0.28
        let pipHeight: CGFloat = pipWidth * 1.33 // 4:3 aspect
        let padding: CGFloat = 16

        return DualCameraFrontPreview(cameraManager: cameraManager)
            .frame(width: pipWidth, height: pipHeight)
            .scaleEffect(x: -1, y: 1) // Mirror for selfie
            .clipShape(Rectangle())
            .overlay {
                // Double pixel border
                Rectangle()
                    .stroke(Color.studioBlack, lineWidth: 2)
                Rectangle()
                    .stroke(Color.studioPrimary, lineWidth: 1)
                    .padding(2)
            }
            .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y: 4)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: cameraManager.pipPosition.alignment)
            .padding(padding)
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    cameraManager.togglePiPPosition()
                }
                HapticManager.shared.impact(.light)
            }
    }

    // MARK: - Top Controls

    private var topControls: some View {
        HStack {
            // Close button
            Button {
                HapticManager.shared.impact(.light)
                dismiss()
                onDismiss?()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.studioPrimary)
                    .frame(width: 44, height: 44)
                    .background(Color.studioBlack.opacity(0.5))
                    .clipShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer()

            // Flash toggle
            Button {
                HapticManager.shared.impact(.light)
                cameraManager.toggleFlash()
            } label: {
                Image(systemName: flashIcon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(flashColor)
                    .frame(width: 44, height: 44)
                    .background(Color.studioBlack.opacity(0.5))
                    .clipShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var flashIcon: String {
        switch cameraManager.flashMode {
        case .on: return "bolt.fill"
        case .off: return "bolt.slash"
        case .auto: return "bolt.badge.automatic"
        @unknown default: return "bolt.slash"
        }
    }

    private var flashColor: Color {
        cameraManager.flashMode == .on ? .yellow : .studioPrimary
    }

    // MARK: - Capture Button

    private var captureButton: some View {
        Button {
            Task {
                await performCapture()
            }
        } label: {
            ZStack {
                // Outer ring with pulse animation
                Circle()
                    .stroke(Color.studioPrimary, lineWidth: 4)
                    .frame(width: 80, height: 80)
                    .scaleEffect(animatePulse ? 1.1 : 1.0)
                    .opacity(animatePulse ? 0.5 : 1.0)

                // Inner circle
                Circle()
                    .fill(Color.studioPrimary)
                    .frame(width: 64, height: 64)

                // Pixel pattern overlay
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Rectangle().fill(Color.studioBlack.opacity(0.2)).frame(width: 8, height: 8)
                        Rectangle().fill(Color.studioBlack.opacity(0.1)).frame(width: 8, height: 8)
                        Rectangle().fill(Color.studioBlack.opacity(0.2)).frame(width: 8, height: 8)
                    }
                    HStack(spacing: 4) {
                        Rectangle().fill(Color.studioBlack.opacity(0.1)).frame(width: 8, height: 8)
                        Rectangle().fill(Color.studioBlack.opacity(0.2)).frame(width: 8, height: 8)
                        Rectangle().fill(Color.studioBlack.opacity(0.1)).frame(width: 8, height: 8)
                    }
                    HStack(spacing: 4) {
                        Rectangle().fill(Color.studioBlack.opacity(0.2)).frame(width: 8, height: 8)
                        Rectangle().fill(Color.studioBlack.opacity(0.1)).frame(width: 8, height: 8)
                        Rectangle().fill(Color.studioBlack.opacity(0.2)).frame(width: 8, height: 8)
                    }
                }
            }
            .scaleEffect(cameraManager.isCapturing ? 0.9 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: cameraManager.isCapturing)
        }
        .buttonStyle(.plain)
        .disabled(cameraManager.isCapturing)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                animatePulse = true
            }
        }
    }

    // MARK: - Capture Preview

    private func capturePreview(_ image: UIImage) -> some View {
        VStack(spacing: 0) {
            // Image preview
            ZStack {
                Color.studioDeepBlack

                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(Rectangle())
            }
            .frame(maxWidth: .infinity)
            .frame(height: UIScreen.main.bounds.width * 1.33)

            // Divider
            Rectangle()
                .fill(Color.studioLine)
                .frame(height: 1)

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
                            .stroke(Color.studioLine, lineWidth: 1)
                    }
            }
            .padding(16)

            // Action buttons
            HStack(spacing: 16) {
                // Retake button
                Button {
                    HapticManager.shared.impact(.light)
                    cameraManager.clearCaptures()
                    showPreview = false
                    caption = ""
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 14, weight: .medium))
                        Text("RETAKE")
                            .font(StudioTypography.labelMedium)
                            .tracking(StudioTypography.trackingNormal)
                    }
                    .foregroundStyle(Color.studioMuted)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.studioSurface)
                    .overlay {
                        Rectangle()
                            .stroke(Color.studioLine, lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)

                // Post button
                Button {
                    HapticManager.shared.impact(.medium)
                    let result = DualCaptureResult(
                        frontImage: cameraManager.frontImage,
                        backImage: cameraManager.backImage,
                        compositeImage: cameraManager.compositeImage,
                        caption: caption.isEmpty ? nil : caption
                    )
                    onCapture?(result)
                    dismiss()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 14, weight: .medium))
                        Text("POST")
                            .font(StudioTypography.labelMedium)
                            .tracking(StudioTypography.trackingNormal)
                    }
                    .foregroundStyle(Color.studioBlack)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.studioChrome)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)

            Spacer()
        }
        .background(Color.studioBlack)
    }

    // MARK: - Perform Capture

    private func performCapture() async {
        HapticManager.shared.impact(.medium)

        // Flash effect
        withAnimation(.easeIn(duration: 0.05)) {
            showFlash = true
        }

        await cameraManager.captureDualPhoto()

        withAnimation(.easeOut(duration: 0.2)) {
            showFlash = false
        }

        if cameraManager.compositeImage != nil {
            HapticManager.shared.notification(.success)
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showPreview = true
            }
        }
    }
}

// MARK: - Dual Camera Sheet

struct DualCameraSheet: View {
    let partyId: UUID
    var onMediaAdded: ((MediaType, Data, String?) -> Void)?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        DualCameraView(
            onCapture: { result in
                guard let composite = result.compositeImage else { return }

                let mediaService = MediaService()
                if let data = mediaService.compressImage(composite) {
                    onMediaAdded?(.photo, data, result.caption)
                }

                dismiss()
            },
            onDismiss: {
                dismiss()
            }
        )
    }
}

// MARK: - Preview

#Preview("Dual Camera View") {
    DualCameraView()
}
