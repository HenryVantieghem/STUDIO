//
//  PermissionsOnboardingView.swift
//  STUDIO
//
//  Created by Claude on 12/16/25.
//

import SwiftUI
import AVFoundation
import Photos

// MARK: - Permissions Onboarding View

/// Post-signup permissions request for camera and photo library
struct PermissionsOnboardingView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var cameraStatus: AVAuthorizationStatus = .notDetermined
    @State private var photosStatus: PHAuthorizationStatus = .notDetermined
    @State private var currentStep: PermissionStep = .welcome
    @State private var isAnimating = false

    var onComplete: () -> Void

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.studioBlack, Color.studioBlack.opacity(0.95)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Disco ball ambient effect
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.studioGold.opacity(0.15), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 300
                    )
                )
                .frame(width: 600, height: 600)
                .offset(y: -200)
                .blur(radius: 60)

            VStack(spacing: 0) {
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

            withAnimation(.easeInOut(duration: 0.8)) {
                isAnimating = true
            }
        }
    }

    // MARK: - Welcome Content

    private var welcomeContent: some View {
        VStack(spacing: 32) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.studioGold.opacity(0.1))
                    .frame(width: 140, height: 140)

                Circle()
                    .fill(Color.studioGold.opacity(0.2))
                    .frame(width: 100, height: 100)

                Image(systemName: "sparkles")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundStyle(Color.studioGold)
            }
            .scaleEffect(isAnimating ? 1 : 0.8)
            .opacity(isAnimating ? 1 : 0)

            VStack(spacing: 16) {
                Text("Welcome to STUDIO")
                    .font(.custom("Bodoni 72 Oldstyle", size: 32))
                    .foregroundStyle(Color.studioPlatinum)

                Text("Before we get started, we need a few permissions to make your party experience unforgettable.")
                    .font(.subheadline)
                    .foregroundStyle(Color.studioSilver)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .opacity(isAnimating ? 1 : 0)
            .offset(y: isAnimating ? 0 : 20)

            // Permission preview cards
            VStack(spacing: 12) {
                permissionPreviewCard(
                    icon: "camera.fill",
                    title: "Camera",
                    description: "Capture party moments"
                )

                permissionPreviewCard(
                    icon: "photo.fill",
                    title: "Photo Library",
                    description: "Save and share memories"
                )
            }
            .padding(.horizontal, 24)
            .opacity(isAnimating ? 1 : 0)
            .offset(y: isAnimating ? 0 : 30)
        }
    }

    private func permissionPreviewCard(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.studioGold.opacity(0.1))
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(Color.studioGold)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.studioPlatinum)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(Color.studioSilver)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color.studioSilver.opacity(0.5))
        }
        .padding(16)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    // MARK: - Camera Content

    private var cameraContent: some View {
        permissionContent(
            icon: "camera.fill",
            title: "Camera Access",
            description: "Take photos and videos at parties to share with your crew. Your memories deserve to be captured.",
            status: cameraStatusText,
            statusColor: cameraStatusColor
        )
    }

    // MARK: - Photos Content

    private var photosContent: some View {
        permissionContent(
            icon: "photo.fill",
            title: "Photo Library",
            description: "Save party photos to your library and upload existing photos to share with friends.",
            status: photosStatusText,
            statusColor: photosStatusColor
        )
    }

    private func permissionContent(
        icon: String,
        title: String,
        description: String,
        status: String,
        statusColor: Color
    ) -> some View {
        VStack(spacing: 32) {
            // Animated icon
            ZStack {
                // Pulsing rings
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .stroke(Color.studioGold.opacity(0.1), lineWidth: 2)
                        .frame(width: CGFloat(100 + index * 40), height: CGFloat(100 + index * 40))
                        .scaleEffect(isAnimating ? 1.1 : 1)
                        .opacity(isAnimating ? 0.3 : 0.6)
                        .animation(
                            .easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                            value: isAnimating
                        )
                }

                Circle()
                    .fill(Color.studioGold.opacity(0.2))
                    .frame(width: 100, height: 100)

                Image(systemName: icon)
                    .font(.system(size: 44, weight: .medium))
                    .foregroundStyle(Color.studioGold)
            }

            VStack(spacing: 16) {
                Text(title)
                    .font(.custom("Bodoni 72 Oldstyle", size: 28))
                    .foregroundStyle(Color.studioPlatinum)

                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(Color.studioSilver)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            // Status badge
            HStack(spacing: 8) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)

                Text(status)
                    .font(.caption)
                    .foregroundStyle(statusColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(statusColor.opacity(0.1))
            .clipShape(Capsule())
        }
    }

    // MARK: - Complete Content

    private var completeContent: some View {
        VStack(spacing: 32) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 140, height: 140)

                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 100, height: 100)

                Image(systemName: "checkmark")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(Color.green)
            }
            .scaleEffect(isAnimating ? 1 : 0.5)

            VStack(spacing: 16) {
                Text("You're All Set!")
                    .font(.custom("Bodoni 72 Oldstyle", size: 32))
                    .foregroundStyle(Color.studioPlatinum)

                Text("Time to start the party. Create your first event or join one from a friend.")
                    .font(.subheadline)
                    .foregroundStyle(Color.studioSilver)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            // Summary cards
            VStack(spacing: 12) {
                permissionSummaryCard(
                    icon: "camera.fill",
                    title: "Camera",
                    granted: cameraStatus == .authorized
                )

                permissionSummaryCard(
                    icon: "photo.fill",
                    title: "Photos",
                    granted: photosStatus == .authorized
                )
            }
            .padding(.horizontal, 24)
        }
    }

    private func permissionSummaryCard(icon: String, title: String, granted: Bool) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(granted ? Color.studioGold : Color.studioSilver)
                .frame(width: 32)

            Text(title)
                .font(.subheadline)
                .foregroundStyle(Color.studioPlatinum)

            Spacer()

            Image(systemName: granted ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(granted ? Color.green : Color.red.opacity(0.7))
        }
        .padding(16)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Action Button

    private var actionButton: some View {
        Button {
            handleAction()
        } label: {
            HStack(spacing: 8) {
                Text(buttonTitle)
                    .font(.headline)

                Image(systemName: buttonIcon)
                    .font(.subheadline)
            }
            .foregroundStyle(Color.studioBlack)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.studioGold)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }

    private var buttonTitle: String {
        switch currentStep {
        case .welcome:
            return "Get Started"
        case .camera:
            return cameraStatus == .notDetermined ? "Enable Camera" : "Continue"
        case .photos:
            return photosStatus == .notDetermined ? "Enable Photos" : "Continue"
        case .complete:
            return "Let's Party"
        }
    }

    private var buttonIcon: String {
        switch currentStep {
        case .welcome:
            return "arrow.right"
        case .camera, .photos:
            return currentStep == .camera && cameraStatus == .notDetermined ? "camera" : "arrow.right"
        case .complete:
            return "sparkles"
        }
    }

    // MARK: - Status Helpers

    private var cameraStatusText: String {
        switch cameraStatus {
        case .authorized: return "Access Granted"
        case .denied, .restricted: return "Access Denied"
        case .notDetermined: return "Not Yet Requested"
        @unknown default: return "Unknown"
        }
    }

    private var cameraStatusColor: Color {
        switch cameraStatus {
        case .authorized: return .green
        case .denied, .restricted: return .red
        case .notDetermined: return .studioGold
        @unknown default: return .studioSilver
        }
    }

    private var photosStatusText: String {
        switch photosStatus {
        case .authorized, .limited: return "Access Granted"
        case .denied, .restricted: return "Access Denied"
        case .notDetermined: return "Not Yet Requested"
        @unknown default: return "Unknown"
        }
    }

    private var photosStatusColor: Color {
        switch photosStatus {
        case .authorized, .limited: return .green
        case .denied, .restricted: return .red
        case .notDetermined: return .studioGold
        @unknown default: return .studioSilver
        }
    }

    // MARK: - Actions

    private func handleAction() {
        switch currentStep {
        case .welcome:
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                currentStep = .camera
            }

        case .camera:
            if cameraStatus == .notDetermined {
                requestCameraPermission()
            } else {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    currentStep = .photos
                }
            }

        case .photos:
            if photosStatus == .notDetermined {
                requestPhotosPermission()
            } else {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    currentStep = .complete
                }
            }

        case .complete:
            onComplete()
        }
    }

    private func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                cameraStatus = granted ? .authorized : .denied
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    currentStep = .photos
                }
            }
        }
    }

    private func requestPhotosPermission() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            DispatchQueue.main.async {
                photosStatus = status
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    currentStep = .complete
                }
            }
        }
    }
}

// MARK: - Permission Step

private enum PermissionStep {
    case welcome
    case camera
    case photos
    case complete
}

// MARK: - Preview

#Preview {
    PermissionsOnboardingView {
        print("Completed")
    }
}
