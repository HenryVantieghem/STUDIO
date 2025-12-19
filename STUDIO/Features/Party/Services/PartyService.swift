//
//  PartyService.swift
//  STUDIO
//
//  Created by Claude on 12/16/25.
//

import Foundation
import Supabase

// MARK: - Party Service

/// Service for party-related database operations
final class PartyService: Sendable {

    // MARK: - Party CRUD

    /// Create a new party
    func createParty(_ request: CreatePartyRequest) async throws -> Party {
        // #region agent log
        DebugLogger.log(
            location: "PartyService.swift:19",
            message: "createParty: entry",
            data: ["title": request.title ?? "nil", "hasDescription": request.description != nil, "hasLocation": request.locationName != nil],
            hypothesisId: "A"
        )
        // #endregion
        
        // Get current user ID for created_by
        let userId = try await supabase.auth.session.user.id
        
        // #region agent log
        DebugLogger.log(
            location: "PartyService.swift:24",
            message: "createParty: got userId",
            data: ["userId": userId.uuidString],
            hypothesisId: "A"
        )
        // #endregion

        // Create request with created_by set
        let fullRequest = CreatePartyRequest(
            title: request.title,
            description: request.description,
            location: request.locationName,
            partyDate: request.startsAt,
            maxGuests: request.maxGuests,
            createdBy: userId
        )

        // #region agent log
        DebugLogger.log(
            location: "PartyService.swift:35",
            message: "createParty: before insert",
            data: ["title": fullRequest.title ?? "nil", "createdBy": fullRequest.createdBy?.uuidString ?? "nil"],
            hypothesisId: "A"
        )
        // #endregion

        do {
            let party: Party = try await supabase
                .from("parties")
                .insert(fullRequest)
                .select()
                .single()
                .execute()
                .value

            // #region agent log
            DebugLogger.log(
                location: "PartyService.swift:43",
                message: "createParty: party created",
                data: ["partyId": party.id.uuidString],
                hypothesisId: "A"
            )
            // #endregion

            // Add creator as host
            try await addHost(partyId: party.id, role: .creator)

            // #region agent log
            DebugLogger.log(
                location: "PartyService.swift:50",
                message: "createParty: host added, success",
                data: ["partyId": party.id.uuidString],
                hypothesisId: "A"
            )
            // #endregion

            return party
        } catch {
            // #region agent log
            DebugLogger.log(
                location: "PartyService.swift:58",
                message: "createParty: error occurred",
                data: [
                    "error": error.localizedDescription,
                    "errorType": String(describing: type(of: error))
                ],
                hypothesisId: "A"
            )
            // #endregion
            throw error
        }
    }

    /// Get a party by ID with all relationships
    func getParty(id: UUID) async throws -> Party {
        let party: Party = try await supabase
            .from("parties")
            .select("""
                *,
                hosts:party_hosts(*, user:profiles(*)),
                guests:party_guests(*, user:profiles(*)),
                media_count:party_media(count),
                comment_count:party_comments(count)
            """)
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value

        return party
    }

    /// Update a party
    func updateParty(id: UUID, title: String?, description: String?, location: String?, partyDate: Date?) async throws {
        var updates: [String: AnyEncodable] = [:]

        if let title { updates["title"] = AnyEncodable(title) }
        if let description { updates["description"] = AnyEncodable(description) }
        if let location { updates["location_name"] = AnyEncodable(location) }
        if let partyDate { updates["starts_at"] = AnyEncodable(partyDate) }

        guard !updates.isEmpty else { return }

        try await supabase
            .from("parties")
            .update(updates)
            .eq("id", value: id.uuidString)
            .execute()
    }

    /// Delete a party (only creator can do this)
    func deleteParty(id: UUID) async throws {
        try await supabase
            .from("parties")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    /// End a party (set status to ended)
    func endParty(id: UUID) async throws {
        let updates: [String: AnyEncodable] = [
            "status": AnyEncodable("ended"),
            "ends_at": AnyEncodable(Date())
        ]
        try await supabase
            .from("parties")
            .update(updates)
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Hosts

    /// Add a host to a party (up to 5)
    func addHost(partyId: UUID, userId: UUID? = nil, role: HostRole = .cohost) async throws {
        // #region agent log
        DebugLogger.log(
            location: "PartyService.swift:152",
            message: "addHost: entry",
            data: ["partyId": partyId.uuidString, "role": role.rawValue, "hasUserId": userId != nil],
            hypothesisId: "B"
        )
        // #endregion
        
        let hostUserId: UUID
        if let userId {
            hostUserId = userId
        } else {
            hostUserId = try await supabase.auth.session.user.id
        }

        let request: [String: AnyEncodable] = [
            "party_id": AnyEncodable(partyId),
            "user_id": AnyEncodable(hostUserId),
            "role": AnyEncodable(role.rawValue)
        ]

        // #region agent log
        DebugLogger.log(
            location: "PartyService.swift:172",
            message: "addHost: before insert",
            data: ["partyId": partyId.uuidString, "userId": hostUserId.uuidString, "role": role.rawValue],
            hypothesisId: "B"
        )
        // #endregion

        do {
            try await supabase
                .from("party_hosts")
                .insert(request)
                .execute()
            
            // #region agent log
            DebugLogger.log(
                location: "PartyService.swift:182",
                message: "addHost: insert successful",
                data: ["partyId": partyId.uuidString],
                hypothesisId: "B"
            )
            // #endregion
        } catch {
            // #region agent log
            DebugLogger.log(
                location: "PartyService.swift:189",
                message: "addHost: error occurred",
                data: [
                    "error": error.localizedDescription,
                    "errorType": String(describing: type(of: error)),
                    "partyId": partyId.uuidString
                ],
                hypothesisId: "B"
            )
            // #endregion
            throw error
        }
    }

    /// Remove a host from a party
    func removeHost(partyId: UUID, userId: UUID) async throws {
        try await supabase
            .from("party_hosts")
            .delete()
            .eq("party_id", value: partyId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .execute()
    }

    /// Get all hosts for a party
    func getHosts(partyId: UUID) async throws -> [PartyHost] {
        let hosts: [PartyHost] = try await supabase
            .from("party_hosts")
            .select("*, user:profiles(*)")
            .eq("party_id", value: partyId.uuidString)
            .execute()
            .value

        return hosts
    }

    // MARK: - Guests

    /// Invite a guest to a party
    func inviteGuest(partyId: UUID, userId: UUID) async throws {
        let inviterId = try await supabase.auth.session.user.id

        let request: [String: AnyEncodable] = [
            "party_id": AnyEncodable(partyId),
            "user_id": AnyEncodable(userId),
            "invited_by": AnyEncodable(inviterId),
            "status": AnyEncodable(GuestStatus.pending.rawValue)
        ]

        try await supabase
            .from("party_guests")
            .insert(request)
            .execute()
    }

    /// Update guest RSVP status
    func updateGuestStatus(partyId: UUID, status: GuestStatus) async throws {
        let userId = try await supabase.auth.session.user.id

        try await supabase
            .from("party_guests")
            .update([
                "status": status.rawValue,
                "responded_at": ISO8601DateFormatter().string(from: Date())
            ] as [String: String])
            .eq("party_id", value: partyId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .execute()
    }

    /// Remove a guest from a party
    func removeGuest(partyId: UUID, userId: UUID) async throws {
        try await supabase
            .from("party_guests")
            .delete()
            .eq("party_id", value: partyId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .execute()
    }

    /// Get all guests for a party
    func getGuests(partyId: UUID) async throws -> [PartyGuest] {
        let guests: [PartyGuest] = try await supabase
            .from("party_guests")
            .select("*, user:profiles(*)")
            .eq("party_id", value: partyId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value

        return guests
    }

    // MARK: - User's Parties

    /// Get parties where user is a host
    func getHostedParties() async throws -> [Party] {
        let userId = try await supabase.auth.session.user.id

        let parties: [Party] = try await supabase
            .from("parties")
            .select("""
                *,
                hosts:party_hosts!inner(*, user:profiles(*)),
                media_count:party_media(count)
            """)
            .eq("hosts.user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value

        return parties
    }

    /// Get parties where user is invited
    func getInvitedParties() async throws -> [Party] {
        let userId = try await supabase.auth.session.user.id

        let parties: [Party] = try await supabase
            .from("parties")
            .select("""
                *,
                guests:party_guests!inner(*, user:profiles(*)),
                hosts:party_hosts(*, user:profiles(*)),
                media_count:party_media(count)
            """)
            .eq("guests.user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value

        return parties
    }

    /// Check if user can view a party
    func canViewParty(partyId: UUID) async throws -> Bool {
        let userId = try await supabase.auth.session.user.id

        // Check if host
        let hosts: [PartyHost] = try await supabase
            .from("party_hosts")
            .select("id")
            .eq("party_id", value: partyId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value

        if !hosts.isEmpty { return true }

        // Check if guest
        let guests: [PartyGuest] = try await supabase
            .from("party_guests")
            .select("id")
            .eq("party_id", value: partyId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .eq("status", value: GuestStatus.accepted.rawValue)
            .limit(1)
            .execute()
            .value

        return !guests.isEmpty
    }
}

// MARK: - AnyEncodable Helper

/// Type-erased Encodable wrapper for dynamic dictionaries
struct AnyEncodable: Encodable, Sendable {
    private let _encode: @Sendable (Encoder) throws -> Void

    init<T: Encodable & Sendable>(_ value: T) {
        _encode = { encoder in
            try value.encode(to: encoder)
        }
    }

    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}
