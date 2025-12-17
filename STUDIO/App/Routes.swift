//
//  Routes.swift
//  STUDIO
//
//  Created by Claude on 12/16/25.
//

import Foundation

/// Main navigation routes for the app
enum Route: Hashable {
    // MARK: - Feed Routes
    case partyDetail(partyId: UUID)
    case mediaViewer(partyId: UUID, startIndex: Int)

    // MARK: - Party Routes
    case createParty
    case editParty(partyId: UUID)
    case inviteGuests(partyId: UUID)
    case partyMembers(partyId: UUID)

    // MARK: - Social Routes
    case createPoll(partyId: UUID)
    case pollDetail(pollId: UUID)
    case createStatus(partyId: UUID)
    case comments(partyId: UUID)

    // MARK: - Profile Routes
    case userProfile(userId: UUID)
    case editProfile
    case followers(userId: UUID)
    case following(userId: UUID)

    // MARK: - Settings Routes
    case settings
}

/// Tabs in the main tab bar
enum Tab: String, CaseIterable, Identifiable {
    case feed
    case activity
    case profile

    var id: String { rawValue }

    var title: String {
        switch self {
        case .feed: return "Feed"
        case .activity: return "Activity"
        case .profile: return "Profile"
        }
    }

    var icon: String {
        switch self {
        case .feed: return "house.fill"
        case .activity: return "bell.fill"
        case .profile: return "person.fill"
        }
    }
}

/// Sheet presentations
enum Sheet: Identifiable {
    case camera(partyId: UUID?)
    case photoPicker(partyId: UUID?)
    case createParty
    case createPoll(partyId: UUID)
    case createStatus(partyId: UUID)
    case shareParty(partyId: UUID)
    case inviteGuests(partyId: UUID)

    var id: String {
        switch self {
        case .camera(let id): return "camera-\(id?.uuidString ?? "new")"
        case .photoPicker(let id): return "picker-\(id?.uuidString ?? "new")"
        case .createParty: return "createParty"
        case .createPoll(let id): return "poll-\(id)"
        case .createStatus(let id): return "status-\(id)"
        case .shareParty(let id): return "share-\(id)"
        case .inviteGuests(let id): return "invite-\(id)"
        }
    }
}

/// Full screen covers
enum FullScreenCover: Identifiable {
    case onboarding
    case mediaCapture(partyId: UUID)

    var id: String {
        switch self {
        case .onboarding: return "onboarding"
        case .mediaCapture(let id): return "capture-\(id)"
        }
    }
}
