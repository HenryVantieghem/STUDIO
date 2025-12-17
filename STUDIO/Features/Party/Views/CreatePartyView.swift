//
//  CreatePartyView.swift
//  STUDIO
//
//  Basel Afterdark Design System
//  Dark luxury, minimal techno, retro-futuristic nightlife
//

import SwiftUI
import MapKit

// MARK: - Create Party View

struct CreatePartyView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var description = ""
    @State private var location = ""
    @State private var partyDate = Date()
    @State private var hasDate = false
    @State private var maxGuests: Int?

    @State private var isCreating = false
    @State private var error: Error?
    @State private var showError = false

    // Location autocomplete state
    @State private var showLocationSearch = false
    @State private var locationSearchQuery = ""
    @State private var locationResults: [MKLocalSearchCompletion] = []
    @State private var searchCompleter = MKLocalSearchCompleter()
    @State private var searchDelegate: LocationSearchDelegate?

    private let partyService = PartyService()

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.studioBlack
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        // Header icon
                        headerSection

                        // Title section
                        titleSection

                        // Description section
                        descriptionSection

                        // Location section with autocomplete
                        locationSection

                        // Date section
                        dateSection

                        // Guest limit section
                        guestLimitSection

                        // Create button
                        createButton

                        Spacer(minLength: 48)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("NEW PARTY")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("CANCEL")
                            .font(StudioTypography.labelSmall)
                            .tracking(StudioTypography.trackingNormal)
                            .foregroundStyle(Color.studioMuted)
                    }
                }
            }
            .alert("ERROR", isPresented: $showError) {
                Button("OK") { showError = false }
            } message: {
                Text(error?.localizedDescription ?? "Failed to create party")
            }
            .sheet(isPresented: $showLocationSearch) {
                LocationSearchSheet(
                    searchQuery: $locationSearchQuery,
                    selectedLocation: $location,
                    isPresented: $showLocationSearch
                )
            }
        }
        .tint(Color.studioChrome)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        Rectangle()
            .fill(Color.studioSurface)
            .frame(width: 72, height: 72)
            .overlay {
                Image(systemName: "plus")
                    .font(.system(size: 28, weight: .ultraLight))
                    .foregroundStyle(Color.studioChrome)
            }
            .overlay {
                Rectangle()
                    .stroke(Color.studioLine, lineWidth: 0.5)
            }
            .padding(.top, 8)
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 4) {
                Text("PARTY NAME")
                    .font(StudioTypography.labelSmall)
                    .tracking(StudioTypography.trackingNormal)
                    .foregroundStyle(Color.studioMuted)

                Text("*")
                    .font(StudioTypography.labelSmall)
                    .foregroundStyle(Color.studioChrome)
            }

            HStack(spacing: 16) {
                Image(systemName: "textformat")
                    .font(.system(size: 16, weight: .ultraLight))
                    .foregroundStyle(Color.studioMuted)

                TextField("", text: $title, prompt: Text("FRIDAY NIGHT DISCO")
                    .font(StudioTypography.bodyMedium)
                    .foregroundStyle(Color.studioMuted.opacity(0.5)))
                    .font(StudioTypography.bodyMedium)
                    .foregroundStyle(Color.studioPrimary)
                    .autocorrectionDisabled()
            }
            .padding(16)
            .background(Color.studioSurface)
            .overlay {
                Rectangle()
                    .stroke(title.isEmpty ? Color.studioLine : Color.studioChrome.opacity(0.5), lineWidth: 0.5)
            }
        }
    }

    // MARK: - Description Section

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text("DESCRIPTION")
                    .font(StudioTypography.labelSmall)
                    .tracking(StudioTypography.trackingNormal)
                    .foregroundStyle(Color.studioMuted)

                Text("OPTIONAL")
                    .font(StudioTypography.labelSmall)
                    .tracking(StudioTypography.trackingNormal)
                    .foregroundStyle(Color.studioMuted.opacity(0.5))
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 16) {
                    Image(systemName: "text.alignleft")
                        .font(.system(size: 16, weight: .ultraLight))
                        .foregroundStyle(Color.studioMuted)
                        .padding(.top, 2)

                    TextField("", text: $description, prompt: Text("WHAT'S THE OCCASION")
                        .font(StudioTypography.bodyMedium)
                        .foregroundStyle(Color.studioMuted.opacity(0.5)), axis: .vertical)
                        .font(StudioTypography.bodyMedium)
                        .foregroundStyle(Color.studioPrimary)
                        .lineLimit(3...6)
                }

                if !description.isEmpty {
                    HStack {
                        Spacer()
                        Text("\(description.count)/500")
                            .font(StudioTypography.labelSmall)
                            .foregroundStyle(description.count > 450 ? Color.studioError : Color.studioMuted)
                    }
                }
            }
            .padding(16)
            .background(Color.studioSurface)
            .overlay {
                Rectangle()
                    .stroke(Color.studioLine, lineWidth: 0.5)
            }
        }
    }

    // MARK: - Location Section

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text("LOCATION")
                    .font(StudioTypography.labelSmall)
                    .tracking(StudioTypography.trackingNormal)
                    .foregroundStyle(Color.studioMuted)

                Text("OPTIONAL")
                    .font(StudioTypography.labelSmall)
                    .tracking(StudioTypography.trackingNormal)
                    .foregroundStyle(Color.studioMuted.opacity(0.5))
            }

            Button {
                showLocationSearch = true
            } label: {
                HStack(spacing: 16) {
                    Image(systemName: "location")
                        .font(.system(size: 16, weight: .ultraLight))
                        .foregroundStyle(location.isEmpty ? Color.studioMuted : Color.studioChrome)

                    if location.isEmpty {
                        Text("SEARCH FOR A LOCATION")
                            .font(StudioTypography.bodyMedium)
                            .foregroundStyle(Color.studioMuted.opacity(0.5))
                    } else {
                        Text(location.uppercased())
                            .font(StudioTypography.bodyMedium)
                            .foregroundStyle(Color.studioPrimary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }

                    Spacer()

                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 12, weight: .ultraLight))
                        .foregroundStyle(Color.studioMuted)
                }
                .padding(16)
                .background(Color.studioSurface)
                .overlay {
                    Rectangle()
                        .stroke(location.isEmpty ? Color.studioLine : Color.studioChrome.opacity(0.5), lineWidth: 0.5)
                }
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())

            if !location.isEmpty {
                Button {
                    location = ""
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .light))
                        Text("CLEAR LOCATION")
                            .font(StudioTypography.labelSmall)
                            .tracking(StudioTypography.trackingNormal)
                    }
                    .foregroundStyle(Color.studioMuted)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Date Section

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("DATE & TIME")
                .font(StudioTypography.labelSmall)
                .tracking(StudioTypography.trackingNormal)
                .foregroundStyle(Color.studioMuted)

            VStack(spacing: 16) {
                // Toggle
                HStack {
                    Image(systemName: "calendar")
                        .font(.system(size: 16, weight: .ultraLight))
                        .foregroundStyle(hasDate ? Color.studioChrome : Color.studioMuted)

                    Text("SET A SPECIFIC DATE")
                        .font(StudioTypography.bodyMedium)
                        .foregroundStyle(Color.studioPrimary)

                    Spacer()

                    Toggle("", isOn: $hasDate)
                        .labelsHidden()
                        .tint(Color.studioChrome)
                }

                if hasDate {
                    Rectangle()
                        .fill(Color.studioLine)
                        .frame(height: 0.5)

                    DatePicker(
                        "Party Date",
                        selection: $partyDate,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.graphical)
                    .tint(Color.studioChrome)
                    .colorScheme(.dark)
                }
            }
            .padding(16)
            .background(Color.studioSurface)
            .overlay {
                Rectangle()
                    .stroke(hasDate ? Color.studioChrome.opacity(0.5) : Color.studioLine, lineWidth: 0.5)
            }
        }
    }

    // MARK: - Guest Limit Section

    private var guestLimitSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text("GUEST LIMIT")
                    .font(StudioTypography.labelSmall)
                    .tracking(StudioTypography.trackingNormal)
                    .foregroundStyle(Color.studioMuted)

                Text("OPTIONAL")
                    .font(StudioTypography.labelSmall)
                    .tracking(StudioTypography.trackingNormal)
                    .foregroundStyle(Color.studioMuted.opacity(0.5))
            }

            HStack(spacing: 16) {
                Image(systemName: "person.2")
                    .font(.system(size: 16, weight: .ultraLight))
                    .foregroundStyle(Color.studioMuted)

                TextField("", value: $maxGuests, format: .number, prompt: Text("NO LIMIT")
                    .font(StudioTypography.bodyMedium)
                    .foregroundStyle(Color.studioMuted.opacity(0.5)))
                    .keyboardType(.numberPad)
                    .font(StudioTypography.bodyMedium)
                    .foregroundStyle(Color.studioPrimary)

                if maxGuests != nil {
                    Button {
                        maxGuests = nil
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .light))
                            .foregroundStyle(Color.studioMuted)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
            .background(Color.studioSurface)
            .overlay {
                Rectangle()
                    .stroke(Color.studioLine, lineWidth: 0.5)
            }
        }
    }

    // MARK: - Create Button

    private var createButton: some View {
        Button {
            createParty()
        } label: {
            HStack(spacing: 12) {
                if isCreating {
                    ProgressView()
                        .tint(Color.studioBlack)
                } else {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .light))
                    Text("CREATE PARTY")
                        .font(StudioTypography.labelLarge)
                        .tracking(StudioTypography.trackingWide)
                }
            }
            .foregroundStyle(Color.studioBlack)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(title.isEmpty ? Color.studioMuted.opacity(0.3) : Color.studioChrome)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .disabled(title.isEmpty || isCreating)
        .padding(.top, 8)
    }

    // MARK: - Create Party

    private func createParty() {
        guard !title.isEmpty else { return }

        isCreating = true

        Task {
            do {
                let request = CreatePartyRequest(
                    title: title,
                    description: description.isEmpty ? nil : description,
                    location: location.isEmpty ? nil : location,
                    partyDate: hasDate ? partyDate : nil,
                    maxGuests: maxGuests
                )

                _ = try await partyService.createParty(request)
                dismiss()
            } catch {
                self.error = error
                showError = true
                isCreating = false
            }
        }
    }
}

// MARK: - Location Search Sheet

struct LocationSearchSheet: View {
    @Binding var searchQuery: String
    @Binding var selectedLocation: String
    @Binding var isPresented: Bool

    @State private var searchResults: [MKLocalSearchCompletion] = []
    @State private var completer = MKLocalSearchCompleter()
    @State private var delegate: LocationSearchDelegate?
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color.studioBlack
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search field
                    HStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 14, weight: .ultraLight))
                            .foregroundStyle(Color.studioMuted)

                        TextField("", text: $searchQuery, prompt: Text("SEARCH LOCATIONS")
                            .font(StudioTypography.bodyMedium)
                            .foregroundStyle(Color.studioMuted.opacity(0.5)))
                            .font(StudioTypography.bodyMedium)
                            .foregroundStyle(Color.studioPrimary)
                            .focused($isSearchFocused)
                            .autocorrectionDisabled()

                        if !searchQuery.isEmpty {
                            Button {
                                searchQuery = ""
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10, weight: .light))
                                    .foregroundStyle(Color.studioMuted)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                    .background(Color.studioSurface)
                    .overlay {
                        Rectangle()
                            .stroke(Color.studioLine, lineWidth: 0.5)
                    }
                    .padding(24)

                    if searchResults.isEmpty && !searchQuery.isEmpty {
                        // No results
                        VStack(spacing: 20) {
                            Spacer()
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 40, weight: .ultraLight))
                                .foregroundStyle(Color.studioMuted)
                            Text("NO LOCATIONS FOUND")
                                .studioLabelMedium()
                            Spacer()
                        }
                    } else if searchResults.isEmpty {
                        // Empty state
                        VStack(spacing: 20) {
                            Spacer()
                            Image(systemName: "location")
                                .font(.system(size: 40, weight: .ultraLight))
                                .foregroundStyle(Color.studioMuted)
                            Text("SEARCH FOR VENUES OR ADDRESSES")
                                .studioLabelMedium()
                            Spacer()
                        }
                    } else {
                        // Results list
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(searchResults, id: \.self) { result in
                                    Button {
                                        selectLocation(result)
                                    } label: {
                                        HStack(spacing: 16) {
                                            Rectangle()
                                                .fill(Color.studioSurface)
                                                .frame(width: 40, height: 40)
                                                .overlay {
                                                    Image(systemName: "mappin")
                                                        .font(.system(size: 14, weight: .ultraLight))
                                                        .foregroundStyle(Color.studioChrome)
                                                }
                                                .overlay {
                                                    Rectangle()
                                                        .stroke(Color.studioLine, lineWidth: 0.5)
                                                }

                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(result.title.uppercased())
                                                    .font(StudioTypography.bodySmall)
                                                    .foregroundStyle(Color.studioPrimary)
                                                    .lineLimit(1)

                                                if !result.subtitle.isEmpty {
                                                    Text(result.subtitle.uppercased())
                                                        .font(StudioTypography.labelSmall)
                                                        .foregroundStyle(Color.studioMuted)
                                                        .lineLimit(1)
                                                }
                                            }

                                            Spacer()

                                            Image(systemName: "arrow.right")
                                                .font(.system(size: 10, weight: .light))
                                                .foregroundStyle(Color.studioMuted)
                                        }
                                        .padding(.vertical, 16)
                                        .padding(.horizontal, 24)
                                    }
                                    .buttonStyle(.plain)
                                    .contentShape(Rectangle())

                                    Rectangle()
                                        .fill(Color.studioLine)
                                        .frame(height: 0.5)
                                        .padding(.leading, 80)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("SEARCH LOCATION")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        isPresented = false
                    } label: {
                        Text("CANCEL")
                            .font(StudioTypography.labelSmall)
                            .tracking(StudioTypography.trackingNormal)
                            .foregroundStyle(Color.studioMuted)
                    }
                }
            }
        }
        .onAppear {
            setupCompleter()
            isSearchFocused = true
        }
        .onChange(of: searchQuery) { _, newValue in
            completer.queryFragment = newValue
        }
    }

    private func setupCompleter() {
        delegate = LocationSearchDelegate { results in
            self.searchResults = results
        }
        completer.delegate = delegate
        completer.resultTypes = [.address, .pointOfInterest]
    }

    private func selectLocation(_ result: MKLocalSearchCompletion) {
        let locationString = result.subtitle.isEmpty ?
            result.title :
            "\(result.title), \(result.subtitle)"

        selectedLocation = locationString
        isPresented = false
    }
}

// MARK: - Location Search Delegate

class LocationSearchDelegate: NSObject, MKLocalSearchCompleterDelegate {
    var onResults: ([MKLocalSearchCompletion]) -> Void

    init(onResults: @escaping ([MKLocalSearchCompletion]) -> Void) {
        self.onResults = onResults
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        onResults(completer.results)
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Location search error: \(error.localizedDescription)")
    }
}

// MARK: - Preview

#Preview("Create Party") {
    CreatePartyView()
}
