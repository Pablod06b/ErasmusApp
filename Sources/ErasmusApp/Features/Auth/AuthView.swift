import SwiftUI

struct AuthView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var navigateToHome = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                
                Text("Iniciar Sesión")
                    .font(.largeTitle)
                    .bold()
                    .padding(.bottom, 20)
                
                // Email
                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(.gray)
                    TextField("Email", text: $email)
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        #endif
                        .disableAutocorrection(true)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                // Contraseña
                HStack {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.gray)
                    SecureField("Contraseña", text: $password)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                // Botón iniciar sesión
                Button(action: loginUser) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Iniciar Sesión")
                            .foregroundColor(.white)
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                }
                .disabled(email.isEmpty || password.isEmpty || isLoading)
                
                // Mensaje de error
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.top, 5)
                }
                
                Spacer()
                
                // Ir a registro
                HStack {
                    Text("¿No tienes cuenta?")
                    Button("Regístrate") {
                        // Aquí navegas a la vista de registro
                    }
                    .foregroundColor(.blue)
                }
                .font(.footnote)
            }
                // Hidden NavigationLink for programmatic navigation
                NavigationLink(destination: HomeView(), isActive: $navigateToHome) {
                    EmptyView()
                }
                .hidden()
            }
            .padding()
            .background(Color.white.ignoresSafeArea())
            #if os(iOS)
            .navigationBarHidden(true)
            #endif
        }

    
    private func loginUser() {
        isLoading = true
        errorMessage = ""
        
        // Simple local authentication
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isLoading = false
            
            // Check if user exists in local storage
            if let storedEmail = UserDefaults.standard.string(forKey: "userEmail"),
               let storedPassword = UserDefaults.standard.string(forKey: "userPassword") {
                
                if email == storedEmail && password == storedPassword {
                    // Login successful
                    UserDefaults.standard.set(true, forKey: "isUserLoggedIn")
                    UserDefaults.standard.set(email, forKey: "currentUserEmail")
                    navigateToHome = true
                } else {
                    errorMessage = "Email o contraseña incorrectos"
                }
            } else {
                // First time user, create account automatically
                UserDefaults.standard.set(email, forKey: "userEmail")
                UserDefaults.standard.set(password, forKey: "userPassword")
                UserDefaults.standard.set(true, forKey: "isUserLoggedIn")
                UserDefaults.standard.set(email, forKey: "currentUserEmail")
                UserDefaults.standard.set("demo_user", forKey: "currentUserId")
                
                // Create default user profile
                // Create basic profile - will be completed in onboarding
                
                navigateToHome = true
            }
        }
    }
}

struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        AuthView()
    }
}

