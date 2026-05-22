import SwiftUI


// MARK: - Modern Input Field (refinado)
struct ModernInputField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    var validation: ((String) -> Bool)? = nil
    var errorMessage: String? = nil
    var autocapitalization: UITextAutocapitalizationType = .none

    @FocusState private var isFocused: Bool

    private var isValid: Bool { validation?(text) ?? true }
    private var showError: Bool { !text.isEmpty && !isValid }
    private var showSuccess: Bool { !text.isEmpty && isValid && validation != nil }

    private var borderColor: Color {
        if showError { return .red.opacity(0.7) }
        if showSuccess { return .green.opacity(0.7) }
        if isFocused { return .blue.opacity(0.6) }
        return .white.opacity(0.15)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption).fontWeight(.semibold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .padding(.leading, 4)

            HStack(spacing: 12) {
                Text(icon)
                    .font(.system(size: 20))

                TextField(placeholder, text: $text)
                    #if os(iOS)
                    .keyboardType(keyboardType)
                    .autocapitalization(autocapitalization)
                    .disableAutocorrection(keyboardType == .emailAddress)
                    #endif
                    .textFieldStyle(PlainTextFieldStyle())
                    .focused($isFocused)

                if showSuccess {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .transition(.scale.combined(with: .opacity))
                } else if showError {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.red)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(borderColor, lineWidth: isFocused || showSuccess || showError ? 1.5 : 1)
                    )
            )
            .animation(.easeOut(duration: 0.18), value: isFocused)
            .animation(.easeOut(duration: 0.18), value: showSuccess)
            .animation(.easeOut(duration: 0.18), value: showError)

            if showError, let errorMessage = errorMessage {
                HStack(spacing: 4) {
                    Image(systemName: "info.circle.fill")
                        .font(.caption2)
                    Text(errorMessage)
                        .font(.caption)
                }
                .foregroundColor(.red)
                .padding(.leading, 4)
                .transition(.opacity)
            }
        }
    }
}

// MARK: - Modern Phone Field con prefijo de país
struct ModernPhoneField: View {
    let title: String
    @Binding var prefix: String       // ej "+34"
    @Binding var phone: String
    var validation: ((String) -> Bool)? = nil
    var errorMessage: String? = nil

    @FocusState private var isFocused: Bool

    /// Catálogo corto de prefijos. Por ahora limitado a países con Erasmus relevantes.
    let prefixes: [(String, String, String)] = [
        ("🇪🇸", "+34", "España"),
        ("🇮🇹", "+39", "Italia"),
        ("🇫🇷", "+33", "Francia"),
        ("🇩🇪", "+49", "Alemania"),
        ("🇵🇹", "+351", "Portugal"),
        ("🇳🇱", "+31", "Países Bajos"),
        ("🇧🇪", "+32", "Bélgica"),
        ("🇬🇧", "+44", "Reino Unido"),
        ("🇮🇪", "+353", "Irlanda"),
        ("🇵🇱", "+48", "Polonia"),
        ("🇨🇿", "+420", "Chequia"),
        ("🇦🇹", "+43", "Austria"),
        ("🇬🇷", "+30", "Grecia"),
        ("🇸🇪", "+46", "Suecia"),
        ("🇩🇰", "+45", "Dinamarca"),
        ("🇫🇮", "+358", "Finlandia"),
        ("🇳🇴", "+47", "Noruega"),
        ("🇨🇭", "+41", "Suiza"),
        ("🇲🇽", "+52", "México"),
        ("🇦🇷", "+54", "Argentina"),
        ("🇨🇴", "+57", "Colombia")
    ]

    private var isValid: Bool { validation?(phone) ?? true }
    private var showError: Bool { !phone.isEmpty && !isValid }
    private var showSuccess: Bool { !phone.isEmpty && isValid && validation != nil }

    private var borderColor: Color {
        if showError { return .red.opacity(0.7) }
        if showSuccess { return .green.opacity(0.7) }
        if isFocused { return .blue.opacity(0.6) }
        return .white.opacity(0.15)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption).fontWeight(.semibold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .padding(.leading, 4)

            HStack(spacing: 10) {
                Menu {
                    ForEach(prefixes, id: \.1) { flag, code, name in
                        Button(action: { prefix = code }) {
                            Label("\(flag) \(name) (\(code))", systemImage: prefix == code ? "checkmark" : "")
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(prefixes.first(where: { $0.1 == prefix })?.0 ?? "🌍")
                        Text(prefix)
                            .font(.subheadline).fontWeight(.semibold)
                            .foregroundColor(.primary)
                        Image(systemName: "chevron.down")
                            .font(.caption2).foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 10).padding(.vertical, 8)
                    .background(Color.blue.opacity(0.12))
                    .clipShape(Capsule())
                }

                TextField("612345678", text: $phone)
                    #if os(iOS)
                    .keyboardType(.phonePad)
                    #endif
                    .textFieldStyle(PlainTextFieldStyle())
                    .focused($isFocused)
                    .onChange(of: phone) { newValue in
                        // Mantener solo dígitos
                        phone = newValue.filter { $0.isNumber }
                    }

                if showSuccess {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .transition(.scale.combined(with: .opacity))
                } else if showError {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.red)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(borderColor, lineWidth: isFocused || showSuccess || showError ? 1.5 : 1)
                    )
            )
            .animation(.easeOut(duration: 0.18), value: isFocused)
            .animation(.easeOut(duration: 0.18), value: showSuccess)
            .animation(.easeOut(duration: 0.18), value: showError)

            if showError, let errorMessage = errorMessage {
                HStack(spacing: 4) {
                    Image(systemName: "info.circle.fill").font(.caption2)
                    Text(errorMessage).font(.caption)
                }
                .foregroundColor(.red)
                .padding(.leading, 4)
            }
        }
    }
}

// MARK: - OTP Field (6 cajitas para verificación)
struct OTPField: View {
    @Binding var code: String
    var length: Int = 6

    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack {
            // TextField oculto para capturar input
            TextField("", text: $code)
                #if os(iOS)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                #endif
                .focused($isFocused)
                .opacity(0.01)
                .onChange(of: code) { newValue in
                    let filtered = newValue.filter { $0.isNumber }
                    if filtered.count > length {
                        code = String(filtered.prefix(length))
                    } else if filtered != newValue {
                        code = filtered
                    }
                }

            HStack(spacing: 10) {
                ForEach(0..<length, id: \.self) { idx in
                    let chars = Array(code)
                    let char: String = idx < chars.count ? String(chars[idx]) : ""
                    let isActive = idx == chars.count

                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        isActive ? Color.blue : (char.isEmpty ? Color.white.opacity(0.2) : Color.green.opacity(0.6)),
                                        lineWidth: isActive ? 2 : 1
                                    )
                            )
                        Text(char)
                            .font(.title2).fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                    .frame(width: 46, height: 56)
                    .scaleEffect(isActive ? 1.05 : 1.0)
                    .animation(.spring(response: 0.25), value: isActive)
                }
            }
            .onTapGesture { isFocused = true }
        }
        .onAppear { isFocused = true }
    }
}

// MARK: - Modern Secure Field
struct ModernSecureField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    @Binding var showPassword: Bool
    let icon: String
    var validation: ((String) -> Bool)? = nil
    var errorMessage: String? = nil
    
    private var isValid: Bool {
        validation?(text) ?? true
    }
    
    private var showError: Bool {
        !text.isEmpty && !isValid
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            HStack(spacing: 12) {
                Text(icon)
                    .font(.system(size: 18))
                
                Group {
                    if showPassword {
                        TextField(placeholder, text: $text)
                    } else {
                        SecureField(placeholder, text: $text)
                    }
                }
                .textFieldStyle(PlainTextFieldStyle())
                
                if !text.isEmpty {
                    Image(systemName: isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(isValid ? .green : .red)
                        .font(.system(size: 16))
                }
                
                Button(action: { showPassword.toggle() }) {
                    Image(systemName: showPassword ? "eye.slash" : "eye")
                        .foregroundColor(.secondary)
                        .font(.system(size: 16))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                showError ? Color.red.opacity(0.5) :
                                (isValid && !text.isEmpty ? Color.green.opacity(0.5) : Color.clear),
                                lineWidth: 1
                            )
                    )
            )
            
            if showError, let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .transition(.opacity)
            }
        }
    }
}

// MARK: - Modern Search Field
struct ModernSearchField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    @Binding var selection: String
    let suggestions: [String]
    let icon: String
    
    @State private var showSuggestions = false
    
    var filteredSuggestions: [String] {
        if text.isEmpty {
            return suggestions.prefix(5).map { $0 }
        }
        return suggestions.filter { $0.localizedCaseInsensitiveContains(text) }.prefix(5).map { $0 }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Text(icon)
                        .font(.system(size: 18))
                    
                    TextField(placeholder, text: $text)
                        .textFieldStyle(PlainTextFieldStyle())
                        .onChange(of: text) { newValue in
                            showSuggestions = !newValue.isEmpty
                            if selection != newValue {
                                selection = ""
                            }
                        }
                        .onTapGesture {
                            showSuggestions = true
                        }
                    
                    if !selection.isEmpty {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 16))
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(!selection.isEmpty ? Color.green.opacity(0.5) : Color.clear, lineWidth: 1)
                        )
                )
                
                if showSuggestions && !filteredSuggestions.isEmpty {
                    VStack(spacing: 0) {
                        ForEach(filteredSuggestions, id: \.self) { suggestion in
                            Button(action: {
                                text = suggestion
                                selection = suggestion
                                showSuggestions = false
                            }) {
                                HStack {
                                    Text(suggestion)
                                        .foregroundColor(.primary)
                                        .font(.subheadline)
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color.gray.opacity(0.05))
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            if suggestion != filteredSuggestions.last {
                                Divider()
                                    .padding(.horizontal, 16)
                            }
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.05))
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    )
                    .padding(.top, 4)
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .onTapGesture {
            // Dismiss suggestions when tapping outside
            showSuggestions = false
        }
    }
}

// MARK: - Modern Option Card
struct ModernOptionCard: View {
    let isSelected: Bool
    let emoji: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Text(emoji)
                    .font(.system(size: 32))
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(color.opacity(0.1))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? color.opacity(0.05) : Color.gray.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? color.opacity(0.3) : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Modern City Card
struct ModernCityCard: View {
    let city: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text("🏛️")
                    .font(.system(size: 32))
                
                Text(city)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Modern Destination Card
struct ModernDestinationCard: View {
    let city: String
    
    var body: some View {
        VStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 12)
                .fill(LinearGradient(colors: [.blue.opacity(0.3), .purple.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(height: 100)
                .overlay(
                    Text("🏛️")
                        .font(.system(size: 40))
                )
            
            VStack(spacing: 4) {
                Text(city)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                HStack(spacing: 4) {
                    ForEach(0..<5) { _ in
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                    Text("4.8")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text("🎭 Cultura • 🍕 Gastronomía")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.05))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Modern Chip
struct ModernChip: View {
    let text: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.blue)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.blue.opacity(0.1))
        )
    }
}

// MARK: - Modern Interest Chip
struct ModernInterestChip: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(text)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .fontWeight(.bold)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color.blue : Color.gray.opacity(0.15))
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Modern Permission Row
struct ModernPermissionRow: View {
    let emoji: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Text(emoji)
                .font(.system(size: 28))
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: .blue))
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.15))
        )
    }
}

// MARK: - Modern Text Field Style
struct ModernTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.15))
            )
    }
}

// MARK: - Supporting Extensions
#if canImport(UIKit)
extension UIApplication {
    var windows: [UIWindow] {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
    }
}
#endif
