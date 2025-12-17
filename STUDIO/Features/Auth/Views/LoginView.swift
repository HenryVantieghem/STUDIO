//
//  LoginView.swift
//  STUDIO
//
//  Basel Afterdark Design System
//  Dark luxury, minimal techno, retro-futuristic nightlife
//

import SwiftUI

/// Login screen with Basel Afterdark aesthetic
struct LoginView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Binding var showSignUp: Bool
    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case email, password
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 48) {
                Spacer().frame(height: 80)

                // Logo & Header
                headerSection

                Spacer().frame(height: 24)

                // Login Form
                formSection()

                // Sign In Button
                signInButton

                // Divider
                dividerSection

                // Sign Up Link
                signUpSection

                Spacer().frame(height: 60)
            }
            .padding(.horizontal, 32)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.studioBlack)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 24) {
            // Geometric icon
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 32, weight: .ultraLight))
                .foregroundStyle(Color.studioChrome)

            // App name - Display Large
            Text("STUDIO")
                .studioDisplayLarge()

            // Tagline - Body Medium
            Text("WHERE THE PARTY NEVER ENDS")
                .studioLabelMedium()
        }
    }

    // MARK: - Form Section

    @ViewBuilder
    private func formSection() -> some View {
        @Bindable var vm = authVM
        VStack(spacing: 24) {
            // Email Field
            VStack(alignment: .leading, spacing: 12) {
                Text("EMAIL")
                    .studioLabelSmall()

                TextField("", text: $vm.email, prompt: Text("ENTER YOUR EMAIL")
                    .font(StudioTypography.bodyMedium)
                    .foregroundStyle(Color.studioMuted.opacity(0.5)))
                    .font(StudioTypography.bodyMedium)
                    .foregroundStyle(Color.studioPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .background(Color.studioSurface)
                    .overlay {
                        Rectangle()
                            .stroke(Color.studioLine, lineWidth: 0.5)
                    }
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .focused($focusedField, equals: .email)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .password }
            }

            // Password Field
            VStack(alignment: .leading, spacing: 12) {
                Text("PASSWORD")
                    .studioLabelSmall()

                SecureField("", text: $vm.password, prompt: Text("ENTER YOUR PASSWORD")
                    .font(StudioTypography.bodyMedium)
                    .foregroundStyle(Color.studioMuted.opacity(0.5)))
                    .font(StudioTypography.bodyMedium)
                    .foregroundStyle(Color.studioPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .background(Color.studioSurface)
                    .overlay {
                        Rectangle()
                            .stroke(Color.studioLine, lineWidth: 0.5)
                    }
                    .textContentType(.password)
                    .focused($focusedField, equals: .password)
                    .submitLabel(.go)
                    .onSubmit {
                        if authVM.isSignInValid {
                            Task { await authVM.signIn() }
                        }
                    }
            }

            // Forgot Password
            HStack {
                Spacer()
                Button {
                    Task { await authVM.resetPassword() }
                } label: {
                    Text("FORGOT PASSWORD")
                        .font(StudioTypography.labelSmall)
                        .tracking(StudioTypography.trackingNormal)
                        .foregroundStyle(Color.studioChrome)
                }
            }
        }
    }

    // MARK: - Sign In Button

    private var signInButton: some View {
        Button {
            focusedField = nil
            Task { await authVM.signIn() }
        } label: {
            Group {
                if authVM.isLoading {
                    ProgressView()
                        .tint(Color.studioBlack)
                } else {
                    Text("ENTER THE PARTY")
                        .font(StudioTypography.labelLarge)
                        .tracking(StudioTypography.trackingWide)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
        }
        .buttonStyle(.studioPrimary)
        .disabled(!authVM.isSignInValid || authVM.isLoading)
        .opacity(authVM.isSignInValid ? 1.0 : 0.5)
    }

    // MARK: - Divider Section

    private var dividerSection: some View {
        HStack(spacing: 20) {
            Rectangle()
                .fill(Color.studioLine)
                .frame(height: 0.5)

            Text("OR")
                .font(StudioTypography.labelSmall)
                .tracking(StudioTypography.trackingWide)
                .foregroundStyle(Color.studioMuted)

            Rectangle()
                .fill(Color.studioLine)
                .frame(height: 0.5)
        }
    }

    // MARK: - Sign Up Section

    private var signUpSection: some View {
        VStack(spacing: 20) {
            Text("NEW TO STUDIO")
                .studioLabelMedium()

            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showSignUp = true
                }
            } label: {
                Text("GET ON THE GUEST LIST")
                    .font(StudioTypography.labelLarge)
                    .tracking(StudioTypography.trackingWide)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
            }
            .buttonStyle(.studioSecondary)
        }
    }
}

#Preview("Login View") {
    LoginView(showSignUp: .constant(false))
        .environment(AuthViewModel())
}
