// EmailChangeView.swift
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct EmailChangeView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: FirebaseAuthManager

    @State private var newEmail = ""
    @State private var currentPassword = ""
    @State private var isProcessing = false
    @State private var successMessage: String? = nil
    @State private var errorMessage: String? = nil

    var currentEmail: String {
        Auth.auth().currentUser?.email ?? "—"
    }

    var canSubmit: Bool {
        !isProcessing &&
        newEmail.contains("@") &&
        newEmail.contains(".") &&
        currentPassword.count >= 6 &&
        newEmail.lowercased() != currentEmail.lowercased()
    }

    var body: some View {
        Form {
            Section("Email actual") {
                Text(currentEmail).foregroundColor(.secondary)
            }
            Section("Nuevo email") {
                TextField("tu.nuevo@email.com", text: $newEmail)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            Section(header: Text("Contraseña actual"), footer: Text("Por seguridad necesitamos confirmar que eres tú. Después de cambiar el email recibirás un correo de verificación en tu nueva dirección.")) {
                SecureField("Tu contraseña", text: $currentPassword)
            }

            if let successMessage = successMessage {
                Section { Text(successMessage).foregroundColor(.green).font(.footnote) }
            }
            if let errorMessage = errorMessage {
                Section { Text(errorMessage).foregroundColor(.red).font(.footnote) }
            }

            Section {
                Button(action: { Task { await submit() } }) {
                    HStack {
                        if isProcessing { ProgressView() }
                        Text("Actualizar email").fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                }
                .disabled(!canSubmit)
            }
        }
        .navigationTitle("Cambiar email")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func submit() async {
        guard let user = Auth.auth().currentUser, let email = user.email else { return }
        isProcessing = true
        defer { isProcessing = false }
        errorMessage = nil
        successMessage = nil

        let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
        do {
            try await user.reauthenticate(with: credential)
            try await user.sendEmailVerification(beforeUpdatingEmail: newEmail)
            try await Firestore.firestore().collection("users").document(user.uid).updateData([
                "pendingEmail": newEmail
            ])
            successMessage = "Te hemos enviado un correo de verificación a \(newEmail). Pulsa el enlace para completar el cambio."
            currentPassword = ""
        } catch {
            errorMessage = friendlyError(error)
        }
    }

    private func friendlyError(_ error: Error) -> String {
        let code = (error as NSError).code
        switch code {
        case AuthErrorCode.wrongPassword.rawValue: return "Contraseña incorrecta."
        case AuthErrorCode.invalidEmail.rawValue: return "El nuevo email no es válido."
        case AuthErrorCode.emailAlreadyInUse.rawValue: return "Ya hay una cuenta con ese email."
        case AuthErrorCode.requiresRecentLogin.rawValue: return "Por seguridad necesitas iniciar sesión otra vez."
        default: return "No se pudo actualizar: \(error.localizedDescription)"
        }
    }
}
