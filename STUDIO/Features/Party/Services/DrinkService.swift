//
//  DrinkService.swift
//  STUDIO
//
//  Service for party drink logging and tracking
//  Basel Afterdark Design System
//

import Foundation
import Supabase

// MARK: - Drink Service

/// Service for logging and managing drinks at parties
final class DrinkService: Sendable {

    // MARK: - Log Drinks

    /// Log a drink at a party
    func logDrink(partyId: UUID, drinkType: DrinkType, customName: String?) async throws -> DrinkLog {
        let userId = try await supabase.auth.session.user.id

        var request: [String: AnyEncodable] = [
            "party_id": AnyEncodable(partyId),
            "user_id": AnyEncodable(userId),
            "drink_type": AnyEncodable(drinkType.rawValue)
        ]

        if let customName { request["custom_name"] = AnyEncodable(customName) }

        let drink: DrinkLog = try await supabase
            .from("drink_logs")
            .insert(request)
            .select("*, user:profiles(*)")
            .single()
            .execute()
            .value

        return drink
    }

    /// Get drinks logged at a party
    func getDrinks(partyId: UUID, limit: Int = 100) async throws -> [DrinkLog] {
        let drinks: [DrinkLog] = try await supabase
            .from("drink_logs")
            .select("*, user:profiles(*)")
            .eq("party_id", value: partyId.uuidString)
            .order("logged_at", ascending: false)
            .limit(limit)
            .execute()
            .value

        return drinks
    }

    /// Get drinks logged by a user at a party
    func getUserDrinks(partyId: UUID, userId: UUID? = nil) async throws -> [DrinkLog] {
        let targetUserId: UUID
        if let userId {
            targetUserId = userId
        } else {
            targetUserId = try await supabase.auth.session.user.id
        }

        let drinks: [DrinkLog] = try await supabase
            .from("drink_logs")
            .select("*, user:profiles(*)")
            .eq("party_id", value: partyId.uuidString)
            .eq("user_id", value: targetUserId.uuidString)
            .order("logged_at", ascending: false)
            .execute()
            .value

        return drinks
    }

    /// Get drink count by type for a party
    func getDrinkStats(partyId: UUID) async throws -> [DrinkType: Int] {
        struct DrinkCount: Codable {
            let drinkType: String
            let count: Int

            enum CodingKeys: String, CodingKey {
                case drinkType = "drink_type"
                case count
            }
        }

        let counts: [DrinkCount] = try await supabase
            .from("drink_logs")
            .select("drink_type, count:id.count()")
            .eq("party_id", value: partyId.uuidString)
            .execute()
            .value

        var stats: [DrinkType: Int] = [:]
        for count in counts {
            if let type = DrinkType(rawValue: count.drinkType) {
                stats[type] = count.count
            }
        }
        return stats
    }

    /// Get total drink count for a user at a party
    func getUserDrinkCount(partyId: UUID, userId: UUID? = nil) async throws -> Int {
        let targetUserId: UUID
        if let userId {
            targetUserId = userId
        } else {
            targetUserId = try await supabase.auth.session.user.id
        }

        struct CountResult: Codable {
            let count: Int
        }

        let result: [CountResult] = try await supabase
            .from("drink_logs")
            .select("count:id.count()", head: false)
            .eq("party_id", value: partyId.uuidString)
            .eq("user_id", value: targetUserId.uuidString)
            .execute()
            .value

        return result.first?.count ?? 0
    }

    /// Delete a drink log
    func deleteDrinkLog(drinkId: UUID) async throws {
        try await supabase
            .from("drink_logs")
            .delete()
            .eq("id", value: drinkId.uuidString)
            .execute()
    }
}

// MARK: - Venue Hop Service

/// Service for managing multi-location venue hops
final class VenueHopService: Sendable {

    /// Add a venue hop to a party
    func addVenueHop(partyId: UUID, venueName: String, address: String?, latitude: Double?, longitude: Double?, arrivalTime: Date) async throws -> VenueHop {
        let userId = try await supabase.auth.session.user.id

        var request: [String: AnyEncodable] = [
            "party_id": AnyEncodable(partyId),
            "added_by": AnyEncodable(userId),
            "venue_name": AnyEncodable(venueName),
            "arrival_time": AnyEncodable(arrivalTime)
        ]

        if let address { request["address"] = AnyEncodable(address) }
        if let latitude { request["latitude"] = AnyEncodable(latitude) }
        if let longitude { request["longitude"] = AnyEncodable(longitude) }

        let hop: VenueHop = try await supabase
            .from("venue_hops")
            .insert(request)
            .select()
            .single()
            .execute()
            .value

        return hop
    }

    /// Get venue hops for a party
    func getVenueHops(partyId: UUID) async throws -> [VenueHop] {
        let hops: [VenueHop] = try await supabase
            .from("venue_hops")
            .select("*")
            .eq("party_id", value: partyId.uuidString)
            .order("arrival_time", ascending: true)
            .execute()
            .value

        return hops
    }

    /// Update venue hop departure time
    func setDepartureTime(hopId: UUID, departureTime: Date) async throws {
        try await supabase
            .from("venue_hops")
            .update(["departure_time": ISO8601DateFormatter().string(from: departureTime)] as [String: String])
            .eq("id", value: hopId.uuidString)
            .execute()
    }

    /// Mark venue as current location
    func setCurrentVenue(partyId: UUID, hopId: UUID) async throws {
        // Clear previous current venue
        try await supabase
            .from("venue_hops")
            .update(["is_current": false] as [String: Bool])
            .eq("party_id", value: partyId.uuidString)
            .execute()

        // Set new current venue
        try await supabase
            .from("venue_hops")
            .update(["is_current": true] as [String: Bool])
            .eq("id", value: hopId.uuidString)
            .execute()
    }

    /// Get current venue for a party
    func getCurrentVenue(partyId: UUID) async throws -> VenueHop? {
        let hops: [VenueHop] = try await supabase
            .from("venue_hops")
            .select("*")
            .eq("party_id", value: partyId.uuidString)
            .eq("is_current", value: true)
            .limit(1)
            .execute()
            .value

        return hops.first
    }

    /// Delete a venue hop
    func deleteVenueHop(hopId: UUID) async throws {
        try await supabase
            .from("venue_hops")
            .delete()
            .eq("id", value: hopId.uuidString)
            .execute()
    }
}
