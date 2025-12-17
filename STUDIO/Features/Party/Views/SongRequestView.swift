//
//  SongRequestView.swift
//  STUDIO
//
//  Song request module for parties - guests can request songs
//  and vote on the queue
//  Basel Afterdark Design System
//

import SwiftUI

// MARK: - Song Request Model

struct SongRequest: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let partyId: UUID
    let userId: UUID
    var songTitle: String
    var artistName: String
    var albumArt: String?        // URL to album artwork
    var spotifyUri: String?      // Spotify track URI for playback
    var appleMusicId: String?    // Apple Music track ID
    var upvotes: Int
    var downvotes: Int
    var status: SongStatus
    let createdAt: Date
    var playedAt: Date?

    var user: User?
    var hasVoted: Bool?          // Current user's vote status
    var userVote: VoteType?      // Current user's vote

    var netVotes: Int {
        upvotes - downvotes
    }

    enum CodingKeys: String, CodingKey {
        case id
        case partyId = "party_id"
        case userId = "user_id"
        case songTitle = "song_title"
        case artistName = "artist_name"
        case albumArt = "album_art"
        case spotifyUri = "spotify_uri"
        case appleMusicId = "apple_music_id"
        case upvotes
        case downvotes
        case status
        case createdAt = "created_at"
        case playedAt = "played_at"
        case user
        case hasVoted = "has_voted"
        case userVote = "user_vote"
    }
}

enum SongStatus: String, Codable, Sendable {
    case pending = "pending"
    case queued = "queued"
    case playing = "playing"
    case played = "played"
    case rejected = "rejected"
}

enum VoteType: String, Codable, Sendable {
    case up = "up"
    case down = "down"
}

// MARK: - Song Request View

struct SongRequestView: View {
    let partyId: UUID
    @Binding var songRequests: [SongRequest]
    var isHost: Bool = false
    var onRequestSong: ((String, String) async -> Void)?
    var onVote: ((UUID, VoteType) async -> Void)?
    var onUpdateStatus: ((UUID, SongStatus) async -> Void)?

    @State private var showAddSong = false
    @State private var selectedTab: SongTab = .queue

    enum SongTab: String, CaseIterable {
        case queue = "QUEUE"
        case played = "PLAYED"

        var icon: String {
            switch self {
            case .queue: return "list.bullet"
            case .played: return "checkmark.circle"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with tabs
            header

            // Now playing (if any)
            if let nowPlaying = songRequests.first(where: { $0.status == .playing }) {
                NowPlayingCard(song: nowPlaying)
            }

            // Tab selector
            tabSelector

            // Song list
            songList
        }
        .background(Color.studioBlack)
        .sheet(isPresented: $showAddSong) {
            AddSongSheet(onAdd: { title, artist in
                Task {
                    await onRequestSong?(title, artist)
                }
            })
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
            .presentationBackground(Color.studioSurface)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("SONG REQUESTS")
                    .font(StudioTypography.headlineMedium)
                    .tracking(StudioTypography.trackingWide)
                    .foregroundStyle(Color.studioPrimary)

                Text("\(queuedCount) IN QUEUE")
                    .font(StudioTypography.labelSmall)
                    .tracking(StudioTypography.trackingNormal)
                    .foregroundStyle(Color.studioMuted)
            }

            Spacer()

            // Add song button
            Button {
                HapticManager.shared.impact(.light)
                showAddSong = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .medium))
                    Text("REQUEST")
                        .font(StudioTypography.labelMedium)
                        .tracking(StudioTypography.trackingNormal)
                }
                .foregroundStyle(Color.studioBlack)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.studioChrome)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color.studioDeepBlack)
    }

    private var queuedCount: Int {
        songRequests.filter { $0.status == .pending || $0.status == .queued }.count
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(SongTab.allCases, id: \.self) { tab in
                Button {
                    HapticManager.shared.impact(.light)
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 12, weight: .light))
                        Text(tab.rawValue)
                            .font(StudioTypography.labelSmall)
                            .tracking(StudioTypography.trackingNormal)
                    }
                    .foregroundStyle(selectedTab == tab ? Color.studioPrimary : Color.studioMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(selectedTab == tab ? Color.studioSurface : Color.clear)
                    .overlay(alignment: .bottom) {
                        if selectedTab == tab {
                            Rectangle()
                                .fill(Color.studioChrome)
                                .frame(height: 2)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .background(Color.studioDeepBlack)
    }

    // MARK: - Song List

    private var songList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                let filteredSongs = selectedTab == .queue
                    ? songRequests.filter { $0.status == .pending || $0.status == .queued }.sorted { $0.netVotes > $1.netVotes }
                    : songRequests.filter { $0.status == .played }.sorted { ($0.playedAt ?? $0.createdAt) > ($1.playedAt ?? $1.createdAt) }

                if filteredSongs.isEmpty {
                    emptyState
                } else {
                    ForEach(filteredSongs) { song in
                        SongRequestRow(
                            song: song,
                            isHost: isHost,
                            onVote: { voteType in
                                Task {
                                    await onVote?(song.id, voteType)
                                }
                            },
                            onStatusChange: { status in
                                Task {
                                    await onUpdateStatus?(song.id, status)
                                }
                            }
                        )

                        Rectangle()
                            .fill(Color.studioLine.opacity(0.5))
                            .frame(height: 0.5)
                    }
                }
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note.list")
                .font(.system(size: 48, weight: .ultraLight))
                .foregroundStyle(Color.studioMuted)

            Text(selectedTab == .queue ? "NO SONGS IN QUEUE" : "NO PLAYED SONGS")
                .font(StudioTypography.labelMedium)
                .tracking(StudioTypography.trackingWide)
                .foregroundStyle(Color.studioSecondary)

            if selectedTab == .queue {
                Text("REQUEST A SONG TO GET THE PARTY STARTED")
                    .font(StudioTypography.bodySmall)
                    .foregroundStyle(Color.studioMuted)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
    }
}

// MARK: - Now Playing Card

struct NowPlayingCard: View {
    let song: SongRequest

    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 16) {
            // Album art / visualizer
            ZStack {
                Rectangle()
                    .fill(Color.studioSurface)
                    .frame(width: 64, height: 64)

                if let albumArt = song.albumArt {
                    AsyncImage(url: URL(string: albumArt)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        musicVisualizer
                    }
                    .frame(width: 64, height: 64)
                    .clipped()
                } else {
                    musicVisualizer
                }
            }
            .overlay {
                Rectangle()
                    .stroke(Color.studioChrome, lineWidth: 2)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("NOW PLAYING")
                    .font(StudioTypography.labelSmall)
                    .tracking(StudioTypography.trackingWide)
                    .foregroundStyle(Color.studioChrome)

                Text(song.songTitle.uppercased())
                    .font(StudioTypography.labelLarge)
                    .tracking(StudioTypography.trackingNormal)
                    .foregroundStyle(Color.studioPrimary)
                    .lineLimit(1)

                Text(song.artistName.uppercased())
                    .font(StudioTypography.labelSmall)
                    .tracking(StudioTypography.trackingNormal)
                    .foregroundStyle(Color.studioSecondary)
                    .lineLimit(1)
            }

            Spacer()

            // Animated equalizer
            HStack(spacing: 3) {
                ForEach(0..<4, id: \.self) { index in
                    Rectangle()
                        .fill(Color.studioChrome)
                        .frame(width: 4)
                        .frame(height: isAnimating ? CGFloat.random(in: 8...24) : 8)
                        .animation(
                            .easeInOut(duration: 0.3)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.1),
                            value: isAnimating
                        )
                }
            }
            .frame(height: 24)
        }
        .padding(16)
        .background(Color.studioChrome.opacity(0.1))
        .overlay {
            Rectangle()
                .stroke(Color.studioChrome, lineWidth: 1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .onAppear {
            isAnimating = true
        }
    }

    private var musicVisualizer: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(Color.studioChrome.opacity(0.3), lineWidth: 1)
                    .frame(width: CGFloat(20 + index * 15), height: CGFloat(20 + index * 15))
            }

            Image(systemName: "music.note")
                .font(.system(size: 20, weight: .light))
                .foregroundStyle(Color.studioChrome)
        }
    }
}

// MARK: - Song Request Row

struct SongRequestRow: View {
    let song: SongRequest
    var isHost: Bool = false
    var onVote: ((VoteType) -> Void)?
    var onStatusChange: ((SongStatus) -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            // Vote buttons
            VStack(spacing: 4) {
                Button {
                    HapticManager.shared.impact(.light)
                    onVote?(.up)
                } label: {
                    Image(systemName: song.userVote == .up ? "arrow.up.circle.fill" : "arrow.up.circle")
                        .font(.system(size: 20, weight: .light))
                        .foregroundStyle(song.userVote == .up ? Color.studioChrome : Color.studioMuted)
                }
                .buttonStyle(.plain)

                Text("\(song.netVotes)")
                    .font(StudioTypography.labelMedium)
                    .foregroundStyle(song.netVotes > 0 ? Color.studioChrome : (song.netVotes < 0 ? Color.studioError : Color.studioMuted))

                Button {
                    HapticManager.shared.impact(.light)
                    onVote?(.down)
                } label: {
                    Image(systemName: song.userVote == .down ? "arrow.down.circle.fill" : "arrow.down.circle")
                        .font(.system(size: 20, weight: .light))
                        .foregroundStyle(song.userVote == .down ? Color.studioError : Color.studioMuted)
                }
                .buttonStyle(.plain)
            }
            .frame(width: 44)

            // Album art placeholder
            ZStack {
                Rectangle()
                    .fill(Color.studioSurface)
                    .frame(width: 48, height: 48)

                if let albumArt = song.albumArt {
                    AsyncImage(url: URL(string: albumArt)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "music.note")
                            .font(.system(size: 20, weight: .ultraLight))
                            .foregroundStyle(Color.studioMuted)
                    }
                    .frame(width: 48, height: 48)
                    .clipped()
                } else {
                    Image(systemName: "music.note")
                        .font(.system(size: 20, weight: .ultraLight))
                        .foregroundStyle(Color.studioMuted)
                }
            }
            .overlay {
                Rectangle()
                    .stroke(Color.studioLine, lineWidth: 0.5)
            }

            // Song info
            VStack(alignment: .leading, spacing: 4) {
                Text(song.songTitle.uppercased())
                    .font(StudioTypography.labelMedium)
                    .tracking(StudioTypography.trackingNormal)
                    .foregroundStyle(Color.studioPrimary)
                    .lineLimit(1)

                Text(song.artistName.uppercased())
                    .font(StudioTypography.labelSmall)
                    .tracking(StudioTypography.trackingNormal)
                    .foregroundStyle(Color.studioSecondary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    // Requester
                    if let user = song.user {
                        Text("BY \(user.username.uppercased())")
                            .font(StudioTypography.labelSmall)
                            .foregroundStyle(Color.studioMuted)
                    }

                    // Status badge
                    if song.status == .queued {
                        Text("QUEUED")
                            .font(StudioTypography.labelSmall)
                            .foregroundStyle(Color.studioChrome)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.studioChrome.opacity(0.2))
                    }
                }
            }

            Spacer()

            // Host controls
            if isHost && song.status == .pending {
                Menu {
                    Button {
                        onStatusChange?(.queued)
                    } label: {
                        Label("ADD TO QUEUE", systemImage: "plus.circle")
                    }

                    Button {
                        onStatusChange?(.playing)
                    } label: {
                        Label("PLAY NOW", systemImage: "play.circle")
                    }

                    Button(role: .destructive) {
                        onStatusChange?(.rejected)
                    } label: {
                        Label("REJECT", systemImage: "xmark.circle")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .light))
                        .foregroundStyle(Color.studioMuted)
                        .frame(width: 44, height: 44)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Add Song Sheet

struct AddSongSheet: View {
    var onAdd: ((String, String) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var songTitle = ""
    @State private var artistName = ""
    @State private var searchResults: [SpotifySearchResult] = []
    @State private var isSearching = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Manual entry
                VStack(spacing: 16) {
                    // Song title
                    VStack(alignment: .leading, spacing: 8) {
                        Text("SONG TITLE")
                            .font(StudioTypography.labelSmall)
                            .tracking(StudioTypography.trackingWide)
                            .foregroundStyle(Color.studioMuted)

                        TextField("", text: $songTitle, prompt: Text("Enter song title...")
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

                    // Artist name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ARTIST")
                            .font(StudioTypography.labelSmall)
                            .tracking(StudioTypography.trackingWide)
                            .foregroundStyle(Color.studioMuted)

                        TextField("", text: $artistName, prompt: Text("Enter artist name...")
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
                }
                .padding(.horizontal, 16)

                Spacer()

                // Request button
                Button {
                    HapticManager.shared.notification(.success)
                    onAdd?(songTitle, artistName)
                    dismiss()
                } label: {
                    Text("REQUEST SONG")
                        .font(StudioTypography.labelLarge)
                        .tracking(StudioTypography.trackingWide)
                        .foregroundStyle(canSubmit ? Color.studioBlack : Color.studioMuted)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(canSubmit ? Color.studioChrome : Color.studioSurface)
                        .overlay {
                            if !canSubmit {
                                Rectangle()
                                    .stroke(Color.studioLine, lineWidth: 1)
                            }
                        }
                }
                .buttonStyle(.plain)
                .disabled(!canSubmit)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .padding(.top, 16)
            .background(Color.studioSurface)
            .navigationTitle("REQUEST A SONG")
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

    private var canSubmit: Bool {
        !songTitle.trimmingCharacters(in: .whitespaces).isEmpty &&
        !artistName.trimmingCharacters(in: .whitespaces).isEmpty
    }
}

// MARK: - Spotify Search Result (Placeholder)

struct SpotifySearchResult: Identifiable {
    let id: String
    let title: String
    let artist: String
    let albumArt: String?
    let uri: String
}

// MARK: - Preview

#Preview("Song Request") {
    SongRequestView(
        partyId: UUID(),
        songRequests: .constant([
            SongRequest(
                id: UUID(),
                partyId: UUID(),
                userId: UUID(),
                songTitle: "Blinding Lights",
                artistName: "The Weeknd",
                albumArt: nil,
                spotifyUri: nil,
                appleMusicId: nil,
                upvotes: 12,
                downvotes: 2,
                status: .playing,
                createdAt: Date(),
                playedAt: nil
            ),
            SongRequest(
                id: UUID(),
                partyId: UUID(),
                userId: UUID(),
                songTitle: "One More Time",
                artistName: "Daft Punk",
                albumArt: nil,
                spotifyUri: nil,
                appleMusicId: nil,
                upvotes: 8,
                downvotes: 1,
                status: .queued,
                createdAt: Date(),
                playedAt: nil
            )
        ]),
        isHost: true
    )
}
