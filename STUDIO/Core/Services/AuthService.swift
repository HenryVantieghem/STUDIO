//
//  AuthService.swift
//  STUDIO
//
//  Created by Claude on 12/16/25.
//

import Foundation
import Supabase

/// Authentication service handling all auth operations
/// Using final class instead of actor for better Supabase SDK compatibility with Swift 6
final class AuthService: Sendable {
    static let shared = AuthService()

    private init() {}

    // MARK: - Sign Up

    /// Create a new user account with email and password
    func signUp(email: String, password: String, username: String, displayName: String?) async throws -> User {
        // Create auth user
        let authResponse = try await supabase.auth.signUp(
            email: email,
            password: password
        )

        let userId = authResponse.user.id

        // Create or update profile in profiles table (upsert to handle existing records)
        let payload = CreateUserPayload(
            id: userId,
            username: username,
            displayName: displayName,
            avatarUrl: nil
        )

        let user: User = try await supabase
            .from("profiles")
            .upsert(payload, onConflict: "id")
            .select()
            .single()
            .execute()
            .value

        return user
    }

    // MARK: - Sign In

    /// Sign in with email and password
    func signIn(email: String, password: String) async throws {
        _ = try await supabase.auth.signIn(
            email: email,
            password: password
        )
    }

    /// Sign in with Apple
    func signInWithApple(idToken: String, nonce: String) async throws {
        try await supabase.auth.signInWithIdToken(
            credentials: .init(
                provider: .apple,
                idToken: idToken,
                nonce: nonce
            )
        )
    }

    // MARK: - Sign Out

    /// Sign out the current user
    func signOut() async throws {
        try await supabase.auth.signOut()
    }

    // MARK: - Session

    /// Get current session
    func currentSession() async -> Session? {
        try? await supabase.auth.session
    }

    /// Get current user ID
    func currentUserId() async -> UUID? {
        await currentSession()?.user.id
    }

    /// Check if user is authenticated
    func isAuthenticated() async -> Bool {
        await currentSession() != nil
    }

    // MARK: - Profile

    /// Fetch current user's profile
    func fetchCurrentUserProfile() async throws -> User? {
        guard let userId = await currentUserId() else { return nil }

        let user: User = try await supabase
            .from("profiles")
            .select()
            .eq("id", value: userId)
            .single()
            .execute()
            .value

        return user
    }

    /// Update current user's profile
    func updateProfile(_ payload: UpdateUserPayload) async throws -> User {
        guard let userId = await currentUserId() else {
            throw AuthError.notAuthenticated
        }

        let user: User = try await supabase
            .from("profiles")
            .update(payload)
            .eq("id", value: userId)
            .select()
            .single()
            .execute()
            .value

        return user
    }

    // MARK: - Password Reset

    /// Send password reset email
    func resetPassword(email: String) async throws {
        try await supabase.auth.resetPasswordForEmail(email)
    }
}

// MARK: - Auth Errors

enum AuthError: LocalizedError {
    case signUpFailed
    case notAuthenticated
    case profileNotFound

    var errorDescription: String? {
        switch self {
        case .signUpFailed:
            return "Failed to create account. Please try again."
        case .notAuthenticated:
            return "You must be signed in to perform this action."
        case .profileNotFound:
            return "User profile not found."
        }
    }
}
