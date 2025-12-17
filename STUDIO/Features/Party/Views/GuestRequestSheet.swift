//
//  GuestRequestSheet.swift
//  STUDIO
//
//  Guest requests to hosts - drink runs, song requests, help, etc.
//  Basel Afterdark Design System
//

import SwiftUI

// MARK: - Guest Request Sheet

/// Sheet for guests to send requests to party hosts
struct GuestRequestSheet: View {
    let partyId: UUID
    var onSubmit: ((HostRequest.HostRequestType, String?) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var selectedType: HostRequest.HostRequestType?
    @State private var message = ""
    @State private var isSubmitting = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Request type selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("WHAT DO YOU NEED?")
                        .font(StudioTypography.labelMedium)
                        .tracking(StudioTypography.trackingWide)
                        .foregroundStyle(Color.studioMuted)

                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(requestTypes, id: \.self) { type in
                            RequestTypeCard(
                                type: type,
                                isSelected: selectedType == type
                            ) {
                                HapticManager.shared.impact(.light)
                                selectedType = type
                            }
                        }
                    }
                }

                // Quick actions for drink run
                if selectedType == .drinkRun {
                    drinkQuickActions
                }

                // Message input
                VStack(alignment: .leading, spacing: 8) {
                    Text("MESSAGE (OPTIONAL)")
                        .font(StudioTypography.labelSmall)
                        .tracking(StudioTypography.trackingWide)
                        .foregroundStyle(Color.studioMuted)

                    TextField("", text: $message, prompt: Text("Add details...")
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

                Spacer()

                // Submit button
                Button {
                    submit()
                } label: {
                    if isSubmitting {
                        ProgressView()
                            .tint(Color.studioBlack)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.studioChrome)
                    } else {
                        Text("SEND REQUEST")
                            .font(StudioTypography.labelLarge)
                            .tracking(StudioTypography.trackingWide)
                            .foregroundStyle(selectedType != nil ? Color.studioBlack : Color.studioMuted)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(selectedType != nil ? Color.studioChrome : Color.studioSurface)
                            .overlay {
                                if selectedType == nil {
                                    Rectangle()
                                        .stroke(Color.studioLine, lineWidth: 1)
                                }
                            }
                    }
                }
                .buttonStyle(.plain)
                .disabled(selectedType == nil || isSubmitting)
            }
            .padding(16)
            .background(Color.studioSurface)
            .navigationTitle("REQUEST")
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

    private var requestTypes: [HostRequest.HostRequestType] {
        [.drinkRun, .songRequest, .help, .announcement, .other]
    }

    // MARK: - Drink Quick Actions

    private var drinkQuickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("QUICK ORDER")
                .font(StudioTypography.labelSmall)
                .tracking(StudioTypography.trackingWide)
                .foregroundStyle(Color.studioMuted)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(quickDrinks, id: \.self) { drink in
                        Button {
                            HapticManager.shared.impact(.light)
                            if message.isEmpty {
                                message = drink
                            } else {
                                message += ", " + drink
                            }
                        } label: {
                            Text(drink)
                                .font(StudioTypography.labelSmall)
                                .foregroundStyle(Color.studioSecondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.studioDeepBlack)
                                .overlay {
                                    Rectangle()
                                        .stroke(Color.studioLine, lineWidth: 1)
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var quickDrinks: [String] {
        ["🍺 BEER", "🍷 WINE", "🥃 WHISKEY", "🍸 COCKTAIL", "💧 WATER", "🧊 ICE"]
    }

    // MARK: - Submit

    private func submit() {
        guard let type = selectedType else { return }

        isSubmitting = true
        HapticManager.shared.notification(.success)

        // Call callback
        onSubmit?(type, message.isEmpty ? nil : message)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            dismiss()
        }
    }
}

// MARK: - Request Type Card

struct RequestTypeCard: View {
    let type: HostRequest.HostRequestType
    let isSelected: Bool
    var action: (() -> Void)?

    var body: some View {
        Button {
            action?()
        } label: {
            VStack(spacing: 8) {
                Text(type.emoji)
                    .font(.system(size: 32))

                Text(type.label)
                    .font(StudioTypography.labelSmall)
                    .tracking(StudioTypography.trackingNormal)
                    .foregroundStyle(isSelected ? Color.studioBlack : Color.studioSecondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(isSelected ? Color.studioChrome : Color.studioDeepBlack)
            .overlay {
                Rectangle()
                    .stroke(isSelected ? Color.studioChrome : Color.studioLine, lineWidth: isSelected ? 2 : 1)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Request Service

/// Service for guest-to-host requests
final class RequestService: Sendable {

    /// Submit a request to party hosts
    func submitRequest(partyId: UUID, type: HostRequest.HostRequestType, message: String?) async throws {
        let userId = try await supabase.auth.session.user.id

        var request: [String: AnyEncodable] = [
            "party_id": AnyEncodable(partyId),
            "user_id": AnyEncodable(userId),
            "request_type": AnyEncodable(type.rawValue)
        ]

        if let message { request["message"] = AnyEncodable(message) }

        try await supabase
            .from("host_requests")
            .insert(request)
            .execute()
    }

    /// Get pending requests for a party (hosts only)
    func getRequests(partyId: UUID) async throws -> [HostRequest] {
        let requests: [HostRequest] = try await supabase
            .from("host_requests")
            .select("*, user:profiles(*)")
            .eq("party_id", value: partyId.uuidString)
            .eq("status", value: "pending")
            .order("created_at", ascending: false)
            .execute()
            .value

        return requests
    }

    /// Approve or dismiss a request
    func handleRequest(requestId: UUID, approved: Bool) async throws {
        let status = approved ? "approved" : "dismissed"

        try await supabase
            .from("host_requests")
            .update(["status": status] as [String: String])
            .eq("id", value: requestId.uuidString)
            .execute()
    }
}

// MARK: - Quick Action Button

/// Floating action button for guest requests
struct QuickRequestButton: View {
    let partyId: UUID
    @State private var showRequestSheet = false

    var body: some View {
        Button {
            HapticManager.shared.impact(.medium)
            showRequestSheet = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 16, weight: .light))
                Text("REQUEST")
                    .font(StudioTypography.labelSmall)
                    .tracking(StudioTypography.trackingNormal)
            }
            .foregroundStyle(Color.studioBlack)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.studioChrome)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showRequestSheet) {
            GuestRequestSheet(partyId: partyId) { type, message in
                Task {
                    try? await RequestService().submitRequest(
                        partyId: partyId,
                        type: type,
                        message: message
                    )
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationBackground(Color.studioSurface)
        }
    }
}

// MARK: - Preview

#Preview("Guest Request Sheet") {
    GuestRequestSheet(partyId: UUID())
}

#Preview("Quick Request Button") {
    ZStack {
        Color.studioBlack.ignoresSafeArea()

        VStack {
            Spacer()

            QuickRequestButton(partyId: UUID())
        }
        .padding()
    }
}
