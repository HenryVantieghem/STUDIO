//
//  FeedService.swift
//  STUDIO
//
//  Created by Claude on 12/16/25.
//

import Foundation
import Supabase

// MARK: - Feed Service

/// Service for feed/timeline operations
final class FeedService: Sendable {

    // MARK: - Feed

    /// Get user's feed (parties they're part of, chronologically)
    func getFeed(limit: Int = 20, offset: Int = 0) async throws -> [Party] {
        let userId = try await supabase.auth.session.user.id

        // First get party IDs where user is a host
        let hostPartyIds: [UUID] = try await getHostedPartyIds(userId: userId)

        // Then get party IDs where user is a guest
        let guestPartyIds: [UUID] = try await getGuestPartyIds(userId: userId)

        // Combine and deduplicate
        let allPartyIds = Array(Set(hostPartyIds + guestPartyIds))

        guard !allPartyIds.isEmpty else {
            return []
        }

        // Fetch parties with details
        let parties: [Party] = try await supabase
            .from("parties")
            .select("""
                *,
                hosts:party_hosts(*, user:profiles(*)),
                guests:party_guests(*, user:profiles(*)),
                media_count:party_media(count),
                comment_count:party_comments(count)
            """)
            .in("id", values: allPartyIds.map { $0.uuidString })
            .order("created_at", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()
            .value

        return parties
    }

    /// Get active parties (currently happening)
    func getActiveParties() async throws -> [Party] {
        let userId = try await supabase.auth.session.user.id

        let hostPartyIds = try await getHostedPartyIds(userId: userId)
        let guestPartyIds = try await getGuestPartyIds(userId: userId)
        let allPartyIds = Array(Set(hostPartyIds + guestPartyIds))

        guard !allPartyIds.isEmpty else {
            return []
        }

        let parties: [Party] = try await supabase
            .from("parties")
            .select("""
                *,
                hosts:party_hosts(*, user:profiles(*)),
                media_count:party_media(count)
            """)
            .eq("is_active", value: true)
            .in("id", values: allPartyIds.map { $0.uuidString })
            .order("created_at", ascending: false)
            .execute()
            .value

        return parties
    }

    /// Get upcoming parties
    func getUpcomingParties() async throws -> [Party] {
        let userId = try await supabase.auth.session.user.id
        let now = ISO8601DateFormatter().string(from: Date())

        let hostPartyIds = try await getHostedPartyIds(userId: userId)
        let guestPartyIds = try await getGuestPartyIds(userId: userId)
        let allPartyIds = Array(Set(hostPartyIds + guestPartyIds))

        guard !allPartyIds.isEmpty else {
            return []
        }

        let parties: [Party] = try await supabase
            .from("parties")
            .select("""
                *,
                hosts:party_hosts(*, user:profiles(*)),
                guests:party_guests(status)
            """)
            .gte("party_date", value: now)
            .in("id", values: allPartyIds.map { $0.uuidString })
            .order("party_date", ascending: true)
            .execute()
            .value

        return parties
    }

    /// Get past parties (memories)
    func getPastParties(limit: Int = 20, offset: Int = 0) async throws -> [Party] {
        let userId = try await supabase.auth.session.user.id

        let hostPartyIds = try await getHostedPartyIds(userId: userId)
        let guestPartyIds = try await getGuestPartyIds(userId: userId)
        let allPartyIds = Array(Set(hostPartyIds + guestPartyIds))

        guard !allPartyIds.isEmpty else {
            return []
        }

        let parties: [Party] = try await supabase
            .from("parties")
            .select("""
                *,
                hosts:party_hosts(*, user:profiles(*)),
                media_count:party_media(count)
            """)
            .eq("is_active", value: false)
            .in("id", values: allPartyIds.map { $0.uuidString })
            .order("end_date", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()
            .value

        return parties
    }

    // MARK: - Helper Methods

    private func getHostedPartyIds(userId: UUID) async throws -> [UUID] {
        struct HostRecord: Decodable {
            let partyId: UUID

            enum CodingKeys: String, CodingKey {
                case partyId = "party_id"
            }
        }

        let hosts: [HostRecord] = try await supabase
            .from("party_hosts")
            .select("party_id")
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value

        return hosts.map { $0.partyId }
    }

    private func getGuestPartyIds(userId: UUID) async throws -> [UUID] {
        struct GuestRecord: Decodable {
            let partyId: UUID

            enum CodingKeys: String, CodingKey {
                case partyId = "party_id"
            }
        }

        let guests: [GuestRecord] = try await supabase
            .from("party_guests")
            .select("party_id")
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value

        return guests.map { $0.partyId }
    }

    // MARK: - Pending Invitations

    /// Get pending party invitations for current user
    func getPendingInvitations() async throws -> [PartyGuest] {
        let userId = try await supabase.auth.session.user.id

        let invitations: [PartyGuest] = try await supabase
            .from("party_guests")
            .select("""
                *,
                party:parties(*,
                    hosts:party_hosts(*, user:profiles(*))
                ),
                inviter:profiles!invited_by(*)
            """)
            .eq("user_id", value: userId.uuidString)
            .eq("status", value: GuestStatus.pending.rawValue)
            .order("invited_at", ascending: false)
            .execute()
            .value

        return invitations
    }

    // MARK: - Search

    /// Search parties by title or location
    func searchParties(query: String, limit: Int = 20) async throws -> [Party] {
        let userId = try await supabase.auth.session.user.id

        let hostPartyIds = try await getHostedPartyIds(userId: userId)
        let guestPartyIds = try await getGuestPartyIds(userId: userId)
        let allPartyIds = Array(Set(hostPartyIds + guestPartyIds))

        guard !allPartyIds.isEmpty else {
            return []
        }

        let parties: [Party] = try await supabase
            .from("parties")
            .select("""
                *,
                hosts:party_hosts(*, user:profiles(*))
            """)
            .or("title.ilike.%\(query)%,location.ilike.%\(query)%")
            .in("id", values: allPartyIds.map { $0.uuidString })
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value

        return parties
    }
}

// MARK: - Feed Item

/// Unified feed item for display
struct FeedItem: Identifiable, Hashable {
    let id: UUID
    let party: Party
    let latestActivity: FeedActivity?
    let previewMedia: [PartyMedia]?

    static func == (lhs: FeedItem, rhs: FeedItem) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

enum FeedActivity {
    case newMedia(count: Int, by: User)
    case newComment(by: User)
    case statusUpdate(status: PartyStatus)
    case pollCreated(poll: PartyPoll)
    case guestJoined(user: User)
}
