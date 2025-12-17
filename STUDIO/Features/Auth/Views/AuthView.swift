//
//  AuthView.swift
//  STUDIO
//
//  Basel Afterdark Design System
//  Dark luxury, minimal techno, retro-futuristic nightlife
//

import SwiftUI

/// Container view for authentication screens
struct AuthView: View {
    @Environment(AuthViewModel.self) private var authVM
    @State private var showSignUp = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.studioBlack.ignoresSafeArea()

                // Content
                if showSignUp {
                    SignUpView(showSignUp: $showSignUp)
                } else {
                    LoginView(showSignUp: $showSignUp)
                }
            }
        }
        .preferredColorScheme(.dark)
        .tint(.studioChrome)
        .alert("ERROR", isPresented: Binding(
            get: { authVM.showError },
            set: { _ in authVM.clearError() }
        )) {
            Button("OK") {
                authVM.clearError()
            }
        } message: {
            Text(authVM.error?.localizedDescription ?? "An error occurred")
        }
    }
}

#Preview("Auth View") {
    AuthView()
        .environment(AuthViewModel())
}
