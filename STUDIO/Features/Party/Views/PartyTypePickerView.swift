//
//  PartyTypePickerView.swift
//  STUDIO
//
//  Party type, vibe style, and dress code selection
//  Basel Afterdark Design System
//

import SwiftUI

// MARK: - Party Type Picker

struct PartyTypePickerView: View {
    @Binding var selectedType: PartyType?
    @Binding var selectedVibe: VibeStyle?
    @Binding var selectedDressCode: DressCode?

    var body: some View {
        VStack(spacing: 24) {
            // Party Type
            VStack(alignment: .leading, spacing: 12) {
                Text("PARTY TYPE")
                    .font(StudioTypography.labelMedium)
                    .tracking(StudioTypography.trackingWide)
                    .foregroundStyle(Color.studioMuted)

                partyTypeGrid
            }

            // Vibe Style
            VStack(alignment: .leading, spacing: 12) {
                Text("VIBE")
                    .font(StudioTypography.labelMedium)
                    .tracking(StudioTypography.trackingWide)
                    .foregroundStyle(Color.studioMuted)

                vibeStylePicker
            }

            // Dress Code
            VStack(alignment: .leading, spacing: 12) {
                Text("DRESS CODE")
                    .font(StudioTypography.labelMedium)
                    .tracking(StudioTypography.trackingWide)
                    .foregroundStyle(Color.studioMuted)

                dressCodePicker
            }
        }
    }

    // MARK: - Party Type Grid

    private var partyTypeGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 8) {
            ForEach(PartyType.allCases, id: \.self) { type in
                PartyTypeCard(
                    partyType: type,
                    isSelected: selectedType == type
                ) {
                    HapticManager.shared.impact(.light)
                    if selectedType == type {
                        selectedType = nil
                    } else {
                        selectedType = type
                    }
                }
            }
        }
    }

    // MARK: - Vibe Style Picker

    private var vibeStylePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(VibeStyle.allCases, id: \.self) { vibe in
                    Button {
                        HapticManager.shared.impact(.light)
                        if selectedVibe == vibe {
                            selectedVibe = nil
                        } else {
                            selectedVibe = vibe
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(vibe.emoji)
                                .font(.system(size: 16))
                            Text(vibe.label)
                                .font(StudioTypography.labelSmall)
                                .tracking(StudioTypography.trackingNormal)
                        }
                        .foregroundStyle(selectedVibe == vibe ? Color.studioBlack : Color.studioSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(selectedVibe == vibe ? Color.studioChrome : Color.studioSurface)
                        .overlay {
                            Rectangle()
                                .stroke(selectedVibe == vibe ? Color.studioChrome : Color.studioLine, lineWidth: 1)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Dress Code Picker

    private var dressCodePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(DressCode.allCases, id: \.self) { code in
                    Button {
                        HapticManager.shared.impact(.light)
                        if selectedDressCode == code {
                            selectedDressCode = nil
                        } else {
                            selectedDressCode = code
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(code.emoji)
                                .font(.system(size: 16))
                            Text(code.label)
                                .font(StudioTypography.labelSmall)
                                .tracking(StudioTypography.trackingNormal)
                        }
                        .foregroundStyle(selectedDressCode == code ? Color.studioBlack : Color.studioSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(selectedDressCode == code ? Color.studioChrome : Color.studioSurface)
                        .overlay {
                            Rectangle()
                                .stroke(selectedDressCode == code ? Color.studioChrome : Color.studioLine, lineWidth: 1)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Party Type Card

struct PartyTypeCard: View {
    let partyType: PartyType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Emoji
                Text(partyType.emoji)
                    .font(.system(size: 32))

                // Label
                Text(partyType.label)
                    .font(StudioTypography.labelSmall)
                    .tracking(StudioTypography.trackingNormal)
                    .foregroundStyle(isSelected ? Color.studioBlack : Color.studioSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 90)
            .background(isSelected ? Color.studioChrome : Color.studioSurface)
            .overlay {
                Rectangle()
                    .stroke(isSelected ? Color.studioChrome : Color.studioLine, lineWidth: isSelected ? 2 : 1)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Party Info Badges

/// Horizontal row of party info badges
struct PartyInfoBadges: View {
    let partyType: PartyType?
    let vibeStyle: VibeStyle?
    let dressCode: DressCode?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if let type = partyType {
                    PartyTypeBadge(partyType: type)
                }

                if let vibe = vibeStyle {
                    VibeStyleBadge(vibeStyle: vibe)
                }

                if let dress = dressCode {
                    DressCodeBadge(dressCode: dress)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Party Type Picker") {
    struct PreviewWrapper: View {
        @State var selectedType: PartyType? = .nightclub
        @State var selectedVibe: VibeStyle? = .hype
        @State var selectedDressCode: DressCode? = .allBlack

        var body: some View {
            ZStack {
                Color.studioBlack.ignoresSafeArea()

                ScrollView {
                    PartyTypePickerView(
                        selectedType: $selectedType,
                        selectedVibe: $selectedVibe,
                        selectedDressCode: $selectedDressCode
                    )
                    .padding()
                }
            }
        }
    }

    return PreviewWrapper()
}
