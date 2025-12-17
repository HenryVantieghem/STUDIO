//
//  FeedViewModel.swift
//  STUDIO
//
//  Created by Claude on 12/16/25.
//

import Foundation

// MARK: - Feed ViewModel

@Observable
@MainActor
final class FeedViewModel {
    // MARK: - Properties

    var activeParties: [Party] = []
    var upcomingParties: [Party] = []
    var pastParties: [Party] = []
    var pendingInvitations: [PartyGuest] = []

    var isLoading = false
    var isLoadingMore = false
    var error: Error?
    var showError = false

    var selectedTab: FeedTab = .active

    // Mock data mode for development
    var useMockData = true

    private let feedService = FeedService()
    private var pastPartiesOffset = 0
    private let pageSize = 20

    // MARK: - Feed Tabs

    enum FeedTab: String, CaseIterable, Identifiable {
        case active = "Active"
        case upcoming = "Upcoming"
        case memories = "Memories"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .active: return "party.popper.fill"
            case .upcoming: return "calendar"
            case .memories: return "photo.on.rectangle"
            }
        }
    }

    // MARK: - Load Data

    func loadFeed() async {
        guard !isLoading else { return }
        isLoading = true
        error = nil

        if useMockData {
            // Use mock data for development
            try? await Task.sleep(for: .milliseconds(800))
            activeParties = MockData.activeParties
            upcomingParties = MockData.upcomingParties
            pastParties = MockData.pastParties
            pendingInvitations = MockData.pendingInvitations
            isLoading = false
            return
        }

        do {
            async let activeTask = feedService.getActiveParties()
            async let upcomingTask = feedService.getUpcomingParties()
            async let invitationsTask = feedService.getPendingInvitations()

            let (active, upcoming, invitations) = try await (activeTask, upcomingTask, invitationsTask)

            activeParties = active
            upcomingParties = upcoming
            pendingInvitations = invitations

            // Load first page of past parties
            pastParties = try await feedService.getPastParties(limit: pageSize, offset: 0)
            pastPartiesOffset = pageSize
        } catch {
            self.error = error
            showError = true
        }

        isLoading = false
    }

    func refreshFeed() async {
        pastPartiesOffset = 0
        await loadFeed()
    }

    // MARK: - Load More Past Parties

    func loadMorePastParties() async {
        guard !isLoadingMore else { return }

        if useMockData {
            return // No pagination in mock mode
        }

        isLoadingMore = true

        do {
            let morePastParties = try await feedService.getPastParties(
                limit: pageSize,
                offset: pastPartiesOffset
            )
            pastParties.append(contentsOf: morePastParties)
            pastPartiesOffset += pageSize
        } catch {
            self.error = error
            showError = true
        }

        isLoadingMore = false
    }

    // MARK: - Invitation Actions

    func respondToInvitation(_ invitation: PartyGuest, accept: Bool) async {
        if useMockData {
            pendingInvitations.removeAll { $0.id == invitation.id }
            return
        }

        let partyService = PartyService()

        do {
            try await partyService.updateGuestStatus(
                partyId: invitation.partyId,
                status: accept ? .accepted : .declined
            )

            // Remove from pending list
            pendingInvitations.removeAll { $0.id == invitation.id }

            // Refresh to show the newly accepted party
            if accept {
                await loadFeed()
            }
        } catch {
            self.error = error
            showError = true
        }
    }

    // MARK: - Computed Properties

    var hasActiveParties: Bool { !activeParties.isEmpty }
    var hasUpcomingParties: Bool { !upcomingParties.isEmpty }
    var hasPastParties: Bool { !pastParties.isEmpty }
    var hasPendingInvitations: Bool { !pendingInvitations.isEmpty }

    var currentTabParties: [Party] {
        switch selectedTab {
        case .active: return activeParties
        case .upcoming: return upcomingParties
        case .memories: return pastParties
        }
    }

    var emptyStateMessage: String {
        switch selectedTab {
        case .active:
            return "No active parties right now. Start one!"
        case .upcoming:
            return "No upcoming parties. Plan something!"
        case .memories:
            return "Your party memories will appear here."
        }
    }
}

// MARK: - Mock Data

enum MockData {
    static let mockUsers: [User] = [
        User(
            id: UUID(),
            username: "sophia_night",
            displayName: "Sophia Chen",
            avatarUrl: nil,
            bio: "Living for the nights I'll never forget",
            createdAt: Date().addingTimeInterval(-86400 * 30),
            updatedAt: Date()
        ),
        User(
            id: UUID(),
            username: "jake_vibe",
            displayName: "Jake Miller",
            avatarUrl: nil,
            bio: "Party architect",
            createdAt: Date().addingTimeInterval(-86400 * 60),
            updatedAt: Date()
        ),
        User(
            id: UUID(),
            username: "luna_dj",
            displayName: "Luna",
            avatarUrl: nil,
            bio: "Music is life",
            createdAt: Date().addingTimeInterval(-86400 * 45),
            updatedAt: Date()
        ),
        User(
            id: UUID(),
            username: "max_party",
            displayName: "Max Rodriguez",
            avatarUrl: nil,
            bio: nil,
            createdAt: Date().addingTimeInterval(-86400 * 20),
            updatedAt: Date()
        )
    ]

    static let activeParties: [Party] = [
        Party(
            id: UUID(),
            createdAt: Date().addingTimeInterval(-3600),
            title: "Neon Dreams",
            description: "An immersive neon-lit experience in the heart of downtown. Dress code: Glow in the dark.",
            coverImageUrl: nil,
            location: "The Warehouse, Brooklyn",
            partyDate: Date().addingTimeInterval(-3600),
            endDate: nil,
            isActive: true,
            isPublic: false,
            maxGuests: 50,
            hosts: [
                PartyHost(
                    id: UUID(),
                    partyId: UUID(),
                    userId: mockUsers[0].id,
                    role: .creator,
                    addedAt: Date(),
                    user: mockUsers[0]
                ),
                PartyHost(
                    id: UUID(),
                    partyId: UUID(),
                    userId: mockUsers[1].id,
                    role: .cohost,
                    addedAt: Date(),
                    user: mockUsers[1]
                )
            ],
            guests: nil,
            mediaCount: 47,
            commentCount: 23
        ),
        Party(
            id: UUID(),
            createdAt: Date().addingTimeInterval(-7200),
            title: "Studio 54 Revival",
            description: "Channel the legendary disco era. Glitter, glamour, and good vibes only.",
            coverImageUrl: nil,
            location: "Penthouse Lounge",
            partyDate: Date().addingTimeInterval(-7200),
            endDate: nil,
            isActive: true,
            isPublic: false,
            maxGuests: 30,
            hosts: [
                PartyHost(
                    id: UUID(),
                    partyId: UUID(),
                    userId: mockUsers[2].id,
                    role: .creator,
                    addedAt: Date(),
                    user: mockUsers[2]
                )
            ],
            guests: nil,
            mediaCount: 89,
            commentCount: 45
        )
    ]

    static let upcomingParties: [Party] = [
        Party(
            id: UUID(),
            createdAt: Date(),
            title: "New Year's Eve Gala",
            description: "Ring in 2026 in style. Black tie optional but encouraged.",
            coverImageUrl: nil,
            location: "The Grand Ballroom",
            partyDate: Calendar.current.date(from: DateComponents(year: 2025, month: 12, day: 31, hour: 21))!,
            endDate: nil,
            isActive: false,
            isPublic: false,
            maxGuests: 100,
            hosts: [
                PartyHost(
                    id: UUID(),
                    partyId: UUID(),
                    userId: mockUsers[0].id,
                    role: .creator,
                    addedAt: Date(),
                    user: mockUsers[0]
                ),
                PartyHost(
                    id: UUID(),
                    partyId: UUID(),
                    userId: mockUsers[1].id,
                    role: .cohost,
                    addedAt: Date(),
                    user: mockUsers[1]
                ),
                PartyHost(
                    id: UUID(),
                    partyId: UUID(),
                    userId: mockUsers[2].id,
                    role: .cohost,
                    addedAt: Date(),
                    user: mockUsers[2]
                )
            ],
            guests: nil,
            mediaCount: 0,
            commentCount: 12
        ),
        Party(
            id: UUID(),
            createdAt: Date().addingTimeInterval(-86400),
            title: "Rooftop Sunset Session",
            description: "Watch the sunset with good music and better company.",
            coverImageUrl: nil,
            location: "Sky Lounge, Manhattan",
            partyDate: Date().addingTimeInterval(86400 * 3),
            endDate: nil,
            isActive: false,
            isPublic: false,
            maxGuests: 25,
            hosts: [
                PartyHost(
                    id: UUID(),
                    partyId: UUID(),
                    userId: mockUsers[3].id,
                    role: .creator,
                    addedAt: Date(),
                    user: mockUsers[3]
                )
            ],
            guests: nil,
            mediaCount: 0,
            commentCount: 5
        )
    ]

    static let pastParties: [Party] = [
        Party(
            id: UUID(),
            createdAt: Date().addingTimeInterval(-86400 * 7),
            title: "Midnight Masquerade",
            description: "A night of mystery and elegance behind the mask.",
            coverImageUrl: nil,
            location: "Secret Garden",
            partyDate: Date().addingTimeInterval(-86400 * 7),
            endDate: Date().addingTimeInterval(-86400 * 7 + 18000),
            isActive: false,
            isPublic: false,
            maxGuests: 40,
            hosts: [
                PartyHost(
                    id: UUID(),
                    partyId: UUID(),
                    userId: mockUsers[1].id,
                    role: .creator,
                    addedAt: Date(),
                    user: mockUsers[1]
                )
            ],
            guests: nil,
            mediaCount: 156,
            commentCount: 67
        ),
        Party(
            id: UUID(),
            createdAt: Date().addingTimeInterval(-86400 * 14),
            title: "Beach Bonfire",
            description: "Sandy toes, good flows, and where the night goes.",
            coverImageUrl: nil,
            location: "Malibu Beach",
            partyDate: Date().addingTimeInterval(-86400 * 14),
            endDate: Date().addingTimeInterval(-86400 * 14 + 21600),
            isActive: false,
            isPublic: false,
            maxGuests: 20,
            hosts: [
                PartyHost(
                    id: UUID(),
                    partyId: UUID(),
                    userId: mockUsers[2].id,
                    role: .creator,
                    addedAt: Date(),
                    user: mockUsers[2]
                ),
                PartyHost(
                    id: UUID(),
                    partyId: UUID(),
                    userId: mockUsers[3].id,
                    role: .cohost,
                    addedAt: Date(),
                    user: mockUsers[3]
                )
            ],
            guests: nil,
            mediaCount: 234,
            commentCount: 89
        )
    ]

    static let pendingInvitations: [PartyGuest] = [
        PartyGuest(
            id: UUID(),
            partyId: upcomingParties[0].id,
            userId: UUID(),
            status: .pending,
            invitedBy: mockUsers[0].id,
            invitedAt: Date().addingTimeInterval(-3600),
            respondedAt: nil,
            user: nil,
            party: upcomingParties[0]
        )
    ]
}
