//
//  StatusPickerView.swift
//  STUDIO
//
//  Basel Afterdark Design System
//  Dark luxury, minimal techno, retro-futuristic nightlife
//

import SwiftUI

// MARK: - Status Picker View

struct StatusPickerView: View {
    let partyId: UUID
    let onStatusPosted: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var selectedType: StatusType = .vibeCheck
    @State private var vibeLevel: Int = 3  // 1-5 scale
    @State private var message = ""
    @State private var isPosting = false
    @State private var error: Error?
    @State private var showError = false

    private let socialService = SocialService()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.studioBlack
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        // Status type picker
                        statusTypePicker

                        // Level slider with visual
                        vibeLevelPicker

                        // Optional message
                        messageInput

                        // Post button
                        Button {
                            Task {
                                await postStatus()
                            }
                        } label: {
                            if isPosting {
                                ProgressView()
                                    .tint(Color.studioBlack)
                            } else {
                                HStack(spacing: 12) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 16, weight: .ultraLight))
                                    Text("SHARE YOUR VIBE")
                                        .font(StudioTypography.labelLarge)
                                        .tracking(StudioTypography.trackingWide)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                            }
                        }
                        .buttonStyle(.studioPrimary)
                        .disabled(isPosting)
                    }
                    .padding(24)
                }
            }
            .navigationTitle("UPDATE STATUS")
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
            .alert("ERROR", isPresented: $showError) {
                Button("OK") { showError = false }
            } message: {
                Text(error?.localizedDescription ?? "An error occurred")
            }
        }
        .tint(Color.studioChrome)
    }

    // MARK: - Status Type Picker

    private var statusTypePicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("WHAT ARE YOU SHARING?")
                .studioLabelSmall()

            HStack(spacing: 8) {
                ForEach([StatusType.vibeCheck, StatusType.drunkMeter], id: \.self) { type in
                    Button {
                        withAnimation {
                            selectedType = type
                        }
                    } label: {
                        VStack(spacing: 10) {
                            Image(systemName: type == .vibeCheck ? "sparkles" : "drop")
                                .font(.system(size: 24, weight: .ultraLight))

                            Text(type == .vibeCheck ? "VIBE CHECK" : "DRUNK METER")
                                .font(StudioTypography.labelSmall)
                                .tracking(StudioTypography.trackingWide)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(selectedType == type ? Color.studioPrimary : Color.studioSurface)
                        .foregroundStyle(selectedType == type ? Color.studioBlack : Color.studioSecondary)
                        .overlay {
                            Rectangle()
                                .stroke(selectedType == type ? Color.studioPrimary : Color.studioLine, lineWidth: 0.5)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Vibe Level Picker

    private var vibeLevelPicker: some View {
        VStack(spacing: 24) {
            // Current level display
            VStack(spacing: 12) {
                Text(currentVibeLevel.emoji)
                    .font(.system(size: 56))

                Text(currentVibeLevel.label.uppercased())
                    .studioHeadlineMedium()

                Text("LEVEL \(vibeLevel)")
                    .font(StudioTypography.labelLarge)
                    .tracking(StudioTypography.trackingWide)
                    .foregroundStyle(Color.studioChrome)
            }
            .padding(.vertical, 20)

            // Slider with custom track
            VStack(spacing: 12) {
                // Custom slider track
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        // Background track
                        Rectangle()
                            .fill(Color.studioSurface)
                            .frame(height: 4)

                        // Active track
                        Rectangle()
                            .fill(sliderColor)
                            .frame(width: geo.size.width * (CGFloat(vibeLevel - 1) / 4), height: 4)
                    }

                    // Level indicators
                    HStack(spacing: 0) {
                        ForEach(1...5, id: \.self) { level in
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    vibeLevel = level
                                }
                            } label: {
                                Rectangle()
                                    .fill(level <= vibeLevel ? sliderColor : Color.studioSurface)
                                    .frame(width: 12, height: 12)
                                    .overlay {
                                        Rectangle()
                                            .stroke(level == vibeLevel ? sliderColor : Color.studioLine, lineWidth: 0.5)
                                    }
                            }
                            .buttonStyle(.plain)

                            if level < 5 {
                                Spacer()
                            }
                        }
                    }
                    .offset(y: -4)
                }
                .frame(height: 12)

                // Labels
                HStack {
                    Text(selectedType == .vibeCheck ? "CHILL" : "SOBER")
                        .font(StudioTypography.labelSmall)
                        .tracking(StudioTypography.trackingNormal)
                        .foregroundStyle(Color.studioMuted)

                    Spacer()

                    Text(selectedType == .vibeCheck ? "PEAK" : "GONE")
                        .font(StudioTypography.labelSmall)
                        .tracking(StudioTypography.trackingNormal)
                        .foregroundStyle(Color.studioMuted)
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(24)
        .background(Color.studioSurface)
        .overlay {
            Rectangle()
                .stroke(Color.studioLine, lineWidth: 0.5)
        }
    }

    private var currentVibeLevel: VibeLevel {
        VibeLevel(rawValue: vibeLevel) ?? .elevated
    }

    private var sliderColor: Color {
        // Monochromatic scale for Basel Afterdark
        switch vibeLevel {
        case 1: return Color.studioMuted
        case 2: return Color.studioSecondary
        case 3: return Color.studioChrome
        case 4: return Color.studioPrimary
        default: return Color.studioPrimary
        }
    }

    // MARK: - Message Input

    private var messageInput: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ADD A MESSAGE (OPTIONAL)")
                .studioLabelSmall()

            TextField("WHAT'S ON YOUR MIND?", text: $message, axis: .vertical)
                .font(StudioTypography.bodyMedium)
                .tracking(StudioTypography.trackingNormal)
                .textInputAutocapitalization(.characters)
                .lineLimit(3...5)
                .padding()
                .background(Color.studioSurface)
                .foregroundStyle(Color.studioPrimary)
                .overlay {
                    Rectangle()
                        .stroke(Color.studioLine, lineWidth: 0.5)
                }
        }
    }

    // MARK: - Post Status

    private func postStatus() async {
        isPosting = true

        do {
            _ = try await socialService.postStatus(
                partyId: partyId,
                statusType: selectedType,
                value: vibeLevel,
                message: message.isEmpty ? nil : message
            )

            onStatusPosted()
            dismiss()
        } catch {
            self.error = error
            showError = true
        }

        isPosting = false
    }
}

// MARK: - Preview

#Preview {
    StatusPickerView(partyId: UUID(), onStatusPosted: {})
}
