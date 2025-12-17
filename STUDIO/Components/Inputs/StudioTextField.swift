//
//  StudioTextField.swift
//  STUDIO
//
//  Pixel Afterdark Input Styles
//  8-bit retro aesthetic with pixel borders
//

import SwiftUI

// MARK: - Pixel Font Reference

private let pixelFontName = "VT323"

// MARK: - Studio Text Field

/// Styled text field component with pixel aesthetic
struct StudioTextField: View {
    let title: String
    @Binding var text: String
    var placeholder: String = ""
    var isRequired: Bool = false
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType?
    var autocapitalization: TextInputAutocapitalization = .sentences
    var errorMessage: String?
    var helpText: String?

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Label - Pixel font, ALL CAPS
            HStack(spacing: 6) {
                Text(title)
                    .font(.custom(pixelFontName, size: 14))
                    .tracking(StudioTypography.trackingStandard)
                    .textCase(.uppercase)
                    .foregroundStyle(Color.studioMuted)

                if isRequired {
                    Text("*")
                        .font(.custom(pixelFontName, size: 14))
                        .foregroundStyle(Color.studioChrome)
                }
            }

            // Input Field
            Group {
                if isSecure {
                    SecureField("", text: $text, prompt: promptText)
                } else {
                    TextField("", text: $text, prompt: promptText)
                }
            }
            .textFieldStyle(PixelInputStyle(isFocused: isFocused, hasError: errorMessage != nil))
            .keyboardType(keyboardType)
            .textContentType(textContentType)
            .textInputAutocapitalization(autocapitalization)
            .autocorrectionDisabled(isSecure || keyboardType == .emailAddress)
            .focused($isFocused)

            // Error or Help Text
            if let error = errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 8))
                    Text(error)
                        .font(.custom(pixelFontName, size: 12))
                        .tracking(StudioTypography.trackingNormal)
                }
                .foregroundStyle(Color.studioError)
            } else if let help = helpText {
                Text(help)
                    .font(.custom(pixelFontName, size: 12))
                    .tracking(StudioTypography.trackingNormal)
                    .foregroundStyle(Color.studioMuted)
            }
        }
    }

    private var promptText: Text {
        Text(placeholder.isEmpty ? title.lowercased() : placeholder)
            .foregroundStyle(Color.studioMuted.opacity(0.4))
    }
}

// MARK: - Pixel Input Style

struct PixelInputStyle: TextFieldStyle {
    var isFocused: Bool = false
    var hasError: Bool = false

    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.custom(pixelFontName, size: 18))
            .tracking(StudioTypography.trackingNormal)
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(Color.studioSurface)
            .foregroundStyle(Color.studioPrimary)
            .overlay {
                Rectangle()
                    .stroke(borderColor, lineWidth: isFocused ? 2 : 1)
            }
            .animation(.easeInOut(duration: 0.1), value: isFocused)
    }

    private var borderColor: Color {
        if hasError {
            return .studioError.opacity(0.7)
        } else if isFocused {
            return .studioPrimary
        } else {
            return .studioLine
        }
    }
}

// MARK: - Studio Search Field

/// Search field with icon - pixel style
struct StudioSearchField: View {
    @Binding var text: String
    var placeholder: String = "SEARCH"
    var onSubmit: (() -> Void)?

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12, weight: .light))
                .foregroundStyle(Color.studioMuted)

            TextField(
                "",
                text: $text,
                prompt: Text(placeholder)
                    .font(.custom(pixelFontName, size: 14))
                    .foregroundStyle(Color.studioMuted.opacity(0.4))
            )
            .font(.custom(pixelFontName, size: 16))
            .tracking(StudioTypography.trackingNormal)
            .textCase(.uppercase)
            .foregroundStyle(Color.studioPrimary)
            .focused($isFocused)
            .onSubmit {
                onSubmit?()
            }

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .light))
                        .foregroundStyle(Color.studioMuted)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.studioSurface)
        .overlay {
            Rectangle()
                .stroke(isFocused ? Color.studioPrimary : Color.studioLine, lineWidth: isFocused ? 2 : 1)
        }
    }
}

// MARK: - Studio Text Editor

/// Multi-line text editor - pixel style
struct StudioTextEditor: View {
    let title: String
    @Binding var text: String
    var placeholder: String = ""
    var isRequired: Bool = false
    var maxLength: Int?
    var minHeight: CGFloat = 100

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Label
            HStack(spacing: 6) {
                Text(title)
                    .font(.custom(pixelFontName, size: 14))
                    .tracking(StudioTypography.trackingStandard)
                    .textCase(.uppercase)
                    .foregroundStyle(Color.studioMuted)

                if isRequired {
                    Text("*")
                        .font(.custom(pixelFontName, size: 14))
                        .foregroundStyle(Color.studioChrome)
                }

                Spacer()

                if let max = maxLength {
                    Text("\(text.count)/\(max)")
                        .font(.custom(pixelFontName, size: 12))
                        .foregroundStyle(text.count > max ? Color.studioError : Color.studioMuted)
                }
            }

            // Text Editor
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder.isEmpty ? title.lowercased() : placeholder)
                        .font(.custom(pixelFontName, size: 16))
                        .foregroundStyle(Color.studioMuted.opacity(0.4))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 14)
                }

                TextEditor(text: $text)
                    .font(.custom(pixelFontName, size: 16))
                    .scrollContentBackground(.hidden)
                    .foregroundStyle(Color.studioPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                    .focused($isFocused)
            }
            .frame(minHeight: minHeight)
            .background(Color.studioSurface)
            .overlay {
                Rectangle()
                    .stroke(isFocused ? Color.studioPrimary : Color.studioLine, lineWidth: isFocused ? 2 : 1)
            }
        }
    }
}

// MARK: - Studio Picker

/// Pixel-style picker/dropdown
struct StudioPicker<T: Hashable>: View {
    let title: String
    @Binding var selection: T
    let options: [T]
    let label: (T) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.custom(pixelFontName, size: 14))
                .tracking(StudioTypography.trackingStandard)
                .textCase(.uppercase)
                .foregroundStyle(Color.studioMuted)

            Menu {
                ForEach(options, id: \.self) { option in
                    Button {
                        selection = option
                    } label: {
                        Text(label(option))
                    }
                }
            } label: {
                HStack {
                    Text(label(selection))
                        .font(.custom(pixelFontName, size: 16))
                        .tracking(StudioTypography.trackingNormal)
                        .textCase(.uppercase)
                        .foregroundStyle(Color.studioPrimary)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .light))
                        .foregroundStyle(Color.studioMuted)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background(Color.studioSurface)
                .overlay {
                    Rectangle()
                        .stroke(Color.studioLine, lineWidth: 1)
                }
            }
        }
    }
}

// MARK: - Studio Toggle

/// Pixel-style toggle switch
struct StudioToggle: View {
    let title: String
    @Binding var isOn: Bool
    var subtitle: String?

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.custom(pixelFontName, size: 16))
                        .tracking(StudioTypography.trackingStandard)
                        .textCase(.uppercase)
                        .foregroundStyle(Color.studioPrimary)

                    if let subtitle {
                        Text(subtitle)
                            .font(.custom(pixelFontName, size: 12))
                            .tracking(StudioTypography.trackingNormal)
                            .foregroundStyle(Color.studioMuted)
                    }
                }

                Spacer()

                // Pixel toggle indicator
                HStack(spacing: 2) {
                    Rectangle()
                        .fill(isOn ? Color.studioPrimary : Color.studioLine)
                        .frame(width: 12, height: 12)

                    Rectangle()
                        .fill(isOn ? Color.studioLine : Color.studioPrimary)
                        .frame(width: 12, height: 12)
                }
                .padding(4)
                .background(Color.studioSurface)
                .overlay {
                    Rectangle()
                        .stroke(Color.studioLine, lineWidth: 1)
                }
            }
            .padding(14)
            .background(Color.studioSurface)
            .overlay {
                Rectangle()
                    .stroke(Color.studioLine, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("Pixel Input Fields") {
    ScrollView {
        VStack(spacing: 28) {
            Text("INPUTS")
                .studioLabelSmall()

            StudioTextField(
                title: "EMAIL",
                text: .constant(""),
                placeholder: "enter your email",
                isRequired: true,
                keyboardType: .emailAddress,
                textContentType: .emailAddress
            )

            StudioTextField(
                title: "PASSWORD",
                text: .constant(""),
                placeholder: "create a password",
                isRequired: true,
                isSecure: true,
                textContentType: .newPassword,
                errorMessage: "minimum 6 characters"
            )

            StudioTextField(
                title: "USERNAME",
                text: .constant("afterdark"),
                isRequired: true,
                autocapitalization: .never,
                helpText: "visible to other guests"
            )

            Rectangle()
                .fill(Color.studioLine)
                .frame(height: 1)

            Text("SEARCH")
                .studioLabelSmall()

            StudioSearchField(text: .constant(""))

            Rectangle()
                .fill(Color.studioLine)
                .frame(height: 1)

            Text("TEXT AREA")
                .studioLabelSmall()

            StudioTextEditor(
                title: "BIO",
                text: .constant(""),
                placeholder: "tell us about yourself",
                maxLength: 150,
                minHeight: 100
            )

            Rectangle()
                .fill(Color.studioLine)
                .frame(height: 1)

            Text("TOGGLE")
                .studioLabelSmall()

            StudioToggle(
                title: "NOTIFICATIONS",
                isOn: .constant(true),
                subtitle: "receive event updates"
            )

            StudioToggle(
                title: "PRIVATE PROFILE",
                isOn: .constant(false)
            )
        }
        .padding(20)
    }
    .background(Color.studioBlack)
}
