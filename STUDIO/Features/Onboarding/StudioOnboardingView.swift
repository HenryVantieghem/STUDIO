//
//  StudioOnboardingView.swift
//  STUDIO
//
//  Stunning first-launch experience with Studio 54 glamour
//  Pixel Afterdark Design System
//

import SwiftUI
import AVFoundation
import Photos

// MARK: - Studio Onboarding View

/// Beautiful first-launch experience with disco ball and velvet rope
struct StudioOnboardingView: View {
    var onComplete: () -> Void

    @State private var currentPage = 0
    @State private var showContent = false
    @State private var discoBallRotation: Double = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "sparkles",
            title: "WELCOME TO STUDIO",
            subtitle: "THE PARTY STARTS HERE",
            description: "CREATE UNFORGETTABLE MOMENTS WITH YOUR CREW"
        ),
        OnboardingPage(
            icon: "camera",
            title: "CAPTURE THE NIGHT",
            subtitle: "DUAL CAMERA MODE",
            description: "FRONT AND BACK SIMULTANEOUSLY - NEVER MISS A MOMENT"
        ),
        OnboardingPage(
            icon: "person.3",
            title: "YOUR GUEST LIST",
            subtitle: "CURATE YOUR CREW",
            description: "INVITE UP TO 5 CO-HOSTS AND UNLIMITED GUESTS"
        ),
        OnboardingPage(
            icon: "chart.bar",
            title: "TRACK THE VIBE",
            subtitle: "LIVE PARTY STATS",
            description: "POLLS, STATUS UPDATES, AND REAL-TIME ENGAGEMENT"
        )
    ]

    var body: some View {
        ZStack {
            // Pure black background
            Color.studioBlack.ignoresSafeArea()

            // Animated disco ball ambient light
            DiscoBallAmbient(rotation: discoBallRotation)
                .opacity(0.3)

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button {
                        HapticManager.shared.impact(.light)
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            currentPage = pages.count
                        }
                    } label: {
                        Text("SKIP")
                            .font(StudioTypography.labelSmall)
                            .tracking(StudioTypography.trackingWide)
                            .foregroundStyle(Color.studioMuted)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                Spacer()

                // Page content
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPageView(page: page, isActive: currentPage == index)
                            .tag(index)
                    }

                    // Permissions page
                    PermissionsPageView()
                        .tag(pages.count)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentPage)

                Spacer()

                // Page indicators
                HStack(spacing: 12) {
                    ForEach(0...pages.count, id: \.self) { index in
                        Rectangle()
                            .fill(currentPage == index ? Color.studioChrome : Color.studioLine)
                            .frame(width: currentPage == index ? 24 : 8, height: 4)
                            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: currentPage)
                    }
                }
                .padding(.bottom, 32)

                // Action button
                Button {
                    HapticManager.shared.impact(.medium)
                    if currentPage < pages.count {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            currentPage += 1
                        }
                    } else {
                        onComplete()
                    }
                } label: {
                    HStack(spacing: 12) {
                        Text(currentPage == pages.count ? "ENTER THE PARTY" : "CONTINUE")
                            .font(StudioTypography.labelLarge)
                            .tracking(StudioTypography.trackingWide)

                        Image(systemName: currentPage == pages.count ? "sparkles" : "arrow.right")
                            .font(.system(size: 14, weight: .light))
                    }
                    .foregroundStyle(Color.studioBlack)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.studioChrome)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                showContent = true
            }
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                discoBallRotation = 360
            }
        }
    }
}

// MARK: - Onboarding Page Model

struct OnboardingPage {
    let icon: String
    let title: String
    let subtitle: String
    let description: String
}

// MARK: - Onboarding Page View

struct OnboardingPageView: View {
    let page: OnboardingPage
    let isActive: Bool

    @State private var showIcon = false
    @State private var showText = false

    var body: some View {
        VStack(spacing: 40) {
            // Icon with pixel border
            ZStack {
                // Outer glow
                Rectangle()
                    .fill(Color.studioChrome.opacity(0.1))
                    .frame(width: 140, height: 140)
                    .blur(radius: 30)

                // Icon container
                Rectangle()
                    .fill(Color.studioSurface)
                    .frame(width: 120, height: 120)
                    .overlay {
                        Image(systemName: page.icon)
                            .font(.system(size: 48, weight: .ultraLight))
                            .foregroundStyle(Color.studioChrome)
                    }
                    .overlay {
                        Rectangle()
                            .stroke(Color.studioLine, lineWidth: 1)
                    }
            }
            .scaleEffect(showIcon ? 1 : 0.8)
            .opacity(showIcon ? 1 : 0)

            // Text content
            VStack(spacing: 16) {
                Text(page.subtitle)
                    .font(StudioTypography.labelSmall)
                    .tracking(StudioTypography.trackingWide)
                    .foregroundStyle(Color.studioMuted)

                Text(page.title)
                    .font(StudioTypography.displayMedium)
                    .tracking(StudioTypography.trackingWide)
                    .foregroundStyle(Color.studioPrimary)
                    .multilineTextAlignment(.center)

                Text(page.description)
                    .font(StudioTypography.bodyMedium)
                    .tracking(StudioTypography.trackingNormal)
                    .foregroundStyle(Color.studioSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .offset(y: showText ? 0 : 20)
            .opacity(showText ? 1 : 0)
        }
        .onChange(of: isActive) { _, active in
            if active {
                showIcon = false
                showText = false
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                    showIcon = true
                }
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                    showText = true
                }
            }
        }
        .onAppear {
            if isActive {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                    showIcon = true
                }
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                    showText = true
                }
            }
        }
    }
}

// MARK: - Permissions Page View

struct PermissionsPageView: View {
    @State private var cameraStatus: AVAuthorizationStatus = .notDetermined
    @State private var photosStatus: PHAuthorizationStatus = .notDetermined
    @State private var showContent = false

    var body: some View {
        VStack(spacing: 40) {
            // Icon
            ZStack {
                Rectangle()
                    .fill(Color.studioChrome.opacity(0.1))
                    .frame(width: 140, height: 140)
                    .blur(radius: 30)

                Rectangle()
                    .fill(Color.studioSurface)
                    .frame(width: 120, height: 120)
                    .overlay {
                        Image(systemName: "lock.open")
                            .font(.system(size: 48, weight: .ultraLight))
                            .foregroundStyle(Color.studioChrome)
                    }
                    .overlay {
                        Rectangle()
                            .stroke(Color.studioLine, lineWidth: 1)
                    }
            }
            .scaleEffect(showContent ? 1 : 0.8)
            .opacity(showContent ? 1 : 0)

            // Text
            VStack(spacing: 16) {
                Text("ALMOST THERE")
                    .font(StudioTypography.labelSmall)
                    .tracking(StudioTypography.trackingWide)
                    .foregroundStyle(Color.studioMuted)

                Text("PERMISSIONS")
                    .font(StudioTypography.displayMedium)
                    .tracking(StudioTypography.trackingWide)
                    .foregroundStyle(Color.studioPrimary)

                Text("ENABLE ACCESS TO CAPTURE AND SHARE YOUR PARTY MOMENTS")
                    .font(StudioTypography.bodyMedium)
                    .tracking(StudioTypography.trackingNormal)
                    .foregroundStyle(Color.studioSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .offset(y: showContent ? 0 : 20)
            .opacity(showContent ? 1 : 0)

            // Permission cards
            VStack(spacing: 12) {
                PermissionCard(
                    icon: "camera",
                    title: "CAMERA",
                    description: "CAPTURE PHOTOS AND VIDEOS",
                    isGranted: cameraStatus == .authorized,
                    isPending: cameraStatus == .notDetermined
                ) {
                    requestCameraPermission()
                }

                PermissionCard(
                    icon: "photo.on.rectangle",
                    title: "PHOTO LIBRARY",
                    description: "SAVE AND UPLOAD MEDIA",
                    isGranted: photosStatus == .authorized || photosStatus == .limited,
                    isPending: photosStatus == .notDetermined
                ) {
                    requestPhotosPermission()
                }
            }
            .padding(.horizontal, 24)
            .opacity(showContent ? 1 : 0)
        }
        .onAppear {
            cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
            photosStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)

            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                showContent = true
            }
        }
    }

    private func requestCameraPermission() {
        HapticManager.shared.impact(.light)
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                cameraStatus = granted ? .authorized : .denied
                if granted {
                    HapticManager.shared.notification(.success)
                }
            }
        }
    }

    private func requestPhotosPermission() {
        HapticManager.shared.impact(.light)
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            DispatchQueue.main.async {
                photosStatus = status
                if status == .authorized || status == .limited {
                    HapticManager.shared.notification(.success)
                }
            }
        }
    }
}

// MARK: - Permission Card

struct PermissionCard: View {
    let icon: String
    let title: String
    let description: String
    let isGranted: Bool
    let isPending: Bool
    var action: (() -> Void)?

    var body: some View {
        Button {
            if isPending {
                action?()
            }
        } label: {
            HStack(spacing: 16) {
                // Icon
                Rectangle()
                    .fill(isGranted ? Color.green.opacity(0.2) : Color.studioSurface)
                    .frame(width: 48, height: 48)
                    .overlay {
                        Image(systemName: icon)
                            .font(.system(size: 20, weight: .light))
                            .foregroundStyle(isGranted ? Color.green : Color.studioChrome)
                    }
                    .overlay {
                        Rectangle()
                            .stroke(isGranted ? Color.green.opacity(0.5) : Color.studioLine, lineWidth: 1)
                    }

                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(StudioTypography.labelMedium)
                        .tracking(StudioTypography.trackingNormal)
                        .foregroundStyle(Color.studioPrimary)

                    Text(description)
                        .font(StudioTypography.labelSmall)
                        .tracking(StudioTypography.trackingNormal)
                        .foregroundStyle(Color.studioMuted)
                }

                Spacer()

                // Status
                if isGranted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.green)
                } else if isPending {
                    Text("ENABLE")
                        .font(StudioTypography.labelSmall)
                        .tracking(StudioTypography.trackingNormal)
                        .foregroundStyle(Color.studioChrome)
                } else {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.studioError)
                }
            }
            .padding(16)
            .background(Color.studioDeepBlack)
            .overlay {
                Rectangle()
                    .stroke(isGranted ? Color.green.opacity(0.3) : Color.studioLine, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .disabled(!isPending)
    }
}

// MARK: - Disco Ball Ambient

struct DiscoBallAmbient: View {
    let rotation: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Light rays
                ForEach(0..<8, id: \.self) { index in
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.studioChrome.opacity(0.3), Color.clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 2, height: 300)
                        .offset(y: -150)
                        .rotationEffect(.degrees(Double(index) * 45 + rotation))
                        .blur(radius: 10)
                }
            }
            .position(x: geometry.size.width / 2, y: 100)
        }
    }
}

// MARK: - Preview

#Preview("Onboarding") {
    StudioOnboardingView {
        print("Completed")
    }
}
