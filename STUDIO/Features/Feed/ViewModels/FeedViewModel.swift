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
