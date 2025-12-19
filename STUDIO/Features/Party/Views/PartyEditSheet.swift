//
//  PartyEditSheet.swift
//  STUDIO
//
//  Host controls for editing party details
//  Basel Afterdark Design System
//

import SwiftUI
import PhotosUI
import Supabase

// MARK: - Party Edit Sheet

/// Host-only sheet for editing party details, managing co-hosts and guests
struct PartyEditSheet: View {
    let party: Party
    var onSave: ((Party) -> Void)?
    var onDelete: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    // Edit state
    @State private var title: String
    @State private var description: String
    @State private var location: String
    @State private var partyDate: Date
    @State private var isPublic: Bool

    // Cover photo
    @State private var selectedCoverItem: PhotosPickerItem?
    @State private var newCoverImage: UIImage?

    // Co-host management
    @State private var showAddCoHost = false
    @State private var coHostToRemove: PartyHost?
    @State private var showRemoveCoHostAlert = false

    // Guest management
    @State private var showGuestList = false

    // Danger zone
    @State private var showEndPartyAlert = false
    @State private var showDeletePartyAlert = false

    // Save state
    @State private var isSaving = false
    @State private var error: Error?
    @State private var showError = false

    // User role tracking
    @State private var isCreator: Bool = false
    @State private var currentUserId: UUID?

    /// Check if current user is creator
    private func checkUserRole() async {
        currentUserId = try? await supabase.auth.session.user.id
        guard let userId = currentUserId,
              let hosts = party.hosts else {
            isCreator = false
            return
        }
        isCreator = hosts.contains { $0.userId == userId && $0.role == .creator }
    }

    init(party: Party, onSave: ((Party) -> Void)? = nil, onDelete: (() -> Void)? = nil) {
        self.party = party
        self.onSave = onSave
        self.onDelete = onDelete

        _title = State(initialValue: party.title)
        _description = State(initialValue: party.description ?? "")
        _location = State(initialValue: party.location ?? "")
        _partyDate = State(initialValue: party.partyDate ?? Date())
        _isPublic = State(initialValue: party.isPublic ?? false)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Party Details Section
                    detailsSection

                    sectionDivider

                    // Cover Photo Section
                    coverPhotoSection

                    sectionDivider

                    // Co-Hosts Section
                    coHostsSection

                    sectionDivider

                    // Guest List Section
                    guestListSection

                    sectionDivider

                    // Privacy Section
                    privacySection

                    sectionDivider

                    // Danger Zone (Creator only)
                    if isCreator {
                        dangerZoneSection
                    }

                    Spacer(minLength: 40)
                }
            }
            .background(Color.studioBlack)
            .navigationTitle("EDIT PARTY")
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

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task {
                            await saveChanges()
                        }
                    } label: {
                        if isSaving {
                            ProgressView()
                                .tint(Color.studioChrome)
                        } else {
                            Text("SAVE")
                                .font(StudioTypography.labelMedium)
                                .tracking(StudioTypography.trackingWide)
                                .foregroundStyle(Color.studioChrome)
                        }
                    }
                    .disabled(isSaving)
                }
            }
            .alert("ERROR", isPresented: $showError) {
                Button("OK") { showError = false }
            } message: {
                Text(error?.localizedDescription ?? "Failed to save changes")
            }
            .alert("REMOVE CO-HOST", isPresented: $showRemoveCoHostAlert) {
                Button("CANCEL", role: .cancel) { }
                Button("REMOVE", role: .destructive) {
                    if let host = coHostToRemove {
                        Task {
                            await removeCoHost(host)
                        }
                    }
                }
            } message: {
                if let host = coHostToRemove {
                    Text("Remove \(host.user?.username ?? "this co-host") from the party?")
                }
            }
            .alert("END PARTY", isPresented: $showEndPartyAlert) {
                Button("CANCEL", role: .cancel) { }
                Button("END PARTY", role: .destructive) {
                    Task {
                        await endParty()
                    }
                }
            } message: {
                Text("This will mark the party as ended. Guests can still view memories but no new content can be added.")
            }
            .alert("DELETE PARTY", isPresented: $showDeletePartyAlert) {
                Button("CANCEL", role: .cancel) { }
                Button("DELETE", role: .destructive) {
                    Task {
                        await deleteParty()
                    }
                }
            } message: {
                Text("This will permanently delete the party and all associated content. This action cannot be undone.")
            }
            .sheet(isPresented: $showAddCoHost) {
                AddCoHostSheet(partyId: party.id) {
                    showAddCoHost = false
                }
            }
            .sheet(isPresented: $showGuestList) {
                GuestListSheet(party: party)
            }
            .onChange(of: selectedCoverItem) { _, newValue in
                Task {
                    await loadCoverImage(newValue)
                }
            }
            .task {
                await checkUserRole()
            }
        }
        .tint(Color.studioChrome)
    }

    // MARK: - Section Divider

    private var sectionDivider: some View {
        Rectangle()
            .fill(Color.studioLine)
            .frame(height: 0.5)
    }

    // MARK: - Details Section

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionHeader("PARTY DETAILS")

            // Title
            VStack(alignment: .leading, spacing: 8) {
                Text("TITLE")
                    .font(StudioTypography.labelSmall)
                    .tracking(StudioTypography.trackingWide)
                    .foregroundStyle(Color.studioMuted)

                TextField("", text: $title, prompt: Text("Party title")
                    .foregroundStyle(Color.studioMuted))
                    .font(StudioTypography.bodyMedium)
                    .foregroundStyle(Color.studioPrimary)
                    .textInputAutocapitalization(.words)
                    .padding()
                    .background(Color.studioSurface)
                    .overlay {
                        Rectangle()
                            .stroke(Color.studioLine, lineWidth: 0.5)
                    }
            }

            // Description
            VStack(alignment: .leading, spacing: 8) {
                Text("DESCRIPTION")
                    .font(StudioTypography.labelSmall)
                    .tracking(StudioTypography.trackingWide)
                    .foregroundStyle(Color.studioMuted)

                TextField("", text: $description, prompt: Text("Optional description")
                    .foregroundStyle(Color.studioMuted), axis: .vertical)
                    .font(StudioTypography.bodyMedium)
                    .foregroundStyle(Color.studioPrimary)
                    .lineLimit(3...6)
                    .padding()
                    .background(Color.studioSurface)
                    .overlay {
                        Rectangle()
                            .stroke(Color.studioLine, lineWidth: 0.5)
                    }
            }

            // Location
            VStack(alignment: .leading, spacing: 8) {
                Text("LOCATION")
                    .font(StudioTypography.labelSmall)
                    .tracking(StudioTypography.trackingWide)
                    .foregroundStyle(Color.studioMuted)

                HStack(spacing: 12) {
                    Image(systemName: "mappin")
                        .font(.system(size: 14, weight: .light))
                        .foregroundStyle(Color.studioMuted)

                    TextField("", text: $location, prompt: Text("Add location")
                        .foregroundStyle(Color.studioMuted))
                        .font(StudioTypography.bodyMedium)
                        .foregroundStyle(Color.studioPrimary)
                }
                .padding()
                .background(Color.studioSurface)
                .overlay {
                    Rectangle()
                        .stroke(Color.studioLine, lineWidth: 0.5)
                }
            }

            // Date & Time
            VStack(alignment: .leading, spacing: 8) {
                Text("DATE & TIME")
                    .font(StudioTypography.labelSmall)
                    .tracking(StudioTypography.trackingWide)
                    .foregroundStyle(Color.studioMuted)

                DatePicker("", selection: $partyDate, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .tint(Color.studioChrome)
                    .padding()
                    .background(Color.studioSurface)
                    .overlay {
                        Rectangle()
                            .stroke(Color.studioLine, lineWidth: 0.5)
                    }
            }
        }
        .padding(16)
    }

    // MARK: - Cover Photo Section

    private var coverPhotoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("COVER PHOTO")

            // Current cover or placeholder
            ZStack {
                if let newImage = newCoverImage {
                    Image(uiImage: newImage)
                        .resizable()
                        .scaledToFill()
                } else if let coverUrl = party.coverImageUrl,
                          let url = URL(string: coverUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Color.studioSurface
                    }
                } else {
                    Color.studioSurface
                    Image(systemName: "photo")
                        .font(.system(size: 48, weight: .ultraLight))
                        .foregroundStyle(Color.studioLine)
                }
            }
            .frame(height: 180)
            .frame(maxWidth: .infinity)
            .clipped()
            .overlay {
                Rectangle()
                    .stroke(Color.studioLine, lineWidth: 0.5)
            }

            // Change cover button
            PhotosPicker(
                selection: $selectedCoverItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                HStack(spacing: 8) {
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 14, weight: .light))
                    Text("CHANGE COVER")
                        .font(StudioTypography.labelSmall)
                        .tracking(StudioTypography.trackingNormal)
                }
                .foregroundStyle(Color.studioChrome)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .overlay {
                    Rectangle()
                        .stroke(Color.studioChrome, lineWidth: 0.5)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(16)
    }

    // MARK: - Co-Hosts Section

    private var coHostsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                sectionHeader("CO-HOSTS")

                Spacer()

                if let hosts = party.hosts, hosts.count < 5 {
                    Button {
                        showAddCoHost = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.system(size: 10, weight: .medium))
                            Text("ADD")
                                .font(StudioTypography.labelSmall)
                                .tracking(StudioTypography.trackingNormal)
                        }
                        .foregroundStyle(Color.studioChrome)
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                }
            }

            Text("UP TO 5 CO-HOSTS CAN MANAGE THIS PARTY")
                .font(.system(size: 10, weight: .regular, design: .monospaced))
                .foregroundStyle(Color.studioMuted)

            // Host list
            if let hosts = party.hosts {
                VStack(spacing: 0) {
                    ForEach(hosts) { host in
                        coHostRow(host)

                        if host.id != hosts.last?.id {
                            Rectangle()
                                .fill(Color.studioLine)
                                .frame(height: 0.5)
                        }
                    }
                }
                .background(Color.studioSurface)
                .overlay {
                    Rectangle()
                        .stroke(Color.studioLine, lineWidth: 0.5)
                }
            }
        }
        .padding(16)
    }

    private func coHostRow(_ host: PartyHost) -> some View {
        HStack(spacing: 12) {
            AvatarView(
                url: host.user?.avatarUrl,
                size: .medium
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(host.user?.username.uppercased() ?? "UNKNOWN")
                    .font(StudioTypography.labelSmall)
                    .tracking(StudioTypography.trackingNormal)
                    .foregroundStyle(Color.studioPrimary)

                Text(host.role == .creator ? "CREATOR" : "CO-HOST")
                    .font(.system(size: 9, weight: .regular, design: .monospaced))
                    .foregroundStyle(Color.studioMuted)
            }

            Spacer()

            // Remove button (creator can remove co-hosts, not themselves)
            if isCreator && host.role != .creator {
                Button {
                    coHostToRemove = host
                    showRemoveCoHostAlert = true
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .light))
                        .foregroundStyle(Color.studioMuted)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
            }
        }
        .padding(12)
    }

    // MARK: - Guest List Section

    private var guestListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("GUESTS")

            Button {
                showGuestList = true
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("MANAGE GUEST LIST")
                            .font(StudioTypography.labelMedium)
                            .tracking(StudioTypography.trackingNormal)
                            .foregroundStyle(Color.studioPrimary)

                        Text("\(party.guests?.count ?? 0) INVITED")
                            .font(.system(size: 10, weight: .regular, design: .monospaced))
                            .foregroundStyle(Color.studioMuted)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .light))
                        .foregroundStyle(Color.studioMuted)
                }
                .padding(16)
                .background(Color.studioSurface)
                .overlay {
                    Rectangle()
                        .stroke(Color.studioLine, lineWidth: 0.5)
                }
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
        }
        .padding(16)
    }

    // MARK: - Privacy Section

    private var privacySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("PRIVACY")

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("PUBLIC PARTY")
                        .font(StudioTypography.labelMedium)
                        .tracking(StudioTypography.trackingNormal)
                        .foregroundStyle(Color.studioPrimary)

                    Text("ANYONE CAN VIEW THIS PARTY")
                        .font(.system(size: 10, weight: .regular, design: .monospaced))
                        .foregroundStyle(Color.studioMuted)
                }

                Spacer()

                Toggle("", isOn: $isPublic)
                    .tint(Color.studioChrome)
                    .labelsHidden()
            }
            .padding(16)
            .background(Color.studioSurface)
            .overlay {
                Rectangle()
                    .stroke(Color.studioLine, lineWidth: 0.5)
            }
        }
        .padding(16)
    }

    // MARK: - Danger Zone Section

    private var dangerZoneSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("DANGER ZONE")

            VStack(spacing: 12) {
                // End Party
                Button {
                    showEndPartyAlert = true
                } label: {
                    HStack {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 12, weight: .light))
                        Text("END PARTY")
                            .font(StudioTypography.labelMedium)
                            .tracking(StudioTypography.trackingWide)
                    }
                    .foregroundStyle(Color.studioMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .overlay {
                        Rectangle()
                            .stroke(Color.studioMuted, lineWidth: 0.5)
                    }
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())

                // Delete Party
                Button {
                    showDeletePartyAlert = true
                } label: {
                    HStack {
                        Image(systemName: "trash")
                            .font(.system(size: 12, weight: .light))
                        Text("DELETE PARTY")
                            .font(StudioTypography.labelMedium)
                            .tracking(StudioTypography.trackingWide)
                    }
                    .foregroundStyle(Color.red.opacity(0.8))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .overlay {
                        Rectangle()
                            .stroke(Color.red.opacity(0.5), lineWidth: 0.5)
                    }
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
            }
        }
        .padding(16)
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(StudioTypography.labelSmall)
            .tracking(StudioTypography.trackingWide)
            .foregroundStyle(Color.studioMuted)
    }

    // MARK: - Load Cover Image

    private func loadCoverImage(_ item: PhotosPickerItem?) async {
        guard let item = item else { return }

        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                newCoverImage = image
            }
        } catch {
            self.error = error
            self.showError = true
        }
    }

    // MARK: - Save Changes

    private func saveChanges() async {
        isSaving = true

        do {
            var updatedParty = party
            updatedParty.title = title
            updatedParty.description = description.isEmpty ? nil : description
            updatedParty.locationName = location.isEmpty ? nil : location
            updatedParty.startsAt = partyDate
            updatedParty.privacy = isPublic ? .publicParty : .inviteOnly

            // Upload new cover if changed
            if let newImage = newCoverImage {
                let storageService = StorageService.shared
                if let imageData = newImage.jpegData(compressionQuality: 0.8) {
                    let coverUrl = try await storageService.uploadPartyCover(
                        partyId: party.id,
                        imageData: imageData
                    )
                    updatedParty.coverImageUrl = coverUrl
                }
            }

            // Update party in database
            var updates: [String: AnyEncodable] = [
                "title": AnyEncodable(title),
                "starts_at": AnyEncodable(ISO8601DateFormatter().string(from: partyDate)),
                "privacy": AnyEncodable(isPublic ? "public" : "invite_only")
            ]

            if !description.isEmpty {
                updates["description"] = AnyEncodable(description)
            }
            if !location.isEmpty {
                updates["location_name"] = AnyEncodable(location)
            }
            if let coverUrl = updatedParty.coverImageUrl {
                updates["cover_image_url"] = AnyEncodable(coverUrl)
            }

            try await supabase
                .from("parties")
                .update(updates)
                .eq("id", value: party.id.uuidString)
                .execute()

            onSave?(updatedParty)
            dismiss()

        } catch {
            self.error = error
            self.showError = true
        }

        isSaving = false
    }

    // MARK: - Remove Co-Host

    private func removeCoHost(_ host: PartyHost) async {
        do {
            try await supabase
                .from("party_hosts")
                .delete()
                .eq("id", value: host.id.uuidString)
                .execute()
        } catch {
            self.error = error
            self.showError = true
        }
    }

    // MARK: - End Party

    private func endParty() async {
        do {
            try await supabase
                .from("parties")
                .update(["is_active": false])
                .eq("id", value: party.id.uuidString)
                .execute()

            dismiss()

        } catch {
            self.error = error
            self.showError = true
        }
    }

    // MARK: - Delete Party

    private func deleteParty() async {
        do {
            try await supabase
                .from("parties")
                .delete()
                .eq("id", value: party.id.uuidString)
                .execute()

            onDelete?()
            dismiss()

        } catch {
            self.error = error
            self.showError = true
        }
    }
}

// MARK: - Add Co-Host Sheet

/// Sheet for searching and adding a co-host
struct AddCoHostSheet: View {
    let partyId: UUID
    var onAdded: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var searchResults: [User] = []
    @State private var isSearching = false
    @State private var isAdding = false
    @State private var error: Error?
    @State private var showError = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14, weight: .light))
                        .foregroundStyle(Color.studioMuted)

                    TextField("", text: $searchText, prompt: Text("Search users...")
                        .foregroundStyle(Color.studioMuted))
                        .font(StudioTypography.bodyMedium)
                        .foregroundStyle(Color.studioPrimary)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                .padding()
                .background(Color.studioSurface)
                .overlay {
                    Rectangle()
                        .stroke(Color.studioLine, lineWidth: 0.5)
                }
                .padding(16)

                // Results
                if isSearching {
                    Spacer()
                    ProgressView()
                        .tint(Color.studioChrome)
                    Spacer()
                } else if searchResults.isEmpty && !searchText.isEmpty {
                    Spacer()
                    Text("NO USERS FOUND")
                        .font(StudioTypography.labelSmall)
                        .tracking(StudioTypography.trackingWide)
                        .foregroundStyle(Color.studioMuted)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(searchResults) { user in
                                userRow(user)
                            }
                        }
                    }
                }
            }
            .background(Color.studioBlack)
            .navigationTitle("ADD CO-HOST")
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
                Text(error?.localizedDescription ?? "Failed to add co-host")
            }
            .onChange(of: searchText) { _, newValue in
                Task {
                    await searchUsers(query: newValue)
                }
            }
        }
        .tint(Color.studioChrome)
    }

    private func userRow(_ user: User) -> some View {
        HStack(spacing: 12) {
            AvatarView(url: user.avatarUrl, size: .medium)

            VStack(alignment: .leading, spacing: 2) {
                Text(user.username.uppercased())
                    .font(StudioTypography.labelSmall)
                    .tracking(StudioTypography.trackingNormal)
                    .foregroundStyle(Color.studioPrimary)

                if let displayName = user.displayName {
                    Text(displayName)
                        .font(.system(size: 10, weight: .regular, design: .monospaced))
                        .foregroundStyle(Color.studioMuted)
                }
            }

            Spacer()

            Button {
                Task {
                    await addCoHost(user)
                }
            } label: {
                if isAdding {
                    ProgressView()
                        .tint(Color.studioChrome)
                } else {
                    Text("ADD")
                        .font(StudioTypography.labelSmall)
                        .tracking(StudioTypography.trackingNormal)
                        .foregroundStyle(Color.studioBlack)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.studioChrome)
                }
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
            .disabled(isAdding)
        }
        .padding(12)
        .background(Color.studioSurface)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.studioLine)
                .frame(height: 0.5)
        }
    }

    private func searchUsers(query: String) async {
        guard query.count >= 2 else {
            searchResults = []
            return
        }

        isSearching = true

        do {
            let results: [User] = try await supabase
                .from("profiles")
                .select()
                .ilike("username", pattern: "%\(query)%")
                .limit(10)
                .execute()
                .value

            searchResults = results
        } catch {
            self.error = error
        }

        isSearching = false
    }

    private func addCoHost(_ user: User) async {
        isAdding = true

        do {
            try await supabase
                .from("party_hosts")
                .insert([
                    "party_id": partyId.uuidString,
                    "user_id": user.id.uuidString,
                    "role": "cohost"
                ])
                .execute()

            onAdded?()
        } catch {
            self.error = error
            self.showError = true
        }

        isAdding = false
    }
}

// MARK: - Guest List Sheet

/// Sheet for managing party guests
struct GuestListSheet: View {
    let party: Party

    @Environment(\.dismiss) private var dismiss
    @State private var guests: [PartyGuest] = []
    @State private var isLoading = true
    @State private var showInviteSheet = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Stats bar
                HStack(spacing: 24) {
                    guestStat(count: guests.filter { $0.status == .accepted }.count, label: "GOING")
                    guestStat(count: guests.filter { $0.status == .pending }.count, label: "PENDING")
                    guestStat(count: guests.filter { $0.status == .declined }.count, label: "DECLINED")
                }
                .padding(16)
                .background(Color.studioSurface)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(Color.studioLine)
                        .frame(height: 0.5)
                }

                // Guest list
                if isLoading {
                    Spacer()
                    ProgressView()
                        .tint(Color.studioChrome)
                    Spacer()
                } else if guests.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "person.2")
                            .font(.system(size: 48, weight: .ultraLight))
                            .foregroundStyle(Color.studioLine)

                        Text("NO GUESTS YET")
                            .font(StudioTypography.labelMedium)
                            .tracking(StudioTypography.trackingWide)
                            .foregroundStyle(Color.studioMuted)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(guests) { guest in
                                guestRow(guest)
                            }
                        }
                    }
                }
            }
            .background(Color.studioBlack)
            .navigationTitle("GUESTS")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("DONE") {
                        dismiss()
                    }
                    .font(StudioTypography.labelMedium)
                    .tracking(StudioTypography.trackingWide)
                    .foregroundStyle(Color.studioMuted)
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showInviteSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .light))
                            .foregroundStyle(Color.studioChrome)
                    }
                }
            }
            .task {
                await loadGuests()
            }
        }
        .tint(Color.studioChrome)
    }

    private func guestStat(count: Int, label: String) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.system(size: 24, weight: .light, design: .monospaced))
                .foregroundStyle(Color.studioPrimary)

            Text(label)
                .font(.system(size: 9, weight: .regular, design: .monospaced))
                .foregroundStyle(Color.studioMuted)
        }
    }

    private func guestRow(_ guest: PartyGuest) -> some View {
        HStack(spacing: 12) {
            AvatarView(url: guest.user?.avatarUrl, size: .medium)

            VStack(alignment: .leading, spacing: 2) {
                Text(guest.user?.username.uppercased() ?? "UNKNOWN")
                    .font(StudioTypography.labelSmall)
                    .tracking(StudioTypography.trackingNormal)
                    .foregroundStyle(Color.studioPrimary)

                Text(guest.status.rawValue.uppercased())
                    .font(.system(size: 9, weight: .regular, design: .monospaced))
                    .foregroundStyle(statusColor(guest.status))
            }

            Spacer()
        }
        .padding(12)
        .background(Color.studioSurface)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.studioLine)
                .frame(height: 0.5)
        }
    }

    private func statusColor(_ status: GuestStatus) -> Color {
        switch status {
        case .accepted: return Color.studioChrome
        case .pending: return Color.studioMuted
        case .declined: return Color.studioMuted.opacity(0.5)
        case .maybe: return Color.studioSecondary
        }
    }

    private func loadGuests() async {
        isLoading = true

        do {
            let results: [PartyGuest] = try await supabase
                .from("party_guests")
                .select("*, user:profiles(*)")
                .eq("party_id", value: party.id.uuidString)
                .execute()
                .value

            guests = results
        } catch {
            print("Failed to load guests: \(error)")
        }

        isLoading = false
    }
}

// MARK: - Preview

#Preview("Edit Sheet") {
    PartyEditSheet(party: MockData.party)
}

#Preview("Add Co-Host") {
    AddCoHostSheet(partyId: UUID())
}

#Preview("Guest List") {
    GuestListSheet(party: MockData.party)
}
