//
//  PartyManagementView.swift
//  STUDIO
//
//  Comprehensive party management for hosts
//  Edit, invite, requests, and host controls
//  Basel Afterdark Design System
//

import SwiftUI

// MARK: - Party Management View

/// Full party management hub for hosts
struct PartyManagementView: View {
    let party: Party
    let isHost: Bool
    var onUpdate: ((Party) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var selectedSection: ManagementSection = .details
    @State private var showEditSheet = false
    @State private var showInviteSheet = false
    @State private var showEndPartyAlert = false
    @State private var isLoading = false

    enum ManagementSection: String, CaseIterable {
        case details = "DETAILS"
        case guests = "GUESTS"
        case hosts = "HOSTS"
        case requests = "REQUESTS"
        case settings = "SETTINGS"

        var icon: String {
            switch self {
            case .details: return "info.circle"
            case .guests: return "person.2"
            case .hosts: return "crown"
            case .requests: return "bell.badge"
            case .settings: return "gear"
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Section tabs
                sectionTabs

                // Content
                TabView(selection: $selectedSection) {
                    detailsSection.tag(ManagementSection.details)
                    guestsSection.tag(ManagementSection.guests)
                    hostsSection.tag(ManagementSection.hosts)
                    requestsSection.tag(ManagementSection.requests)
                    settingsSection.tag(ManagementSection.settings)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .background(Color.studioBlack)
            .navigationTitle("MANAGE PARTY")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("DONE") {
                        dismiss()
                    }
                    .font(StudioTypography.labelMedium)
                    .foregroundStyle(Color.studioChrome)
                }
            }
            .sheet(isPresented: $showEditSheet) {
                PartyEditSheet(party: party) { updatedParty in
                    onUpdate?(updatedParty)
                }
            }
            .sheet(isPresented: $showInviteSheet) {
                InviteGuestsView(partyId: party.id)
            }
            .alert("END PARTY", isPresented: $showEndPartyAlert) {
                Button("CANCEL", role: .cancel) { }
                Button("END PARTY", role: .destructive) {
                    Task { await endParty() }
                }
            } message: {
                Text("This will mark the party as ended. Guests can still view memories.")
            }
        }
    }

    // MARK: - Section Tabs

    private var sectionTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(ManagementSection.allCases, id: \.self) { section in
                    Button {
                        HapticManager.shared.impact(.light)
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedSection = section
                        }
                    } label: {
                        VStack(spacing: 6) {
                            HStack(spacing: 6) {
                                Image(systemName: section.icon)
                                    .font(.system(size: 14, weight: .light))
                                Text(section.rawValue)
                                    .font(StudioTypography.labelSmall)
                                    .tracking(StudioTypography.trackingNormal)
                            }
                            .foregroundStyle(selectedSection == section ? Color.studioChrome : Color.studioMuted)

                            Rectangle()
                                .fill(selectedSection == section ? Color.studioChrome : Color.clear)
                                .frame(height: 2)
                        }
                        .padding(.horizontal, 16)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 12)
        }
        .background(Color.studioDeepBlack)
    }

    // MARK: - Details Section

    private var detailsSection: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Party info card
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        if let type = party.partyType {
                            Text(type.emoji)
                                .font(.system(size: 32))
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(party.title.uppercased())
                                .font(StudioTypography.headlineMedium)
                                .tracking(StudioTypography.trackingWide)
                                .foregroundStyle(Color.studioPrimary)

                            if let type = party.partyType {
                                Text(type.label)
                                    .font(StudioTypography.labelSmall)
                                    .foregroundStyle(Color.studioChrome)
                            }
                        }

                        Spacer()

                        // Status badge
                        Text(party.isActive ? "ACTIVE" : "ENDED")
                            .font(StudioTypography.labelSmall)
                            .tracking(StudioTypography.trackingWide)
                            .foregroundStyle(party.isActive ? Color.studioChrome : Color.studioMuted)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(party.isActive ? Color.studioChrome.opacity(0.2) : Color.studioSurface)
                            .overlay {
                                Rectangle()
                                    .stroke(party.isActive ? Color.studioChrome : Color.studioLine, lineWidth: 1)
                            }
                    }

                    Rectangle()
                        .fill(Color.studioLine)
                        .frame(height: 1)

                    // Details
                    if let location = party.location {
                        detailRow(icon: "mappin", label: "LOCATION", value: location)
                    }

                    if let date = party.partyDate {
                        detailRow(icon: "calendar", label: "DATE", value: date.formatted(date: .abbreviated, time: .shortened))
                    }

                    if let maxGuests = party.maxGuests {
                        let currentGuests = party.guests?.filter { $0.status == .accepted }.count ?? 0
                        detailRow(icon: "person.2", label: "CAPACITY", value: "\(currentGuests)/\(maxGuests)")
                    }

                    if let vibe = party.vibeStyle {
                        detailRow(icon: "sparkles", label: "VIBE", value: vibe.emoji + " " + vibe.label)
                    }

                    if let dress = party.dressCode {
                        detailRow(icon: "tshirt", label: "DRESS CODE", value: dress.emoji + " " + dress.label)
                    }
                }
                .padding(16)
                .background(Color.studioSurface)
                .overlay {
                    Rectangle()
                        .stroke(Color.studioLine, lineWidth: 1)
                }

                // Edit button
                if isHost {
                    Button {
                        HapticManager.shared.impact(.medium)
                        showEditSheet = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "pencil")
                                .font(.system(size: 14, weight: .light))
                            Text("EDIT DETAILS")
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
            }
            .padding(16)
        }
    }

    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .light))
                .foregroundStyle(Color.studioMuted)
                .frame(width: 20)

            Text(label)
                .font(StudioTypography.labelSmall)
                .tracking(StudioTypography.trackingNormal)
                .foregroundStyle(Color.studioMuted)

            Spacer()

            Text(value.uppercased())
                .font(StudioTypography.labelMedium)
                .foregroundStyle(Color.studioPrimary)
        }
    }

    // MARK: - Guests Section

    private var guestsSection: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Stats
                HStack(spacing: 16) {
                    guestStatCard(
                        count: party.guests?.filter { $0.status == .accepted }.count ?? 0,
                        label: "GOING",
                        color: Color.studioChrome
                    )
                    guestStatCard(
                        count: party.guests?.filter { $0.status == .pending }.count ?? 0,
                        label: "PENDING",
                        color: Color.studioMuted
                    )
                    guestStatCard(
                        count: party.guests?.filter { $0.status == .maybe }.count ?? 0,
                        label: "MAYBE",
                        color: Color.studioMuted
                    )
                }

                // Invite button
                if isHost {
                    Button {
                        HapticManager.shared.impact(.medium)
                        showInviteSheet = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 14, weight: .light))
                            Text("INVITE GUESTS")
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

                // Guest list
                VStack(alignment: .leading, spacing: 12) {
                    Text("GUEST LIST")
                        .font(StudioTypography.labelSmall)
                        .tracking(StudioTypography.trackingWide)
                        .foregroundStyle(Color.studioMuted)

                    if let guests = party.guests, !guests.isEmpty {
                        ForEach(guests, id: \.id) { guest in
                            GuestManagementRow(
                                guest: guest,
                                isHost: isHost,
                                onRemove: {
                                    Task { await removeGuest(guest) }
                                }
                            )
                        }
                    } else {
                        EmptyStateView(
                            icon: "person.2",
                            title: "NO GUESTS YET",
                            message: "Invite friends to your party"
                        )
                    }
                }
            }
            .padding(16)
        }
    }

    private func guestStatCard(count: Int, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(StudioTypography.headlineLarge)
                .foregroundStyle(color)

            Text(label)
                .font(StudioTypography.labelSmall)
                .tracking(StudioTypography.trackingNormal)
                .foregroundStyle(Color.studioMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.studioSurface)
        .overlay {
            Rectangle()
                .stroke(Color.studioLine, lineWidth: 1)
        }
    }

    // MARK: - Hosts Section

    private var hostsSection: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Current hosts
                VStack(alignment: .leading, spacing: 12) {
                    Text("CURRENT HOSTS (\(party.hosts?.count ?? 0)/5)")
                        .font(StudioTypography.labelSmall)
                        .tracking(StudioTypography.trackingWide)
                        .foregroundStyle(Color.studioMuted)

                    if let hosts = party.hosts {
                        ForEach(hosts, id: \.id) { host in
                            HostManagementRow(
                                host: host,
                                canRemove: isHost && host.role != .creator,
                                onRemove: {
                                    Task { await removeHost(host) }
                                }
                            )
                        }
                    }
                }

                // Add co-host
                if isHost && (party.hosts?.count ?? 0) < 5 {
                    Button {
                        HapticManager.shared.impact(.medium)
                        // TODO: Show add co-host sheet
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 14, weight: .light))
                            Text("ADD CO-HOST")
                                .font(StudioTypography.labelMedium)
                                .tracking(StudioTypography.trackingNormal)
                        }
                        .foregroundStyle(Color.studioChrome)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.studioSurface)
                        .overlay {
                            Rectangle()
                                .stroke(Color.studioChrome, lineWidth: 1)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
    }

    // MARK: - Requests Section

    private var requestsSection: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Host requests
                HostRequestsSection(partyId: party.id)

                // Join requests (if public party)
                if party.isPublic == true {
                    JoinRequestsSection(partyId: party.id, isHost: isHost)
                }
            }
            .padding(16)
        }
    }

    // MARK: - Settings Section

    private var settingsSection: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Party visibility
                VStack(alignment: .leading, spacing: 12) {
                    Text("VISIBILITY")
                        .font(StudioTypography.labelSmall)
                        .tracking(StudioTypography.trackingWide)
                        .foregroundStyle(Color.studioMuted)

                    HStack {
                        Image(systemName: party.isPublic == true ? "globe" : "lock")
                            .font(.system(size: 16, weight: .light))
                            .foregroundStyle(Color.studioMuted)

                        Text(party.isPublic == true ? "PUBLIC" : "PRIVATE")
                            .font(StudioTypography.labelMedium)
                            .foregroundStyle(Color.studioPrimary)

                        Spacer()

                        Text(party.isPublic == true ? "Anyone can discover" : "Invite only")
                            .font(StudioTypography.labelSmall)
                            .foregroundStyle(Color.studioMuted)
                    }
                    .padding(16)
                    .background(Color.studioSurface)
                    .overlay {
                        Rectangle()
                            .stroke(Color.studioLine, lineWidth: 1)
                    }
                }

                // End party
                if isHost && party.isActive {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("DANGER ZONE")
                            .font(StudioTypography.labelSmall)
                            .tracking(StudioTypography.trackingWide)
                            .foregroundStyle(Color.studioError)

                        Button {
                            HapticManager.shared.notification(.warning)
                            showEndPartyAlert = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "stop.circle")
                                    .font(.system(size: 14, weight: .light))
                                Text("END PARTY")
                                    .font(StudioTypography.labelMedium)
                                    .tracking(StudioTypography.trackingNormal)
                            }
                            .foregroundStyle(Color.studioError)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.studioSurface)
                            .overlay {
                                Rectangle()
                                    .stroke(Color.studioError, lineWidth: 1)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(16)
        }
    }

    // MARK: - Actions

    private func removeGuest(_ guest: PartyGuest) async {
        do {
            let service = PartyService()
            try await service.removeGuest(partyId: party.id, userId: guest.userId)
            HapticManager.shared.notification(.success)
        } catch {
            HapticManager.shared.notification(.error)
        }
    }

    private func removeHost(_ host: PartyHost) async {
        do {
            let service = PartyService()
            try await service.removeHost(partyId: party.id, userId: host.userId)
            HapticManager.shared.notification(.success)
        } catch {
            HapticManager.shared.notification(.error)
        }
    }

    private func endParty() async {
        do {
            let service = PartyService()
            try await service.endParty(id: party.id)
            HapticManager.shared.notification(.success)
            dismiss()
        } catch {
            HapticManager.shared.notification(.error)
        }
    }
}

// MARK: - Guest Management Row

struct GuestManagementRow: View {
    let guest: PartyGuest
    let isHost: Bool
    var onRemove: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(url: guest.user?.avatarUrl, size: .medium)

            VStack(alignment: .leading, spacing: 2) {
                Text(guest.user?.displayName?.uppercased() ?? guest.user?.username.uppercased() ?? "GUEST")
                    .font(StudioTypography.labelMedium)
                    .foregroundStyle(Color.studioPrimary)

                Text("@\(guest.user?.username ?? "unknown")")
                    .font(StudioTypography.labelSmall)
                    .foregroundStyle(Color.studioMuted)
            }

            Spacer()

            // Status badge
            Text(guest.status.label)
                .font(StudioTypography.labelSmall)
                .tracking(StudioTypography.trackingNormal)
                .foregroundStyle(statusColor(guest.status))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor(guest.status).opacity(0.2))

            // Remove button
            if isHost {
                Button {
                    HapticManager.shared.impact(.light)
                    onRemove?()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .light))
                        .foregroundStyle(Color.studioMuted)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(Color.studioSurface)
        .overlay {
            Rectangle()
                .stroke(Color.studioLine, lineWidth: 1)
        }
    }

    private func statusColor(_ status: GuestStatus) -> Color {
        switch status {
        case .accepted: return Color.studioChrome
        case .pending: return Color.studioMuted
        case .maybe: return Color.studioMuted
        case .declined: return Color.studioError
        }
    }
}

// MARK: - Host Management Row

struct HostManagementRow: View {
    let host: PartyHost
    let canRemove: Bool
    var onRemove: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(url: host.user?.avatarUrl, size: .medium)

            VStack(alignment: .leading, spacing: 2) {
                Text(host.user?.displayName?.uppercased() ?? host.user?.username.uppercased() ?? "HOST")
                    .font(StudioTypography.labelMedium)
                    .foregroundStyle(Color.studioPrimary)

                Text(host.role == .creator ? "CREATOR" : "CO-HOST")
                    .font(StudioTypography.labelSmall)
                    .foregroundStyle(Color.studioChrome)
            }

            Spacer()

            if host.role == .creator {
                Image(systemName: "crown.fill")
                    .font(.system(size: 14, weight: .light))
                    .foregroundStyle(Color.studioChrome)
            }

            if canRemove {
                Button {
                    HapticManager.shared.impact(.light)
                    onRemove?()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .light))
                        .foregroundStyle(Color.studioMuted)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(Color.studioSurface)
        .overlay {
            Rectangle()
                .stroke(host.role == .creator ? Color.studioChrome : Color.studioLine, lineWidth: host.role == .creator ? 2 : 1)
        }
    }
}

// MARK: - Host Requests Section

struct HostRequestsSection: View {
    let partyId: UUID
    @State private var requests: [HostRequest] = []
    @State private var isLoading = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("HOST REQUESTS")
                    .font(StudioTypography.labelSmall)
                    .tracking(StudioTypography.trackingWide)
                    .foregroundStyle(Color.studioMuted)

                Spacer()

                if !requests.isEmpty {
                    Text("\(requests.count)")
                        .font(StudioTypography.labelSmall)
                        .foregroundStyle(Color.studioChrome)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.studioChrome.opacity(0.2))
                }
            }

            if requests.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 16, weight: .light))
                        .foregroundStyle(Color.studioMuted)

                    Text("No pending requests")
                        .font(StudioTypography.labelSmall)
                        .foregroundStyle(Color.studioMuted)
                }
                .padding(16)
                .frame(maxWidth: .infinity)
                .background(Color.studioSurface)
                .overlay {
                    Rectangle()
                        .stroke(Color.studioLine, lineWidth: 1)
                }
            } else {
                ForEach(requests) { request in
                    HostRequestRow(request: request) { approved in
                        handleRequest(request, approved: approved)
                    }
                }
            }
        }
        .task {
            await loadRequests()
        }
    }

    private func loadRequests() async {
        // TODO: Load from Supabase
    }

    private func handleRequest(_ request: HostRequest, approved: Bool) {
        // TODO: Handle request approval/denial
    }
}

// MARK: - Host Request Model

struct HostRequest: Identifiable, Codable {
    let id: UUID
    let partyId: UUID
    let requestType: HostRequestType
    let userId: UUID
    let message: String?
    let createdAt: Date
    var user: User?

    enum HostRequestType: String, Codable {
        case drinkRun = "drink_run"
        case songRequest = "song_request"
        case announcement = "announcement"
        case help = "help"
        case other = "other"

        var emoji: String {
            switch self {
            case .drinkRun: return "🍺"
            case .songRequest: return "🎵"
            case .announcement: return "📢"
            case .help: return "🙋"
            case .other: return "💬"
            }
        }

        var label: String {
            switch self {
            case .drinkRun: return "DRINK RUN"
            case .songRequest: return "SONG REQUEST"
            case .announcement: return "ANNOUNCEMENT"
            case .help: return "NEED HELP"
            case .other: return "OTHER"
            }
        }
    }
}

// MARK: - Host Request Row

struct HostRequestRow: View {
    let request: HostRequest
    var onAction: ((Bool) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Text(request.requestType.emoji)
                    .font(.system(size: 24))

                VStack(alignment: .leading, spacing: 2) {
                    Text(request.requestType.label)
                        .font(StudioTypography.labelMedium)
                        .foregroundStyle(Color.studioPrimary)

                    Text("FROM @\(request.user?.username ?? "unknown")")
                        .font(StudioTypography.labelSmall)
                        .foregroundStyle(Color.studioMuted)
                }

                Spacer()

                Text(timeAgo(from: request.createdAt))
                    .font(StudioTypography.labelSmall)
                    .foregroundStyle(Color.studioMuted)
            }

            if let message = request.message {
                Text(message)
                    .font(StudioTypography.bodyMedium)
                    .foregroundStyle(Color.studioSecondary)
            }

            HStack(spacing: 8) {
                Button {
                    HapticManager.shared.impact(.medium)
                    onAction?(true)
                } label: {
                    Text("APPROVE")
                        .font(StudioTypography.labelSmall)
                        .tracking(StudioTypography.trackingNormal)
                        .foregroundStyle(Color.studioBlack)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.studioChrome)
                }
                .buttonStyle(.plain)

                Button {
                    HapticManager.shared.impact(.light)
                    onAction?(false)
                } label: {
                    Text("DISMISS")
                        .font(StudioTypography.labelSmall)
                        .tracking(StudioTypography.trackingNormal)
                        .foregroundStyle(Color.studioMuted)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.studioSurface)
                        .overlay {
                            Rectangle()
                                .stroke(Color.studioLine, lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(Color.studioSurface)
        .overlay {
            Rectangle()
                .stroke(Color.studioLine, lineWidth: 1)
        }
    }

    private func timeAgo(from date: Date) -> String {
        let seconds = Int(-date.timeIntervalSinceNow)
        if seconds < 60 { return "JUST NOW" }
        if seconds < 3600 { return "\(seconds / 60)M AGO" }
        if seconds < 86400 { return "\(seconds / 3600)H AGO" }
        return "\(seconds / 86400)D AGO"
    }
}

// MARK: - Join Requests Section

struct JoinRequestsSection: View {
    let partyId: UUID
    let isHost: Bool
    @State private var requests: [PartyGuest] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("JOIN REQUESTS")
                .font(StudioTypography.labelSmall)
                .tracking(StudioTypography.trackingWide)
                .foregroundStyle(Color.studioMuted)

            if requests.isEmpty {
                HStack {
                    Image(systemName: "person.badge.clock")
                        .font(.system(size: 16, weight: .light))
                        .foregroundStyle(Color.studioMuted)

                    Text("No join requests")
                        .font(StudioTypography.labelSmall)
                        .foregroundStyle(Color.studioMuted)
                }
                .padding(16)
                .frame(maxWidth: .infinity)
                .background(Color.studioSurface)
                .overlay {
                    Rectangle()
                        .stroke(Color.studioLine, lineWidth: 1)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Party Management") {
    PartyManagementView(
        party: Party(
            id: UUID(),
            createdAt: Date(),
            title: "Basel Afterdark",
            description: "Secret underground party",
            coverImageUrl: nil,
            location: "Downtown Warehouse",
            partyDate: Date(),
            endDate: nil,
            isActive: true,
            isPublic: false,
            maxGuests: 50,
            partyType: .nightclub,
            vibeStyle: .hype,
            dressCode: .allBlack
        ),
        isHost: true
    )
}
