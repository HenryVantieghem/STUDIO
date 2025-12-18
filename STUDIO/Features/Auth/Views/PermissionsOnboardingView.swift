//
//  PermissionsOnboardingView.swift
//  STUDIO
//
//  Pixel Afterdark Design System - 8-bit retro, sharp edges
//

import SwiftUI
import AVFoundation
import Photos

// MARK: - Permissions Onboarding View

/// Post-signup permissions request for camera and photo library
/// 4-step flow: Welcome → Camera → Photos → Complete
struct PermissionsOnboardingView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var cameraStatus: AVAuthorizationStatus = .notDetermined
    @State private var photosStatus: PHAuthorizationStatus = .notDetermined
    @State private var currentStep: PermissionStep = .welcome
    @State private var isAnimating = false

    var onComplete: () -> Void

    var body: some View {
        ZStack {
            // Pure black background - Pixel Afterdark
            Color.studioBlack
                .ignoresSafeArea()

            // Grid pattern overlay
            GeometryReader { geo in
                Path { path in
                    let spacing: CGFloat = 40
                    for x in stride(from: 0, to: geo.size.width, by: spacing) {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: geo.size.height))
                    }
                    for y in stride(from: 0, to: geo.size.height, by: spacing) {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geo.size.width, y: y))
                    }
                }
                .stroke(Color.studioLine.opacity(0.2), lineWidth: 0.5)
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress indicator
                progressIndicator
                    .padding(.top, 60)
                    .padding(.horizontal, 24)

                Spacer()

                // Content based on step
                switch currentStep {
                case .welcome:
                    welcomeContent
                case .camera:
                    cameraContent
                case .photos:
                    photosContent
                case .complete:
                    completeContent
                }

                Spacer()

                // Action button
                actionButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 60)
            }
        }
        .task {
            cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
            photosStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)

            withAnimation(.easeInOut(duration: 0.6)) {
                isAnimating = true
            }
        }
    }

    // MARK: - Progress Indicator

    private var progressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<4, id: \.self) { index in
                Rectangle()
                    .fill(index <= currentStep.rawValue ? Color.studioChrome : Color.studioLine)
                    .frame(height: 2)
            }
        }
    }

    // MARK: - Welcome Content

    private var welcomeContent: some View {
        VStack(spacing: 40) {
            // Pixel icon
            ZStack {
                Rectangle()
                    .fill(Color.studioSurface)
                    .frame(width: 120, height: 120)
                    .overlay {
                        Rectangle()
                            .stroke(Color.studioChrome, lineWidth: 2)
                    }

                Image(systemName: "sparkles")
                    .font(.system(size: 48, weight: .ultraLight))
                    .foregroundStyle(Color.studioChrome)
            }
            .scaleEffect(isAnimating ? 1 : 0.8)
            .opacity(isAnimating ? 1 : 0)

            VStack(spacing: 20) {
                Text("WELCOME TO STUDIO")
                    .font(StudioTypography.headlineLarge)
                    .tracking(StudioTypography.trackingWide)
                    .foregroundStyle(Color.studioPrimary)

                Text("BEFORE WE GET STARTED, WE NEED A FEW PERMISSIONS TO MAKE YOUR PARTY EXPERIENCE UNFORGETTABLE.")
                    .font(StudioTypography.bodySmall)
                    .tracking(StudioTypography.trackingNormal)
                    .foregroundStyle(Color.studioMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            .opacity(isAnimating ? 1 : 0)
            .offset(y: isAnimating ? 0 : 20)

            // Permission preview cards
            VStack(spacing: 12) {
                permissionPreviewCard(
                    icon: "camera.fill",
                    title: "CAMERA",
                    description: "CAPTURE PARTY MOMENTS"
                )

                permissionPreviewCard(
                    icon: "photo.fill",
                    title: "PHOTO LIBRARY",
                    description: "SAVE AND SHARE MEMORIES"
                )
            }
            .padding(.horizontal, 24)
            .opacity(isAnimating ? 1 : 0)
            .offset(y: isAnimating ? 0 : 30)
        }
    }

    private func permissionPreviewCard(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 16) {
            Rectangle()
                .fill(Color.studioSurface)
                .frame(width: 48, height: 48)
                .overlay {
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .light))
                        .foregroundStyle(Color.studioChrome)
                }
                .overlay {
                    Rectangle()
                        .stroke(Color.studioLine, lineWidth: 0.5)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(StudioTypography.labelLarge)
                    .tracking(StudioTypography.trackingNormal)
                    .foregroundStyle(Color.studioPrimary)

                Text(description)
                    .font(StudioTypography.labelSmall)
                    .tracking(StudioTypography.trackingNormal)
                    .foregroundStyle(Color.studioMuted)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .light))
                .foregroundStyle(Color.studioMuted)
        }
        .padding(16)
        .background(Color.studioSurface)
        .overlay {
            Rectangle()
                .stroke(Color.studioLine, lineWidth: 0.5)
        }
    }

    // MARK: - Camera Content

    private var cameraContent: some View {
        permissionContent(
            icon: "camera.fill",
            title: "CAMERA ACCESS",
            description: "TAKE PHOTOS AND VIDEOS AT PARTIES TO SHARE WITH YOUR CREW. YOUR MEMORIES DESERVE TO BE CAPTURED.",
            status: cameraStatusText,
            isGranted: cameraStatus == .authorized
        )
    }

    // MARK: - Photos Content

    private var photosContent: some View {
        permissionContent(
            icon: "photo.fill",
            title: "PHOTO LIBRARY",
            description: "SAVE PARTY PHOTOS TO YOUR LIBRARY AND UPLOAD EXISTING PHOTOS TO SHARE WITH FRIENDS.",
            status: photosStatusText,
            isGranted: photosStatus == .authorized || photosStatus == .limited
        )
    }

    private func permissionContent(
        icon: String,
        title: String,
        description: String,
        status: String,
        isGranted: Bool
    ) -> some View {
        VStack(spacing: 40) {
            // Animated pixel icon
            ZStack {
                // Pixel pulse rings
                ForEach(0..<3, id: \.self) { index in
                    Rectangle()
                        .stroke(Color.studioLine.opacity(0.3), lineWidth: 1)
                        .frame(
                            width: CGFloat(80 + index * 30),
                            height: CGFloat(80 + index * 30)
                        )
                        .scaleEffect(isAnimating ? 1.05 : 1)
                        .opacity(isAnimating ? 0.3 : 0.6)
                        .animation(
                            .easeInOut(duration: 1.2)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.15),
                            value: isAnimating
                        )
                }

                Rectangle()
                    .fill(Color.studioSurface)
                    .frame(width: 100, height: 100)
                    .overlay {
                        Image(systemName: icon)
                            .font(.system(size: 40, weight: .ultraLight))
                            .foregroundStyle(Color.studioChrome)
                    }
                    .overlay {
                        Rectangle()
                            .stroke(Color.studioChrome, lineWidth: 2)
                    }
            }

            VStack(spacing: 20) {
                Text(title)
                    .font(StudioTypography.headlineLarge)
                    .tracking(StudioTypography.trackingWide)
                    .foregroundStyle(Color.studioPrimary)

                Text(description)
                    .font(StudioTypography.bodySmall)
                    .tracking(StudioTypography.trackingNormal)
                    .foregroundStyle(Color.studioMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            // Status badge - pixel style
            HStack(spacing: 8) {
                Rectangle()
                    .fill(isGranted ? Color.studioChrome : Color.studioMuted)
                    .frame(width: 6, height: 6)

                Text(status)
                    .font(StudioTypography.labelSmall)
                    .tracking(StudioTypography.trackingNormal)
                    .foregroundStyle(isGranted ? Color.studioChrome : Color.studioMuted)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.studioSurface)
            .overlay {
                Rectangle()
                    .stroke(isGranted ? Color.studioChrome : Color.studioLine, lineWidth: 0.5)
            }
        }
    }

    // MARK: - Complete Content

    private var completeContent: some View {
        VStack(spacing: 40) {
            ZStack {
                Rectangle()
                    .fill(Color.studioSurface)
                    .frame(width: 120, height: 120)
                    .overlay {
                        Image(systemName: "checkmark")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundStyle(Color.studioChrome)
                    }
                    .overlay {
                        Rectangle()
                            .stroke(Color.studioChrome, lineWidth: 2)
                    }
            }
            .scaleEffect(isAnimating ? 1 : 0.5)

            VStack(spacing: 20) {
                Text("YOU'RE ALL SET")
                    .font(StudioTypography.headlineLarge)
                    .tracking(StudioTypography.trackingWide)
                    .foregroundStyle(Color.studioPrimary)

                Text("TIME TO START THE PARTY. CREATE YOUR FIRST EVENT OR JOIN ONE FROM A FRIEND.")
                    .font(StudioTypography.bodySmall)
                    .tracking(StudioTypography.trackingNormal)
                    .foregroundStyle(Color.studioMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            // Summary cards
            VStack(spacing: 12) {
                permissionSummaryCard(
                    icon: "camera.fill",
                    title: "CAMERA",
                    granted: cameraStatus == .authorized
                )

                permissionSummaryCard(
                    icon: "photo.fill",
                    title: "PHOTOS",
                    granted: photosStatus == .authorized || photosStatus == .limited
                )
            }
            .padding(.horizontal, 24)
        }
    }

    private func permissionSummaryCard(icon: String, title: String, granted: Bool) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .light))
                .foregroundStyle(granted ? Color.studioChrome : Color.studioMuted)
                .frame(width: 24)

            Text(title)
                .font(StudioTypography.labelLarge)
                .tracking(StudioTypography.trackingNormal)
                .foregroundStyle(Color.studioPrimary)

            Spacer()

            Rectangle()
                .fill(granted ? Color.studioChrome : Color.studioError)
                .frame(width: 20, height: 20)
                .overlay {
                    Image(systemName: granted ? "checkmark" : "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.studioBlack)
                }
        }
        .padding(16)
        .background(Color.studioSurface)
        .overlay {
            Rectangle()
                .stroke(Color.studioLine, lineWidth: 0.5)
        }
    }

    // MARK: - Action Button

    private var actionButton: some View {
        Button {
            handleAction()
        } label: {
            HStack(spacing: 12) {
                Text(buttonTitle)
                    .font(StudioTypography.labelLarge)
                    .tracking(StudioTypography.trackingWide)

                Image(systemName: buttonIcon)
                    .font(.system(size: 12, weight: .light))
            }
            .foregroundStyle(Color.studioBlack)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.studioChrome)
            .overlay {
                Rectangle()
                    .stroke(Color.studioPrimary, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }

    private var buttonTitle: String {
        switch currentStep {
        case .welcome:
            return "GET STARTED"
        case .camera:
            return cameraStatus == .notDetermined ? "ENABLE CAMERA" : "CONTINUE"
        case .photos:
            return photosStatus == .notDetermined ? "ENABLE PHOTOS" : "CONTINUE"
        case .complete:
            return "LET'S PARTY"
        }
    }

    private var buttonIcon: String {
        switch currentStep {
        case .welcome:
            return "arrow.right"
        case .camera, .photos:
            return "arrow.right"
        case .complete:
            return "sparkles"
        }
    }

    // MARK: - Status Helpers

    private var cameraStatusText: String {
        switch cameraStatus {
        case .authorized: return "ACCESS GRANTED"
        case .denied, .restricted: return "ACCESS DENIED"
        case .notDetermined: return "NOT YET REQUESTED"
        @unknown default: return "UNKNOWN"
        }
    }

    private var photosStatusText: String {
        switch photosStatus {
        case .authorized, .limited: return "ACCESS GRANTED"
        case .denied, .restricted: return "ACCESS DENIED"
        case .notDetermined: return "NOT YET REQUESTED"
        @unknown default: return "UNKNOWN"
        }
    }

    // MARK: - Actions

    private func handleAction() {
        switch currentStep {
        case .welcome:
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = .camera
            }

        case .camera:
            if cameraStatus == .notDetermined {
                requestCameraPermission()
            } else {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentStep = .photos
                }
            }

        case .photos:
            if photosStatus == .notDetermined {
                requestPhotosPermission()
            } else {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentStep = .complete
                }
            }

        case .complete:
            onComplete()
        }
    }

    private func requestCameraPermission() {
        Task {
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            cameraStatus = granted ? .authorized : .denied
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = .photos
            }
        }
    }

    private func requestPhotosPermission() {
        Task {
            let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            photosStatus = status
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = .complete
            }
        }
    }
}

// MARK: - Permission Step

private enum PermissionStep: Int {
    case welcome = 0
    case camera = 1
    case photos = 2
    case complete = 3
}

// MARK: - Preview

#Preview {
    PermissionsOnboardingView {
        print("Completed")
    }
}
