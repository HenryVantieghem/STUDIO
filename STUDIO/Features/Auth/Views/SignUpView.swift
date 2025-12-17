//
//  SignUpView.swift
//  STUDIO
//
//  Basel Afterdark Design System
//  Dark luxury, minimal techno, retro-futuristic nightlife
//

import SwiftUI

/// Sign up screen with Basel Afterdark aesthetic
struct SignUpView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Binding var showSignUp: Bool
    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case username, displayName, email, password, confirmPassword
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer().frame(height: 48)

                // Header
                headerSection

                Spacer().frame(height: 16)

                // Sign Up Form
                formSection()

                // Sign Up Button
                signUpButton

                // Back to Login
                backToLoginSection

                Spacer().frame(height: 48)
            }
            .padding(.horizontal, 32)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.studioBlack)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 20) {
            // Geometric icon
            Image(systemName: "person.badge.key")
                .font(.system(size: 28, weight: .ultraLight))
                .foregroundStyle(Color.studioChrome)

            // Title - Display Small
            Text("JOIN STUDIO")
                .studioDisplaySmall()

            // Subtitle
            Text("GET ON THE GUEST LIST")
                .studioLabelMedium()
        }
    }

    // MARK: - Form Section

    @ViewBuilder
    private func formSection() -> some View {
        @Bindable var vm = authVM
        VStack(spacing: 20) {
            // Username Field (required)
            formField(
                label: "USERNAME",
                required: true,
                content: {
                    TextField("", text: $vm.username, prompt: Text("CHOOSE A UNIQUE USERNAME")
                        .font(StudioTypography.bodyMedium)
                        .foregroundStyle(Color.studioMuted.opacity(0.5)))
                        .font(StudioTypography.bodyMedium)
                        .foregroundStyle(Color.studioPrimary)
                        .textContentType(.username)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .focused($focusedField, equals: .username)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .displayName }
                },
                error: (!authVM.username.isEmpty && authVM.username.count < 3)
                    ? "USERNAME MUST BE AT LEAST 3 CHARACTERS" : nil
            )

            // Display Name Field (optional)
            formField(
                label: "DISPLAY NAME",
                required: false,
                content: {
                    TextField("", text: $vm.displayName, prompt: Text("HOW SHOULD WE CALL YOU")
                        .font(StudioTypography.bodyMedium)
                        .foregroundStyle(Color.studioMuted.opacity(0.5)))
                        .font(StudioTypography.bodyMedium)
                        .foregroundStyle(Color.studioPrimary)
                        .textContentType(.name)
                        .focused($focusedField, equals: .displayName)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .email }
                }
            )

            // Email Field
            formField(
                label: "EMAIL",
                required: true,
                content: {
                    TextField("", text: $vm.email, prompt: Text("ENTER YOUR EMAIL")
                        .font(StudioTypography.bodyMedium)
                        .foregroundStyle(Color.studioMuted.opacity(0.5)))
                        .font(StudioTypography.bodyMedium)
                        .foregroundStyle(Color.studioPrimary)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .focused($focusedField, equals: .email)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .password }
                }
            )

            // Password Field
            formField(
                label: "PASSWORD",
                required: true,
                content: {
                    SecureField("", text: $vm.password, prompt: Text("CREATE A PASSWORD")
                        .font(StudioTypography.bodyMedium)
                        .foregroundStyle(Color.studioMuted.opacity(0.5)))
                        .font(StudioTypography.bodyMedium)
                        .foregroundStyle(Color.studioPrimary)
                        .textContentType(.newPassword)
                        .focused($focusedField, equals: .password)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .confirmPassword }
                },
                error: (!authVM.password.isEmpty && authVM.password.count < 6)
                    ? "PASSWORD MUST BE AT LEAST 6 CHARACTERS" : nil
            )

            // Confirm Password Field
            formField(
                label: "CONFIRM PASSWORD",
                required: true,
                content: {
                    SecureField("", text: $vm.confirmPassword, prompt: Text("CONFIRM YOUR PASSWORD")
                        .font(StudioTypography.bodyMedium)
                        .foregroundStyle(Color.studioMuted.opacity(0.5)))
                        .font(StudioTypography.bodyMedium)
                        .foregroundStyle(Color.studioPrimary)
                        .textContentType(.newPassword)
                        .focused($focusedField, equals: .confirmPassword)
                        .submitLabel(.go)
                        .onSubmit {
                            if authVM.isSignUpValid {
                                Task { await authVM.signUp() }
                            }
                        }
                },
                error: (!authVM.confirmPassword.isEmpty && !authVM.passwordsMatch)
                    ? "PASSWORDS DO NOT MATCH" : nil
            )

            // Required fields note
            HStack(spacing: 8) {
                Text("*")
                    .font(StudioTypography.labelSmall)
                    .foregroundStyle(Color.studioChrome)
                Text("REQUIRED FIELDS")
                    .font(StudioTypography.labelSmall)
                    .tracking(StudioTypography.trackingNormal)
                    .foregroundStyle(Color.studioMuted)
                Spacer()
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Form Field Helper

    @ViewBuilder
    private func formField<Content: View>(
        label: String,
        required: Bool = false,
        @ViewBuilder content: () -> Content,
        error: String? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 4) {
                Text(label)
                    .font(StudioTypography.labelSmall)
                    .tracking(StudioTypography.trackingNormal)
                    .foregroundStyle(Color.studioMuted)

                if required {
                    Text("*")
                        .font(StudioTypography.labelSmall)
                        .foregroundStyle(Color.studioChrome)
                }
            }

            content()
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(Color.studioSurface)
                .overlay {
                    Rectangle()
                        .stroke(Color.studioLine, lineWidth: 0.5)
                }

            if let error = error {
                Text(error)
                    .font(StudioTypography.labelSmall)
                    .tracking(StudioTypography.trackingNormal)
                    .foregroundStyle(Color.studioError)
            }
        }
    }

    // MARK: - Sign Up Button

    private var signUpButton: some View {
        Button {
            focusedField = nil
            Task { await authVM.signUp() }
        } label: {
            Group {
                if authVM.isLoading {
                    ProgressView()
                        .tint(Color.studioBlack)
                } else {
                    Text("CREATE ACCOUNT")
                        .font(StudioTypography.labelLarge)
                        .tracking(StudioTypography.trackingWide)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
        }
        .buttonStyle(.studioPrimary)
        .disabled(!authVM.isSignUpValid || authVM.isLoading)
        .opacity(authVM.isSignUpValid ? 1.0 : 0.5)
        .padding(.top, 8)
    }

    // MARK: - Back to Login Section

    private var backToLoginSection: some View {
        VStack(spacing: 16) {
            Text("ALREADY HAVE AN ACCOUNT")
                .studioLabelMedium()

            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showSignUp = false
                }
            } label: {
                Text("BACK TO LOGIN")
                    .font(StudioTypography.labelMedium)
                    .tracking(StudioTypography.trackingWide)
                    .foregroundStyle(Color.studioChrome)
            }
        }
        .padding(.top, 8)
    }
}

#Preview("Sign Up View") {
    SignUpView(showSignUp: .constant(true))
        .environment(AuthViewModel())
}
