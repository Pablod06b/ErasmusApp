// PhoneAuthManager.swift — verificación SMS via Firebase Phone Auth
import Foundation
import FirebaseAuth

/// Encapsula el flujo de verificación por SMS con Firebase Phone Auth.
///
/// Uso:
/// 1. `sendCode(to:)` → envía SMS, devuelve verificationID o lanza error
/// 2. `verify(code:)` → confirma el código, devuelve `PhoneAuthCredential`
/// 3. Si ya hay un usuario logueado (caso típico tras signUpWithOnboarding),
///    llamar a `link(credential:)` para vincular el teléfono al usuario actual
/// 4. Si no hay usuario, llamar a `signIn(credential:)` para crear sesión solo con teléfono
@MainActor
final class PhoneAuthManager: ObservableObject {
    static let shared = PhoneAuthManager()

    @Published var isSending: Bool = false
    @Published var isVerifying: Bool = false
    @Published var verificationID: String? = nil

    private init() {}

    /// Envía SMS al número en formato internacional (ej. "+34612345678").
    @discardableResult
    func sendCode(to phoneNumber: String) async throws -> String {
        isSending = true
        defer { isSending = false }

        // En simulator iOS Firebase usa fakeWebsiteVerification por defecto;
        // en dispositivo real intenta SilentPushNotification primero y cae a reCAPTCHA.
        let id = try await PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil)
        verificationID = id
        return id
    }

    /// Construye la credencial con el código que metió el user.
    func makeCredential(code: String) -> PhoneAuthCredential? {
        guard let id = verificationID, code.count == 6 else { return nil }
        return PhoneAuthProvider.provider().credential(withVerificationID: id, verificationCode: code)
    }

    /// Vincula el teléfono al usuario logueado actual (caso típico tras signUpWithOnboarding).
    /// Lanza error si el código es inválido o el teléfono ya está vinculado a otra cuenta.
    func link(code: String) async throws {
        guard let credential = makeCredential(code: code) else {
            throw NSError(domain: "PhoneAuth", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Código inválido"])
        }
        guard let user = Auth.auth().currentUser else {
            throw NSError(domain: "PhoneAuth", code: -2,
                          userInfo: [NSLocalizedDescriptionKey: "No hay sesión activa para vincular"])
        }
        isVerifying = true
        defer { isVerifying = false }
        _ = try await user.link(with: credential)
    }

    /// Inicia sesión sólo con teléfono (no se usa en el flujo principal; útil si
    /// algún día añadimos login alternativo por SMS).
    func signIn(code: String) async throws -> AuthDataResult {
        guard let credential = makeCredential(code: code) else {
            throw NSError(domain: "PhoneAuth", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Código inválido"])
        }
        isVerifying = true
        defer { isVerifying = false }
        return try await Auth.auth().signIn(with: credential)
    }

    func reset() {
        verificationID = nil
    }
}
