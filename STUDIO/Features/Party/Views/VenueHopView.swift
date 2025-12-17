//
//  VenueHopView.swift
//  STUDIO
//
//  Multi-location venue hop timeline view
//  Shows party progression from pregame -> main event -> afterparty
//  Basel Afterdark Design System
//

import SwiftUI

// MARK: - Venue Hop Timeline View

struct VenueHopTimelineView: View {
    @Binding var venueHops: [VenueHop]
    var onAddVenue: (() -> Void)?
    var onSelectVenue: ((VenueHop) -> Void)?
    var onSetCurrentVenue: ((VenueHop) -> Void)?
    var isHost: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("VENUE HOP")
                    .font(StudioTypography.labelMedium)
                    .tracking(StudioTypography.trackingWide)
                    .foregroundStyle(Color.studioMuted)

                Spacer()

                if isHost {
                    Button {
                        HapticManager.shared.impact(.light)
                        onAddVenue?()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .medium))
                            Text("ADD")
                                .font(StudioTypography.labelSmall)
                                .tracking(StudioTypography.trackingNormal)
                        }
                        .foregroundStyle(Color.studioChrome)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            // Timeline
            if venueHops.isEmpty {
                emptyState
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        ForEach(Array(venueHops.sorted { $0.sequence < $1.sequence }.enumerated()), id: \.element.id) { index, venue in
                            VenueHopCard(
                                venue: venue,
                                isFirst: index == 0,
                                isLast: index == venueHops.count - 1,
                                isHost: isHost,
                                onTap: {
                                    HapticManager.shared.impact(.light)
                                    onSelectVenue?(venue)
                                },
                                onSetCurrent: {
                                    HapticManager.shared.impact(.medium)
                                    onSetCurrentVenue?(venue)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
        }
        .background(Color.studioDeepBlack)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "map")
                .font(.system(size: 32, weight: .ultraLight))
                .foregroundStyle(Color.studioMuted)

            Text("NO VENUES YET")
                .font(StudioTypography.labelMedium)
                .tracking(StudioTypography.trackingWide)
                .foregroundStyle(Color.studioSecondary)

            if isHost {
                Text("ADD MULTIPLE LOCATIONS TO CREATE A VENUE HOP")
                    .font(StudioTypography.bodySmall)
                    .tracking(StudioTypography.trackingNormal)
                    .foregroundStyle(Color.studioMuted)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 16)
    }
}

// MARK: - Venue Hop Card

struct VenueHopCard: View {
    let venue: VenueHop
    let isFirst: Bool
    let isLast: Bool
    var isHost: Bool = false
    var onTap: (() -> Void)?
    var onSetCurrent: (() -> Void)?

    var body: some View {
        HStack(spacing: 0) {
            // Timeline connector (left)
            if !isFirst {
                Rectangle()
                    .fill(venue.isCurrentVenue ? Color.studioChrome : Color.studioLine)
                    .frame(width: 32, height: 2)
            }

            // Card
            Button {
                onTap?()
            } label: {
                VStack(alignment: .leading, spacing: 8) {
                    // Sequence badge
                    HStack {
                        Text("\(venue.sequence)")
                            .font(StudioTypography.labelSmall)
                            .tracking(StudioTypography.trackingNormal)
                            .foregroundStyle(venue.isCurrentVenue ? Color.studioBlack : Color.studioSecondary)
                            .frame(width: 24, height: 24)
                            .background(venue.isCurrentVenue ? Color.studioChrome : Color.studioSurface)
                            .overlay {
                                Rectangle()
                                    .stroke(venue.isCurrentVenue ? Color.studioChrome : Color.studioLine, lineWidth: 1)
                            }

                        if venue.isCurrentVenue {
                            Text("NOW")
                                .font(StudioTypography.labelSmall)
                                .tracking(StudioTypography.trackingWide)
                                .foregroundStyle(Color.studioChrome)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.studioChrome.opacity(0.2))
                        }

                        Spacer()
                    }

                    // Venue name
                    Text(venue.venueName.uppercased())
                        .font(StudioTypography.labelLarge)
                        .tracking(StudioTypography.trackingNormal)
                        .foregroundStyle(venue.isCurrentVenue ? Color.studioPrimary : Color.studioSecondary)
                        .lineLimit(1)

                    // Location
                    if let location = venue.location {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin")
                                .font(.system(size: 10, weight: .light))
                            Text(location)
                                .font(StudioTypography.bodySmall)
                                .lineLimit(1)
                        }
                        .foregroundStyle(Color.studioMuted)
                    }

                    // Time
                    if let startTime = venue.startTime {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 10, weight: .light))
                            Text(startTime.formatted(date: .omitted, time: .shortened))
                                .font(StudioTypography.bodySmall)
                        }
                        .foregroundStyle(Color.studioMuted)
                    }

                    // Set as current (host only)
                    if isHost && !venue.isCurrentVenue {
                        Button {
                            onSetCurrent?()
                        } label: {
                            Text("SET CURRENT")
                                .font(StudioTypography.labelSmall)
                                .tracking(StudioTypography.trackingNormal)
                                .foregroundStyle(Color.studioChrome)
                                .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(12)
                .frame(width: 160)
                .background(venue.isCurrentVenue ? Color.studioSurface : Color.studioDeepBlack)
                .overlay {
                    Rectangle()
                        .stroke(venue.isCurrentVenue ? Color.studioChrome : Color.studioLine, lineWidth: venue.isCurrentVenue ? 2 : 1)
                }
            }
            .buttonStyle(.plain)

            // Timeline connector (right)
            if !isLast {
                Rectangle()
                    .fill(Color.studioLine)
                    .frame(width: 32, height: 2)
            }
        }
    }
}

// MARK: - Add Venue Sheet

struct AddVenueHopSheet: View {
    let partyId: UUID
    var onAdd: ((AddVenueHopRequest) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var venueName = ""
    @State private var location = ""
    @State private var startTime = Date()
    @State private var hasStartTime = false
    @State private var description = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Venue name
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("VENUE NAME")
                                .font(StudioTypography.labelSmall)
                                .tracking(StudioTypography.trackingWide)
                                .foregroundStyle(Color.studioMuted)

                            Text("*")
                                .foregroundStyle(Color.studioError)
                        }

                        TextField("", text: $venueName, prompt: Text("Enter venue name...")
                            .font(StudioTypography.bodyMedium)
                            .foregroundStyle(Color.studioMuted))
                            .font(StudioTypography.bodyMedium)
                            .foregroundStyle(Color.studioPrimary)
                            .textInputAutocapitalization(.words)
                            .padding()
                            .background(Color.studioDeepBlack)
                            .overlay {
                                Rectangle()
                                    .stroke(Color.studioLine, lineWidth: 1)
                            }
                    }

                    // Location
                    VStack(alignment: .leading, spacing: 8) {
                        Text("LOCATION")
                            .font(StudioTypography.labelSmall)
                            .tracking(StudioTypography.trackingWide)
                            .foregroundStyle(Color.studioMuted)

                        TextField("", text: $location, prompt: Text("Enter address or area...")
                            .font(StudioTypography.bodyMedium)
                            .foregroundStyle(Color.studioMuted))
                            .font(StudioTypography.bodyMedium)
                            .foregroundStyle(Color.studioPrimary)
                            .padding()
                            .background(Color.studioDeepBlack)
                            .overlay {
                                Rectangle()
                                    .stroke(Color.studioLine, lineWidth: 1)
                            }
                    }

                    // Start time
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("START TIME")
                                .font(StudioTypography.labelSmall)
                                .tracking(StudioTypography.trackingWide)
                                .foregroundStyle(Color.studioMuted)

                            Spacer()

                            Toggle("", isOn: $hasStartTime)
                                .labelsHidden()
                                .tint(Color.studioChrome)
                        }

                        if hasStartTime {
                            DatePicker("", selection: $startTime, displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .tint(Color.studioChrome)
                                .padding()
                                .background(Color.studioDeepBlack)
                                .overlay {
                                    Rectangle()
                                        .stroke(Color.studioLine, lineWidth: 1)
                                }
                        }
                    }

                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("NOTES")
                            .font(StudioTypography.labelSmall)
                            .tracking(StudioTypography.trackingWide)
                            .foregroundStyle(Color.studioMuted)

                        TextField("", text: $description, prompt: Text("Add notes about this stop...")
                            .font(StudioTypography.bodyMedium)
                            .foregroundStyle(Color.studioMuted), axis: .vertical)
                            .font(StudioTypography.bodyMedium)
                            .foregroundStyle(Color.studioPrimary)
                            .lineLimit(3...5)
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
            .navigationTitle("ADD VENUE")
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
                        let request = AddVenueHopRequest(
                            partyId: partyId,
                            venueName: venueName,
                            location: location.isEmpty ? nil : location,
                            startTime: hasStartTime ? startTime : nil,
                            description: description.isEmpty ? nil : description
                        )
                        onAdd?(request)
                        dismiss()
                    } label: {
                        Text("ADD")
                            .font(StudioTypography.labelMedium)
                            .foregroundStyle(venueName.isEmpty ? Color.studioMuted : Color.studioChrome)
                    }
                    .disabled(venueName.isEmpty)
                }
            }
        }
    }
}

// MARK: - Venue Hop Progress

/// Compact progress indicator showing current venue in hop
struct VenueHopProgress: View {
    let venueHops: [VenueHop]

    var currentIndex: Int {
        venueHops.firstIndex { $0.isCurrentVenue } ?? 0
    }

    var body: some View {
        if venueHops.count > 1 {
            HStack(spacing: 8) {
                ForEach(Array(venueHops.sorted { $0.sequence < $1.sequence }.enumerated()), id: \.element.id) { index, venue in
                    // Dot
                    Circle()
                        .fill(index <= currentIndex ? Color.studioChrome : Color.studioLine)
                        .frame(width: venue.isCurrentVenue ? 12 : 8, height: venue.isCurrentVenue ? 12 : 8)
                        .overlay {
                            if venue.isCurrentVenue {
                                Circle()
                                    .stroke(Color.studioChrome.opacity(0.5), lineWidth: 2)
                                    .scaleEffect(1.5)
                            }
                        }

                    // Connector
                    if index < venueHops.count - 1 {
                        Rectangle()
                            .fill(index < currentIndex ? Color.studioChrome : Color.studioLine)
                            .frame(width: 16, height: 2)
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Venue Hop Timeline") {
    ZStack {
        Color.studioBlack.ignoresSafeArea()

        VenueHopTimelineView(
            venueHops: .constant([
                VenueHop(
                    id: UUID(),
                    partyId: UUID(),
                    sequence: 1,
                    venueName: "Jake's Place",
                    location: "Williamsburg",
                    startTime: Date(),
                    endTime: nil,
                    description: "Pregame here",
                    isCurrentVenue: false
                ),
                VenueHop(
                    id: UUID(),
                    partyId: UUID(),
                    sequence: 2,
                    venueName: "House of Yes",
                    location: "Brooklyn",
                    startTime: Date().addingTimeInterval(3600),
                    endTime: nil,
                    description: nil,
                    isCurrentVenue: true
                ),
                VenueHop(
                    id: UUID(),
                    partyId: UUID(),
                    sequence: 3,
                    venueName: "Somewhere Secret",
                    location: "TBD",
                    startTime: nil,
                    endTime: nil,
                    description: nil,
                    isCurrentVenue: false
                )
            ]),
            isHost: true
        )
    }
}
