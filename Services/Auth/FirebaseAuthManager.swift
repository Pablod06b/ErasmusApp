import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseCore
import GoogleSignIn

// MARK: - Firebase Authentication Manager
@MainActor
class FirebaseAuthManager: ObservableObject {
    @Published var currentUser: UserProfile?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var authError: AuthError?
    
    private let db = Firestore.firestore()
    
    init() {
        // Listen to Auth state changes
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            if let user = user {
                Task {
                    await self.fetchUserProfile(uid: user.uid)
                }
            } else {
                self.currentUser = nil
                self.isAuthenticated = false
                GroupManager.shared.reset()
            }
        }
    }
    
    // MARK: - Sign In
    func signIn(email: String, password: String) async throws {
        isLoading = true
        authError = nil
        
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            await fetchUserProfile(uid: result.user.uid)
            AppAnalytics.logLogin(method: "email")
            isLoading = false
        } catch {
            isLoading = false
            throw mapFirebaseError(error)
        }
    }

    // MARK: - Sign Up
    func signUp(email: String, password: String, displayName: String) async throws {
        isLoading = true
        authError = nil
        
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            
            // Create user profile in Firestore
            let newUser = UserProfile(
                id: result.user.uid,
                email: email,
                displayName: displayName,
                username: email.components(separatedBy: "@").first ?? "user",
                createdAt: Date(),
                lastLogin: Date(),
                interests: [],
                destination: "", // To be set later
                photoURL: "",
                onboardingCompleted: false
            )
            
            try await saveUserProfile(newUser)
            self.currentUser = newUser
            self.isAuthenticated = true
            AppAnalytics.logSignUp(method: "email")
            isLoading = false

        } catch {
            isLoading = false
            throw mapFirebaseError(error)
        }
    }

    // MARK: - Complete Sign Up with Onboarding Data
    func signUpWithOnboarding(
        email: String,
        password: String,
        displayName: String,
        username: String,
        university: String,
        career: String,
        erasmusStatus: String,
        destination: String,
        languages: [LanguageLevel],
        interests: [String],
        groupCode: String?,
        groupType: String?,
        permissions: UserPermissions
    ) async throws {
        isLoading = true
        authError = nil
        
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            
            let newUser = UserProfile(
                id: result.user.uid,
                email: email,
                displayName: displayName,
                username: username,
                createdAt: Date(),
                lastLogin: Date(),
                interests: interests,
                destination: destination,
                photoURL: "",
                onboardingCompleted: true,
                university: university,
                career: career,
                erasmusStatus: erasmusStatus,
                languages: languages,
                groupCode: groupCode,
                groupType: groupType,
                permissions: permissions
            )
            
            try await saveUserProfile(newUser)
            self.currentUser = newUser
            self.isAuthenticated = true
            AppAnalytics.logSignUp(method: "email")
            AppAnalytics.logOnboardingCompleted()
            AppAnalytics.setUserProperties(destination: destination, accountType: "student")

            // Handle Group Logic
            if let type = groupType, let code = groupCode, !code.isEmpty {
                if type == "crear" {
                    _ = await GroupManager.shared.createGroup(name: "Mi Grupo Erasmus", code: code)
                } else if type == "unirse" {
                    _ = await GroupManager.shared.joinGroup(code: code)
                }
            }
            
            isLoading = false
            
        } catch {
            isLoading = false
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Sign Out
    func signOut() throws {
        do {
            try Auth.auth().signOut()
            self.currentUser = nil
            self.isAuthenticated = false
        } catch {
            throw AuthError.unknownError("Error al cerrar sesión")
        }
    }
    
    
    // MARK: - Google Sign In
    func signInWithGoogle(idToken: String, accessToken: String) async throws {
        isLoading = true
        authError = nil
        
        do {
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
            let result = try await Auth.auth().signIn(with: credential)
            
            // Check if user exists in Firestore
            let document = try await db.collection("users").document(result.user.uid).getDocument()
            
            if !document.exists {
                // New user - create profile
                let email = result.user.email ?? ""
                let name = result.user.displayName ?? email.components(separatedBy: "@").first ?? "user"
                
                let newUser = UserProfile(
                    id: result.user.uid,
                    email: email,
                    displayName: name,
                    username: email.components(separatedBy: "@").first ?? "user",
                    createdAt: Date(),
                    lastLogin: Date(),
                    interests: [],
                    destination: "",
                    photoURL: result.user.photoURL?.absoluteString ?? "",
                    onboardingCompleted: false
                )
                try await saveUserProfile(newUser)
            }
            
            await fetchUserProfile(uid: result.user.uid)
            self.isAuthenticated = true
            if !document.exists {
                AppAnalytics.logSignUp(method: "google")
            } else {
                AppAnalytics.logLogin(method: "google")
            }
            isLoading = false
        } catch {
            isLoading = false
            throw mapFirebaseError(error)
        }
    }

    // MARK: - Password Reset
    func resetPassword(email: String) async throws {
        isLoading = true
        authError = nil
        
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
            isLoading = false
        } catch {
            isLoading = false
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Delete Account
    func deleteAccount() async throws {
        guard let firebaseUser = Auth.auth().currentUser else { return }
        isLoading = true
        authError = nil
        do {
            try await db.collection("users").document(firebaseUser.uid).delete()
            try await firebaseUser.delete()
            self.isAuthenticated = false
            self.currentUser = nil
            isLoading = false
        } catch {
            isLoading = false
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Firestore Operations
    private func saveUserProfile(_ user: UserProfile) async throws {
        let data = try Firestore.Encoder().encode(user)
        try await db.collection("users").document(user.id).setData(data)
    }
    
    private func fetchUserProfile(uid: String) async {
        do {
            let document = try await db.collection("users").document(uid).getDocument()
            if document.exists {
                self.currentUser = try document.data(as: UserProfile.self)
                self.isAuthenticated = true
                // Sincroniza set de bloqueados para filtros instantáneos
                await SocialManager.shared.loadBlockedUsers()
            } else {
                // User exists in Auth but not in Firestore (rare edge case)
                self.isAuthenticated = false
                self.currentUser = nil
            }
        } catch {
            print("Error fetching user profile: \(error)")
            self.authError = .unknownError("Error cargando perfil")
        }
    }
    
    func updateUserProfile(data: [String: Any]) async throws {
        guard let uid = currentUser?.id else { return }
        
        do {
            try await db.collection("users").document(uid).updateData(data)
            // Refresh local user
            await fetchUserProfile(uid: uid)
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    func getUserProfile() async throws -> UserProfile? {
        // If we want fresh data
        if let uid = currentUser?.id {
            await fetchUserProfile(uid: uid)
        }
        return currentUser
    }
    
    // MARK: - Error Mapping
    private func mapFirebaseError(_ error: Error) -> AuthError {
        let nsError = error as NSError
        switch nsError.code {
        case AuthErrorCode.invalidEmail.rawValue:
            return .invalidEmail
        case AuthErrorCode.wrongPassword.rawValue:
            return .wrongPassword
        case AuthErrorCode.userNotFound.rawValue:
            return .userNotFound
        case AuthErrorCode.emailAlreadyInUse.rawValue:
            return .emailAlreadyInUse
        case AuthErrorCode.weakPassword.rawValue:
            return .weakPassword
        case AuthErrorCode.networkError.rawValue:
            return .networkError
        default:
            return .unknownError(error.localizedDescription)
        }
    }
}

// MARK: - Auth Error Types
enum AuthError: LocalizedError, Identifiable {
    case invalidEmail
    case weakPassword
    case emailAlreadyInUse
    case userNotFound
    case wrongPassword
    case networkError
    case unknownError(String)
    
    var id: String { localizedDescription }
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "El formato del email no es válido"
        case .weakPassword:
            return "La contraseña debe tener al menos 6 caracteres"
        case .emailAlreadyInUse:
            return "Este email ya está registrado"
        case .userNotFound:
            return "Usuario no encontrado"
        case .wrongPassword:
            return "Contraseña incorrecta"
        case .networkError:
            return "Error de conexión. Verifica tu internet"
        case .unknownError(let message):
            return message
        }
    }
}

// MARK: - Google Sign In Helper (Moved to GoogleSignInHelper.swift)
