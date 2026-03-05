import SwiftUI

struct ForgotPasswordView: View {
    @StateObject private var authManager = FirebaseAuthManager()
    @Environment(\.dismiss) var dismiss
    
    @State private var email = ""
    @State private var isAnimating = false
    @State private var showSuccessMessage = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.orange.opacity(0.8),
                        Color.red.opacity(0.6),
                        Color.orange.opacity(0.4)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    headerSection
                    
                    if showSuccessMessage {
                        successSection
                    } else {
                        // Form section
                        formSection
                    }
                    
                    Spacer()
                }
                
                // Loading overlay
                if authManager.isLoading {
                    loadingOverlay
                }
            }
            #if canImport(UIKit)
            .navigationBarHidden(true)
            #endif
            .alert("Error", isPresented: .constant(authManager.authError != nil)) {
                Button("OK") {
                    authManager.authError = nil
                }
            } message: {
                if let error = authManager.authError {
                    Text(error.localizedDescription)
                }
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                Text("Recuperar Contraseña")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Invisible button for balance
                Button(action: {}) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.clear)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            
            Text("Te enviaremos un enlace para restablecer tu contraseña")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .opacity(isAnimating ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.6).delay(0.2), value: isAnimating)
        }
    }
    
    // MARK: - Form Section
    private var formSection: some View {
        VStack(spacing: 32) {
            Spacer(minLength: 60)
            
            // Icon
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "lock.rotation")
                        .font(.system(size: 50, weight: .light))
                        .foregroundColor(.white)
                }
                .scaleEffect(isAnimating ? 1.0 : 0.8)
                .opacity(isAnimating ? 1.0 : 0.0)
                .animation(.spring(response: 0.8, dampingFraction: 0.6), value: isAnimating)
                
                Text("¿Olvidaste tu contraseña?")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.6).delay(0.4), value: isAnimating)
                
                Text("No te preocupes, es algo que le pasa a todo el mundo. Solo ingresa tu email y te enviaremos un enlace para restablecer tu contraseña.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.6).delay(0.6), value: isAnimating)
            }
            .padding(.horizontal, 24)
            
            // Email field
            VStack(spacing: 20) {
                ModernTextField(
                    text: $email,
                    placeholder: "Tu email",
                    icon: "envelope.fill",
                    keyboardType: .emailAddress
                )
                .opacity(isAnimating ? 1.0 : 0.0)
                .offset(y: isAnimating ? 0 : 20)
                .animation(.easeInOut(duration: 0.6).delay(0.8), value: isAnimating)
                
                // Reset button
                Button(action: resetPassword) {
                    HStack {
                        if authManager.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Text("Enviar enlace de recuperación")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.orange, Color.red]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .shadow(color: .orange.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .disabled(authManager.isLoading || email.isEmpty || !email.contains("@"))
                .opacity((email.isEmpty || !email.contains("@")) ? 0.6 : 1.0)
                .opacity(isAnimating ? 1.0 : 0.0)
                .offset(y: isAnimating ? 0 : 20)
                .animation(.easeInOut(duration: 0.6).delay(1.0), value: isAnimating)
            }
            .padding(.horizontal, 24)
            
            Spacer(minLength: 40)
        }
    }
    
    // MARK: - Success Section
    private var successSection: some View {
        VStack(spacing: 32) {
            Spacer(minLength: 80)
            
            VStack(spacing: 24) {
                // Success icon
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50, weight: .light))
                        .foregroundColor(.green)
                }
                .scaleEffect(isAnimating ? 1.0 : 0.8)
                .opacity(isAnimating ? 1.0 : 0.0)
                .animation(.spring(response: 0.8, dampingFraction: 0.6), value: isAnimating)
                
                VStack(spacing: 16) {
                    Text("¡Email enviado!")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Hemos enviado un enlace de recuperación a:")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                    
                    Text(email)
                        .font(.system(size: 18, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.15))
                        )
                }
                .opacity(isAnimating ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.6).delay(0.4), value: isAnimating)
                
                VStack(spacing: 16) {
                    Text("¿Qué hacer ahora?")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        InstructionRow(
                            number: "1",
                            text: "Revisa tu bandeja de entrada"
                        )
                        InstructionRow(
                            number: "2",
                            text: "Haz clic en el enlace de recuperación"
                        )
                        InstructionRow(
                            number: "3",
                            text: "Crea una nueva contraseña segura"
                        )
                    }
                    .padding(.horizontal, 20)
                }
                .opacity(isAnimating ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.6).delay(0.6), value: isAnimating)
            }
            .padding(.horizontal, 24)
            
            Spacer(minLength: 40)
            
            // Close button
            Button(action: { dismiss() }) {
                Text("Entendido")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.green.opacity(0.8))
                    )
                    .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .opacity(isAnimating ? 1.0 : 0.0)
            .animation(.easeInOut(duration: 0.6).delay(0.8), value: isAnimating)
        }
    }
    
    // MARK: - Loading Overlay
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                
                Text("Enviando email...")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.8))
            )
        }
    }
    
    // MARK: - Actions
    private func resetPassword() {
        Task {
            do {
                try await authManager.resetPassword(email: email)
                showSuccessMessage = true
            } catch {
                // Error is handled by the auth manager
            }
        }
    }
    
    private func startAnimations() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isAnimating = true
        }
    }
}

// MARK: - Instruction Row
struct InstructionRow: View {
    let number: String
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.8))
                    .frame(width: 28, height: 28)
                
                Text(number)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Text(text)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
        }
    }
}

// MARK: - Preview
struct ForgotPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        ForgotPasswordView()
    }
}
