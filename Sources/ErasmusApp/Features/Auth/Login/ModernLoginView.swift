import SwiftUI
import UserNotifications

#if !canImport(UIKit)
enum UIKeyboardType {
    case `default`, emailAddress, asciiCapable, numbersAndPunctuation, URL, numberPad, phonePad, namePhonePad, email, decimalPad, twitter, webSearch, asciiCapableNumberPad
}
#endif

struct ModernLoginView: View {
    @EnvironmentObject var authManager: FirebaseAuthManager
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var showSignUp = false
    @State private var showForgotPassword = false
    @State private var isAnimating = false
    @StateObject private var googleSignInHelper = GoogleSignInHelper()
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.8),
                        Color.purple.opacity(0.6),
                        Color.blue.opacity(0.4)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        Spacer(minLength: 60)
                        
                        // Logo and title section
                        logoSection
                        
                        // Login form
                        loginFormSection
                        
                        // Action buttons
                        actionButtonsSection
                        
                        // Divider
                        dividerSection
                        
                        // Social login options
                        socialLoginSection
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 24)
                }
                
                // Loading overlay
                if authManager.isLoading {
                    loadingOverlay
                }
            }
            #if os(iOS)
            .navigationBarHidden(true)
            #endif
            .sheet(isPresented: $showSignUp) {
                ModernSignUpView(onFinish: {
                    showSignUp = false
                })
                .environmentObject(authManager)
            }
            .sheet(isPresented: $showForgotPassword) {
                ForgotPasswordView()
                    .environmentObject(authManager)
            }
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
            
            googleSignInHelper.onLoginSuccess = { idToken, accessToken in
                Task {
                    do {
                        try await authManager.signInWithGoogle(idToken: idToken, accessToken: accessToken)
                    } catch {
                        authManager.authError = .unknownError(error.localizedDescription)
                    }
                }
            }
            
            googleSignInHelper.onError = { error in
                authManager.authError = .unknownError(error.localizedDescription)
            }
        }
        .onChange(of: authManager.isAuthenticated) { isAuth in
            if isAuth {
                if !UserDefaults.standard.bool(forKey: "didRequestPermissions") {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        requestPermissions()
                    }
                }
            }
        }
    }
    
    // MARK: - Permissions
    private func requestPermissions() {
        UserDefaults.standard.set(true, forKey: "didRequestPermissions")
        // Location
        LocationManager.shared.requestAuthorization()
        // Notifications
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
    }

    // MARK: - Logo Section
    private var logoSection: some View {
        VStack(spacing: 20) {
            Image("app_logo")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .scaleEffect(isAnimating ? 1.0 : 0.8)
                .opacity(isAnimating ? 1.0 : 0.0)
                .animation(.spring(response: 0.8, dampingFraction: 0.6), value: isAnimating)
            
            VStack(spacing: 8) {
                Text("Erasmus Connect")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.6).delay(0.2), value: isAnimating)
                
                Text("Conecta con estudiantes de todo el mundo")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.6).delay(0.4), value: isAnimating)
            }
        }
    }
    
    // MARK: - Login Form Section
    private var loginFormSection: some View {
        VStack(spacing: 20) {
            // Email field
            ModernTextField(
                text: $email,
                placeholder: "Email",
                icon: "envelope.fill",
                keyboardType: .emailAddress
            )
            .opacity(isAnimating ? 1.0 : 0.0)
            .offset(y: isAnimating ? 0 : 20)
            .animation(.easeInOut(duration: 0.6).delay(0.6), value: isAnimating)
            
            // Password field
            LoginSecureField(
                text: $password,
                placeholder: "Contraseña",
                icon: "lock.fill",
                showPassword: $showPassword
            )
            .opacity(isAnimating ? 1.0 : 0.0)
            .offset(y: isAnimating ? 0 : 20)
            .animation(.easeInOut(duration: 0.6).delay(0.8), value: isAnimating)
            
            // Forgot password
            HStack {
                Spacer()
                Button("¿Olvidaste tu contraseña?") {
                    showForgotPassword = true
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .opacity(isAnimating ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.6).delay(1.0), value: isAnimating)
            }
        }
    }
    
    // MARK: - Action Buttons Section
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            // Login button
            Button(action: performLogin) {
                HStack {
                    if authManager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Text("Iniciar Sesión")
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
                                gradient: Gradient(colors: [Color.blue, Color.purple]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .disabled(authManager.isLoading || email.isEmpty || password.isEmpty)
            .opacity((email.isEmpty || password.isEmpty) ? 0.6 : 1.0)
            .opacity(isAnimating ? 1.0 : 0.0)
            .offset(y: isAnimating ? 0 : 20)
            .animation(.easeInOut(duration: 0.6).delay(1.2), value: isAnimating)
            
            // Sign up button
            Button(action: { showSignUp = true }) {
                Text("Crear cuenta")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                    )
            }
            .opacity(isAnimating ? 1.0 : 0.0)
            .offset(y: isAnimating ? 0 : 20)
            .animation(.easeInOut(duration: 0.6).delay(1.4), value: isAnimating)
        }
    }
    
    // MARK: - Divider Section
    private var dividerSection: some View {
        HStack {
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.white.opacity(0.3))
            
            Text("o continúa con")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .padding(.horizontal, 16)
            
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.white.opacity(0.3))
        }
        .opacity(isAnimating ? 1.0 : 0.0)
        .animation(.easeInOut(duration: 0.6).delay(1.6), value: isAnimating)
    }
    
    // MARK: - Social Login Section
    private var socialLoginSection: some View {
        HStack(spacing: 20) {
            // Google login
            SocialLoginButton(
                title: "Google",
                icon: "globe",
                action: { googleSignInHelper.signIn() }
            )
        }
        .opacity(isAnimating ? 1.0 : 0.0)
        .animation(.easeInOut(duration: 0.6).delay(1.8), value: isAnimating)
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
                
                Text("Iniciando sesión...")
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
    private func performLogin() {
        Task {
            do {
                try await authManager.signIn(email: email, password: password)
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

// MARK: - Modern Text Field
struct ModernTextField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    let keyboardType: UIKeyboardType
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 24)
            
            TextField(placeholder, text: $text)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                #if canImport(UIKit)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(.never)
                #endif
                .disableAutocorrection(true)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Login Secure Field
struct LoginSecureField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    @Binding var showPassword: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 24)
            
            if showPassword {
                TextField(placeholder, text: $text)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    #if canImport(UIKit)
                    .textInputAutocapitalization(.never)
                    #endif
                    .disableAutocorrection(true)
            } else {
                SecureField(placeholder, text: $text)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    #if canImport(UIKit)
                    .textInputAutocapitalization(.never)
                    #endif
                    .disableAutocorrection(true)
            }
            
            Button(action: { showPassword.toggle() }) {
                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Social Login Button
struct SocialLoginButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - Preview
struct ModernLoginView_Previews: PreviewProvider {
    static var previews: some View {
        ModernLoginView()
            .environmentObject(FirebaseAuthManager())
    }
}
