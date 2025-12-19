//
//  AuthViewModel.swift
//  STUDIO
//
//  Created by Claude on 12/16/25.
//

import Foundation
import Observation
import Supabase

/// View model for authentication state and operations
@Observable
@MainActor
class AuthViewModel {
    // MARK: - State

    var isAuthenticated = false
    var currentUser: User?
    var isLoading = false
    var error: Error?
    var showError = false
    var needsOnboarding = false  // True after fresh signup

    // MARK: - Form State

    var email = ""
    var password = ""
    var confirmPassword = ""
    var username = ""
    var displayName = ""

    // MARK: - Computed Properties

    var isSignInValid: Bool {
        !email.isEmpty && !password.isEmpty && password.count >= 6
    }

    var isSignUpValid: Bool {
        !email.isEmpty &&
        !password.isEmpty &&
        password.count >= 6 &&
        password == confirmPassword &&
        !username.isEmpty &&
        username.count >= 3
    }

    var passwordsMatch: Bool {
        password == confirmPassword
    }

    // MARK: - Initialization

    init() {
        // Check initial session state
        Task {
            await checkInitialSession()
            await observeAuthState()
        }
    }

    // MARK: - Initial Session Check

    private func checkInitialSession() async {
        do {
            let session = try await supabase.auth.session
            isAuthenticated = session != nil
            if session != nil {
                await loadCurrentUser()
            }
        } catch {
            // No active session
            isAuthenticated = false
        }
    }

    // MARK: - Auth State Observation

    private func observeAuthState() async {
        for await state in supabase.auth.authStateChanges {
            if [.initialSession, .signedIn, .signedOut].contains(state.event) {
                isAuthenticated = state.session != nil

                if state.session != nil {
                    await loadCurrentUser()
                } else {
                    currentUser = nil
                }
            }
        }
    }

    // MARK: - Load User

    func loadCurrentUser() async {
        do {
            currentUser = try await AuthService.shared.fetchCurrentUserProfile()
        } catch {
            self.error = error
            showError = true
        }
    }

    // MARK: - Sign In

    func signIn() async {
        guard isSignInValid else { return }

        isLoading = true
        error = nil

        do {
            try await AuthService.shared.signIn(email: email, password: password)
            clearForm()
        } catch {
            self.error = error
            showError = true
        }

        isLoading = false
    }

    // MARK: - Sign Up

    func signUp() async {
        guard isSignUpValid else { return }

        isLoading = true
        error = nil

        do {
            let user = try await AuthService.shared.signUp(
                email: email,
                password: password,
                username: username,
                displayName: displayName.isEmpty ? nil : displayName
            )
            currentUser = user
            needsOnboarding = true  // Show permissions onboarding after signup
            clearForm()
        } catch {
            self.error = error
            showError = true
        }

        isLoading = false
    }

    // MARK: - Sign Out

    func signOut() async {
        isLoading = true

        do {
            try await AuthService.shared.signOut()
            currentUser = nil
            clearForm()
        } catch {
            self.error = error
            showError = true
        }

        isLoading = false
    }

    // MARK: - Password Reset

    func resetPassword() async {
        guard !email.isEmpty else { return }

        isLoading = true

        do {
            try await AuthService.shared.resetPassword(email: email)
        } catch {
            self.error = error
            showError = true
        }

        isLoading = false
    }

    // MARK: - Helpers

    private func clearForm() {
        email = ""
        password = ""
        confirmPassword = ""
        username = ""
        displayName = ""
    }

    func clearError() {
        error = nil
        showError = false
    }
}
