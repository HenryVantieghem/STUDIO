//
//  PartyRatingSheet.swift
//  STUDIO
//
//  Rate parties and hosts after attending
//  Basel Afterdark Design System
//

import SwiftUI

// MARK: - Party Rating Sheet

struct PartyRatingSheet: View {
    let party: Party
    var onSubmit: ((RatePartyRequest) -> Void)?

    @Environment(\.dismiss) private var dismiss

    @State private var overallRating = 0
    @State private var vibeRating = 0
    @State private var musicRating = 0
    @State private var crowdRating = 0
    @State private var venueRating = 0
    @State private var comment = ""
    @State private var isSubmitting = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Party info header
                    partyHeader

                    // Overall rating (required)
                    VStack(spacing: 12) {
                        Text("OVERALL RATING")
                            .font(StudioTypography.labelMedium)
                            .tracking(StudioTypography.trackingWide)
                            .foregroundStyle(Color.studioMuted)

                        SkeuomorphicStarRating(rating: $overallRating, size: 40)

                        if overallRating > 0 {
                            Text(ratingLabel(overallRating))
                                .font(StudioTypography.headlineMedium)
                                .tracking(StudioTypography.trackingWide)
                                .foregroundStyle(Color.studioChrome)
                        }
                    }

                    // Detailed ratings
                    VStack(spacing: 20) {
                        Text("RATE THE DETAILS")
                            .font(StudioTypography.labelMedium)
                            .tracking(StudioTypography.trackingWide)
                            .foregroundStyle(Color.studioMuted)

                        DetailRatingRow(title: "VIBE", emoji: "✨", rating: $vibeRating)
                        DetailRatingRow(title: "MUSIC", emoji: "🎵", rating: $musicRating)
                        DetailRatingRow(title: "CROWD", emoji: "👥", rating: $crowdRating)
                        DetailRatingRow(title: "VENUE", emoji: "📍", rating: $venueRating)
                    }

                    // Comment
                    VStack(alignment: .leading, spacing: 8) {
                        Text("COMMENTS (OPTIONAL)")
                            .font(StudioTypography.labelSmall)
                            .tracking(StudioTypography.trackingWide)
                            .foregroundStyle(Color.studioMuted)

                        TextField("", text: $comment, prompt: Text("Share your thoughts...")
                            .font(StudioTypography.bodyMedium)
                            .foregroundStyle(Color.studioMuted), axis: .vertical)
                            .font(StudioTypography.bodyMedium)
                            .foregroundStyle(Color.studioPrimary)
                            .lineLimit(3...6)
                            .padding()
                            .background(Color.studioDeepBlack)
                            .overlay {
                                Rectangle()
                                    .stroke(Color.studioLine, lineWidth: 1)
                            }
                    }
                }
                .padding(16)
            }
            .background(Color.studioSurface)
            .navigationTitle("RATE PARTY")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("CANCEL") {
                        dismiss()
                    }
                    .font(StudioTypography.labelMedium)
                    .foregroundStyle(Color.studioMuted)
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        submitRating()
                    } label: {
                        if isSubmitting {
                            ProgressView()
                                .tint(Color.studioChrome)
                        } else {
                            Text("SUBMIT")
                                .font(StudioTypography.labelMedium)
                                .foregroundStyle(overallRating > 0 ? Color.studioChrome : Color.studioMuted)
                        }
                    }
                    .disabled(overallRating == 0 || isSubmitting)
                }
            }
        }
    }

    // MARK: - Party Header

    private var partyHeader: some View {
        VStack(spacing: 12) {
            // Party emoji based on type
            if let type = party.partyType {
                SkeuomorphicEmoji(
                    emoji: type.emoji,
                    size: .large,
                    showGlow: true
                )
            } else {
                SkeuomorphicEmoji(
                    emoji: "🎉",
                    size: .large,
                    showGlow: true
                )
            }

            Text(party.title.uppercased())
                .font(StudioTypography.headlineMedium)
                .tracking(StudioTypography.trackingWide)
                .foregroundStyle(Color.studioPrimary)
                .multilineTextAlignment(.center)

            if let date = party.partyDate {
                Text(date.formatted(date: .abbreviated, time: .omitted).uppercased())
                    .font(StudioTypography.labelSmall)
                    .tracking(StudioTypography.trackingNormal)
                    .foregroundStyle(Color.studioMuted)
            }
        }
        .padding(.vertical, 16)
    }

    // MARK: - Helpers

    private func ratingLabel(_ rating: Int) -> String {
        switch rating {
        case 1: return "NEEDS WORK"
        case 2: return "DECENT"
        case 3: return "GOOD"
        case 4: return "GREAT"
        case 5: return "LEGENDARY"
        default: return ""
        }
    }

    private func submitRating() {
        isSubmitting = true
        HapticManager.shared.notification(.success)

        let request = RatePartyRequest(
            partyId: party.id,
            overallRating: overallRating,
            vibeRating: vibeRating > 0 ? vibeRating : nil,
            musicRating: musicRating > 0 ? musicRating : nil,
            crowdRating: crowdRating > 0 ? crowdRating : nil,
            venueRating: venueRating > 0 ? venueRating : nil,
            comment: comment.isEmpty ? nil : comment
        )

        onSubmit?(request)
        dismiss()
    }
}

// MARK: - Detail Rating Row

struct DetailRatingRow: View {
    let title: String
    let emoji: String
    @Binding var rating: Int

    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Text(emoji)
                    .font(.system(size: 20))

                Text(title)
                    .font(StudioTypography.labelMedium)
                    .tracking(StudioTypography.trackingNormal)
                    .foregroundStyle(Color.studioSecondary)
            }

            Spacer()

            // Small star rating
            HStack(spacing: 6) {
                ForEach(1...5, id: \.self) { star in
                    Button {
                        HapticManager.shared.impact(.light)
                        rating = star
                    } label: {
                        Image(systemName: star <= rating ? "star.fill" : "star")
                            .font(.system(size: 16, weight: .light))
                            .foregroundStyle(star <= rating ? Color.studioChrome : Color.studioLine)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(12)
        .background(Color.studioDeepBlack)
        .overlay {
            Rectangle()
                .stroke(Color.studioLine, lineWidth: 0.5)
        }
    }
}

// MARK: - Host Rating Sheet

struct HostRatingSheet: View {
    let host: User
    let party: Party
    var onSubmit: ((Int, String?) -> Void)?

    @Environment(\.dismiss) private var dismiss

    @State private var rating = 0
    @State private var comment = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // Host info
                VStack(spacing: 16) {
                    AvatarView(url: host.avatarUrl, size: .xlarge)

                    Text(host.displayName?.uppercased() ?? host.username.uppercased())
                        .font(StudioTypography.headlineMedium)
                        .tracking(StudioTypography.trackingWide)
                        .foregroundStyle(Color.studioPrimary)

                    Text("HOST")
                        .font(StudioTypography.labelSmall)
                        .tracking(StudioTypography.trackingWide)
                        .foregroundStyle(Color.studioChrome)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.studioChrome.opacity(0.2))
                }

                // Rating
                VStack(spacing: 12) {
                    Text("RATE THIS HOST")
                        .font(StudioTypography.labelMedium)
                        .tracking(StudioTypography.trackingWide)
                        .foregroundStyle(Color.studioMuted)

                    SkeuomorphicStarRating(rating: $rating, size: 40)

                    if rating > 0 {
                        Text(hostRatingLabel(rating))
                            .font(StudioTypography.headlineMedium)
                            .tracking(StudioTypography.trackingWide)
                            .foregroundStyle(Color.studioChrome)
                    }
                }

                // Comment
                VStack(alignment: .leading, spacing: 8) {
                    Text("FEEDBACK (OPTIONAL)")
                        .font(StudioTypography.labelSmall)
                        .tracking(StudioTypography.trackingWide)
                        .foregroundStyle(Color.studioMuted)

                    TextField("", text: $comment, prompt: Text("How was the host?")
                        .font(StudioTypography.bodyMedium)
                        .foregroundStyle(Color.studioMuted), axis: .vertical)
                        .font(StudioTypography.bodyMedium)
                        .foregroundStyle(Color.studioPrimary)
                        .lineLimit(2...4)
                        .padding()
                        .background(Color.studioDeepBlack)
                        .overlay {
                            Rectangle()
                                .stroke(Color.studioLine, lineWidth: 1)
                        }
                }
                .padding(.horizontal, 16)

                Spacer()

                // Submit button
                Button {
                    HapticManager.shared.notification(.success)
                    onSubmit?(rating, comment.isEmpty ? nil : comment)
                    dismiss()
                } label: {
                    Text("SUBMIT RATING")
                        .font(StudioTypography.labelLarge)
                        .tracking(StudioTypography.trackingWide)
                        .foregroundStyle(rating > 0 ? Color.studioBlack : Color.studioMuted)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(rating > 0 ? Color.studioChrome : Color.studioSurface)
                        .overlay {
                            if rating == 0 {
                                Rectangle()
                                    .stroke(Color.studioLine, lineWidth: 1)
                            }
                        }
                }
                .buttonStyle(.plain)
                .disabled(rating == 0)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .padding(.top, 32)
            .background(Color.studioSurface)
            .navigationTitle("RATE HOST")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("CANCEL") {
                        dismiss()
                    }
                    .font(StudioTypography.labelMedium)
                    .foregroundStyle(Color.studioMuted)
                }
            }
        }
    }

    private func hostRatingLabel(_ rating: Int) -> String {
        switch rating {
        case 1: return "COULD IMPROVE"
        case 2: return "OKAY HOST"
        case 3: return "GOOD HOST"
        case 4: return "GREAT HOST"
        case 5: return "AMAZING HOST"
        default: return ""
        }
    }
}

// MARK: - Rating Summary Card

/// Shows average rating for a party or host
struct RatingSummaryCard: View {
    let averageRating: Double
    let totalRatings: Int
    let title: String

    var body: some View {
        HStack(spacing: 16) {
            // Large rating number
            VStack(spacing: 2) {
                Text(String(format: "%.1f", averageRating))
                    .font(StudioTypography.displayMedium)
                    .tracking(StudioTypography.trackingNormal)
                    .foregroundStyle(Color.studioPrimary)

                Text("/5")
                    .font(StudioTypography.labelSmall)
                    .foregroundStyle(Color.studioMuted)
            }

            // Stars and count
            VStack(alignment: .leading, spacing: 4) {
                // Stars
                HStack(spacing: 4) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: starIcon(for: star))
                            .font(.system(size: 16, weight: .light))
                            .foregroundStyle(Color.studioChrome)
                    }
                }

                Text("\(totalRatings) \(title)")
                    .font(StudioTypography.labelSmall)
                    .tracking(StudioTypography.trackingNormal)
                    .foregroundStyle(Color.studioMuted)
            }

            Spacer()
        }
        .padding(16)
        .background(Color.studioSurface)
        .overlay {
            Rectangle()
                .stroke(Color.studioLine, lineWidth: 1)
        }
    }

    private func starIcon(for position: Int) -> String {
        let rating = averageRating
        if Double(position) <= rating {
            return "star.fill"
        } else if Double(position) - 0.5 <= rating {
            return "star.leadinghalf.filled"
        } else {
            return "star"
        }
    }
}

// MARK: - Preview

#Preview("Party Rating") {
    PartyRatingSheet(
        party: Party(
            id: UUID(),
            createdAt: Date(),
            title: "Basel Afterdark",
            description: nil,
            coverImageUrl: nil,
            location: "Secret Location",
            partyDate: Date(),
            endDate: nil,
            isActive: false,
            isPublic: true,
            maxGuests: nil,
            partyType: .nightclub,
            vibeStyle: .hype,
            dressCode: .allBlack
        )
    )
}
