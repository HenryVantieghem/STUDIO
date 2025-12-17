//
//  CreatePollView.swift
//  STUDIO
//
//  Basel Afterdark Design System
//  Dark luxury, minimal techno, retro-futuristic nightlife
//

import SwiftUI

// MARK: - Create Poll View

struct CreatePollView: View {
    let partyId: UUID
    let guests: [PartyGuest]
    let onPollCreated: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var question = ""
    @State private var pollType: PollType = .custom
    @State private var textOptions: [String] = ["", ""]
    @State private var isCreating = false
    @State private var error: Error?
    @State private var showError = false

    private let socialService = SocialService()

    var isValid: Bool {
        !question.isEmpty && textOptions.filter { !$0.isEmpty }.count >= 2
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.studioBlack
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        // Poll type picker
                        pollTypePicker

                        // Question input
                        questionSection

                        // Options
                        optionsSection

                        // Create button
                        Button {
                            Task {
                                await createPoll()
                            }
                        } label: {
                            if isCreating {
                                ProgressView()
                                    .tint(Color.studioBlack)
                            } else {
                                HStack(spacing: 12) {
                                    Image(systemName: "chart.bar.doc.horizontal")
                                        .font(.system(size: 16, weight: .ultraLight))
                                    Text("CREATE POLL")
                                        .font(StudioTypography.labelLarge)
                                        .tracking(StudioTypography.trackingWide)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                            }
                        }
                        .buttonStyle(.studioPrimary)
                        .disabled(!isValid || isCreating)
                    }
                    .padding(24)
                }
            }
            .navigationTitle("CREATE POLL")
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

    // MARK: - Poll Type Picker

    private var pollTypePicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("POLL TYPE")
                .studioLabelSmall()

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    pollTypeButton(type: .partyMVP, icon: "star", label: "MVP")
                    pollTypeButton(type: .bestDressed, icon: "tshirt", label: "DRESSED")
                    pollTypeButton(type: .bestMoment, icon: "sparkles", label: "MOMENT")
                    pollTypeButton(type: .custom, icon: "questionmark", label: "CUSTOM")
                }
            }
        }
    }

    private func pollTypeButton(type: PollType, icon: String, label: String) -> some View {
        Button {
            withAnimation {
                pollType = type
                updateQuestionForType(type)
            }
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .ultraLight))

                Text(label)
                    .font(StudioTypography.labelSmall)
                    .tracking(StudioTypography.trackingWide)
            }
            .frame(width: 80)
            .padding(.vertical, 16)
            .background(pollType == type ? Color.studioPrimary : Color.studioSurface)
            .foregroundStyle(pollType == type ? Color.studioBlack : Color.studioSecondary)
            .overlay {
                Rectangle()
                    .stroke(pollType == type ? Color.studioPrimary : Color.studioLine, lineWidth: 0.5)
            }
        }
        .buttonStyle(.plain)
    }

    private func updateQuestionForType(_ type: PollType) {
        switch type {
        case .partyMVP:
            question = "Who's the Party MVP tonight?"
        case .bestDressed:
            question = "Who's best dressed at the party?"
        case .bestMoment:
            question = "What was the best moment of the night?"
        case .custom:
            question = ""
        }

        // For user-based polls, populate with guest names
        if type == .partyMVP || type == .bestDressed {
            textOptions = guests.compactMap { $0.user?.displayName ?? $0.user?.username }
            if textOptions.count < 2 {
                textOptions = ["", ""]
            }
        } else {
            textOptions = ["", ""]
        }
    }

    // MARK: - Question Section

    private var questionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("QUESTION")
                .studioLabelSmall()

            TextField("WHAT DO YOU WANT TO ASK?", text: $question, axis: .vertical)
                .font(StudioTypography.bodyMedium)
                .tracking(StudioTypography.trackingNormal)
                .textInputAutocapitalization(.characters)
                .lineLimit(2...4)
                .padding()
                .background(Color.studioSurface)
                .foregroundStyle(Color.studioPrimary)
                .overlay {
                    Rectangle()
                        .stroke(Color.studioLine, lineWidth: 0.5)
                }
        }
    }

    // MARK: - Options Section

    private var optionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("OPTIONS")
                .studioLabelSmall()

            ForEach(Array(textOptions.enumerated()), id: \.offset) { index, _ in
                HStack(spacing: 12) {
                    TextField("OPTION \(index + 1)", text: $textOptions[index])
                        .font(StudioTypography.bodyMedium)
                        .tracking(StudioTypography.trackingNormal)
                        .textInputAutocapitalization(.characters)
                        .padding()
                        .background(Color.studioSurface)
                        .foregroundStyle(Color.studioPrimary)
                        .overlay {
                            Rectangle()
                                .stroke(Color.studioLine, lineWidth: 0.5)
                        }

                    if textOptions.count > 2 {
                        Button {
                            textOptions.remove(at: index)
                        } label: {
                            Rectangle()
                                .fill(Color.studioSurface)
                                .frame(width: 44, height: 44)
                                .overlay {
                                    Image(systemName: "minus")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(Color.studioMuted)
                                }
                                .overlay {
                                    Rectangle()
                                        .stroke(Color.studioLine, lineWidth: 0.5)
                                }
                        }
                    }
                }
            }

            if textOptions.count < 6 {
                Button {
                    textOptions.append("")
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .ultraLight))
                        Text("ADD OPTION")
                            .font(StudioTypography.labelMedium)
                            .tracking(StudioTypography.trackingWide)
                    }
                    .foregroundStyle(Color.studioChrome)
                }
            }
        }
    }

    // MARK: - Create Poll

    private func createPoll() async {
        isCreating = true

        do {
            let validOptions = textOptions.filter { !$0.isEmpty }

            _ = try await socialService.createPoll(
                partyId: partyId,
                question: question,
                pollType: pollType,
                options: validOptions
            )

            onPollCreated()
            dismiss()
        } catch {
            self.error = error
            showError = true
        }

        isCreating = false
    }
}

// MARK: - Preview

#Preview {
    CreatePollView(
        partyId: UUID(),
        guests: [],
        onPollCreated: {}
    )
}
