//
//  MockData.swift
//  STUDIO
//
//  Mock data for SwiftUI Previews
//  Basel Afterdark Design System
//

import Foundation

// MARK: - Mock Data

/// Mock data for SwiftUI previews
enum MockData {

    // MARK: - Users

    static let user = User(
        id: UUID(),
        username: "afterdark_user",
        displayName: "Night Owl",
        avatarUrl: nil,
        bio: "Living for the night",
        isPrivate: false,
        createdAt: Date(),
        updatedAt: Date()
    )

    static let user2 = User(
        id: UUID(),
        username: "basel_vibes",
        displayName: "Basel Vibes",
        avatarUrl: nil,
        bio: nil,
        isPrivate: false,
        createdAt: Date(),
        updatedAt: Date()
    )

    // MARK: - Party

    static let party = Party(
        id: UUID(),
        createdAt: Date(),
        title: "Afterdark Session",
        description: "An exclusive night to remember",
        coverImageUrl: nil,
        location: "The Warehouse",
        partyDate: Date(),
        endDate: nil,
        isActive: true,
        isPublic: false,
        maxGuests: 50,
        hosts: nil,
        guests: nil,
        mediaCount: 12,
        commentCount: 5
    )

    // MARK: - Party Comments

    static let partyComments: [PartyComment] = [
        PartyComment(
            id: UUID(),
            partyId: party.id,
            userId: user.id,
            content: "This night is incredible!",
            createdAt: Date().addingTimeInterval(-3600),
            updatedAt: nil,
            parentId: nil,
            user: user,
            replies: nil
        ),
        PartyComment(
            id: UUID(),
            partyId: party.id,
            userId: user2.id,
            content: "Best vibes of the year",
            createdAt: Date().addingTimeInterval(-1800),
            updatedAt: nil,
            parentId: nil,
            user: user2,
            replies: nil
        ),
        PartyComment(
            id: UUID(),
            partyId: party.id,
            userId: user.id,
            content: "Who's hitting the dance floor?",
            createdAt: Date().addingTimeInterval(-900),
            updatedAt: nil,
            parentId: nil,
            user: user,
            replies: nil
        )
    ]

    // MARK: - Party Media

    static let partyMedia: [PartyMedia] = [
        PartyMedia(
            id: UUID(),
            partyId: party.id,
            userId: user.id,
            mediaType: .photo,
            url: "https://example.com/photo1.jpg",
            thumbnailUrl: nil,
            caption: "The crowd is wild",
            createdAt: Date().addingTimeInterval(-7200),
            duration: nil,
            user: user
        ),
        PartyMedia(
            id: UUID(),
            partyId: party.id,
            userId: user2.id,
            mediaType: .photo,
            url: "https://example.com/photo2.jpg",
            thumbnailUrl: nil,
            caption: nil,
            createdAt: Date().addingTimeInterval(-3600),
            duration: nil,
            user: user2
        ),
        PartyMedia(
            id: UUID(),
            partyId: party.id,
            userId: user.id,
            mediaType: .video,
            url: "https://example.com/video1.mp4",
            thumbnailUrl: "https://example.com/thumb1.jpg",
            caption: "DJ dropping beats",
            createdAt: Date().addingTimeInterval(-1800),
            duration: 15.0,
            user: user
        )
    ]

    // MARK: - Party Polls

    static let partyPolls: [PartyPoll] = [
        PartyPoll(
            id: UUID(),
            partyId: party.id,
            createdBy: user.id,
            question: "Who's the party MVP?",
            pollType: .partyMVP,
            createdAt: Date().addingTimeInterval(-3600),
            expiresAt: Date().addingTimeInterval(3600),
            isActive: true,
            options: [
                PollOption(
                    id: UUID(),
                    pollId: UUID(),
                    optionText: nil,
                    optionUserId: user.id,
                    voteCount: 5,
                    optionUser: user,
                    hasVoted: false
                ),
                PollOption(
                    id: UUID(),
                    pollId: UUID(),
                    optionText: nil,
                    optionUserId: user2.id,
                    voteCount: 3,
                    optionUser: user2,
                    hasVoted: true
                )
            ],
            creator: user,
            totalVotes: 8
        ),
        PartyPoll(
            id: UUID(),
            partyId: party.id,
            createdBy: user2.id,
            question: "Best moment of the night?",
            pollType: .bestMoment,
            createdAt: Date().addingTimeInterval(-1800),
            expiresAt: nil,
            isActive: true,
            options: [
                PollOption(
                    id: UUID(),
                    pollId: UUID(),
                    optionText: "The DJ set",
                    optionUserId: nil,
                    voteCount: 7,
                    optionUser: nil,
                    hasVoted: true
                ),
                PollOption(
                    id: UUID(),
                    pollId: UUID(),
                    optionText: "The surprise guest",
                    optionUserId: nil,
                    voteCount: 4,
                    optionUser: nil,
                    hasVoted: false
                )
            ],
            creator: user2,
            totalVotes: 11
        )
    ]

    // MARK: - Party Statuses

    static let partyStatuses: [PartyStatus] = [
        PartyStatus(
            id: UUID(),
            partyId: party.id,
            userId: user.id,
            statusType: .vibeCheck,
            value: 4,
            message: "Feeling amazing!",
            createdAt: Date().addingTimeInterval(-1800),
            user: user
        ),
        PartyStatus(
            id: UUID(),
            partyId: party.id,
            userId: user2.id,
            statusType: .vibeCheck,
            value: 5,
            message: nil,
            createdAt: Date().addingTimeInterval(-900),
            user: user2
        ),
        PartyStatus(
            id: UUID(),
            partyId: party.id,
            userId: user.id,
            statusType: .drunkMeter,
            value: 3,
            message: "Just right",
            createdAt: Date().addingTimeInterval(-600),
            user: user
        ),
        PartyStatus(
            id: UUID(),
            partyId: party.id,
            userId: user2.id,
            statusType: .energy,
            value: 5,
            message: nil,
            createdAt: Date().addingTimeInterval(-300),
            user: user2
        )
    ]

    // MARK: - Party Guests

    static let partyGuests: [PartyGuest] = [
        PartyGuest(
            id: UUID(),
            partyId: party.id,
            userId: user.id,
            status: .accepted,
            invitedBy: user.id,
            invitedAt: Date().addingTimeInterval(-86400),
            respondedAt: Date().addingTimeInterval(-82800),
            user: user,
            party: nil
        ),
        PartyGuest(
            id: UUID(),
            partyId: party.id,
            userId: user2.id,
            status: .accepted,
            invitedBy: user.id,
            invitedAt: Date().addingTimeInterval(-86400),
            respondedAt: Date().addingTimeInterval(-80000),
            user: user2,
            party: nil
        )
    ]

    // MARK: - Party Lists (for Feed)

    static let activeParties: [Party] = [
        Party(
            id: UUID(),
            createdAt: Date(),
            title: "Afterdark Session",
            description: "The night is young",
            coverImageUrl: nil,
            location: "The Warehouse",
            partyDate: Date(),
            endDate: nil,
            isActive: true,
            isPublic: false,
            maxGuests: 50,
            hosts: nil,
            guests: nil,
            mediaCount: 8,
            commentCount: 3
        ),
        Party(
            id: UUID(),
            createdAt: Date().addingTimeInterval(-3600),
            title: "Basel Nights",
            description: "Art and music collide",
            coverImageUrl: nil,
            location: "Gallery District",
            partyDate: Date(),
            endDate: nil,
            isActive: true,
            isPublic: false,
            maxGuests: 30,
            hosts: nil,
            guests: nil,
            mediaCount: 15,
            commentCount: 7
        )
    ]

    static let upcomingParties: [Party] = [
        Party(
            id: UUID(),
            createdAt: Date(),
            title: "Midnight Gala",
            description: "Formal attire required",
            coverImageUrl: nil,
            location: "The Penthouse",
            partyDate: Date().addingTimeInterval(86400),
            endDate: nil,
            isActive: false,
            isPublic: false,
            maxGuests: 100,
            hosts: nil,
            guests: nil,
            mediaCount: 0,
            commentCount: 0
        )
    ]

    static let pastParties: [Party] = [
        Party(
            id: UUID(),
            createdAt: Date().addingTimeInterval(-604800),
            title: "Last Weekend",
            description: "One for the books",
            coverImageUrl: nil,
            location: "Rooftop",
            partyDate: Date().addingTimeInterval(-604800),
            endDate: Date().addingTimeInterval(-590400),
            isActive: false,
            isPublic: false,
            maxGuests: 40,
            hosts: nil,
            guests: nil,
            mediaCount: 45,
            commentCount: 23
        )
    ]

    static let pendingInvitations: [PartyGuest] = [
        PartyGuest(
            id: UUID(),
            partyId: UUID(),
            userId: user.id,
            status: .pending,
            invitedBy: user2.id,
            invitedAt: Date().addingTimeInterval(-3600),
            respondedAt: nil,
            user: user,
            party: Party(
                id: UUID(),
                createdAt: Date(),
                title: "Secret Event",
                description: "You're invited",
                coverImageUrl: nil,
                location: "TBA",
                partyDate: Date().addingTimeInterval(172800),
                endDate: nil,
                isActive: false,
                isPublic: false,
                maxGuests: 20,
                hosts: nil,
                guests: nil,
                mediaCount: 0,
                commentCount: 0
            )
        )
    ]
}
