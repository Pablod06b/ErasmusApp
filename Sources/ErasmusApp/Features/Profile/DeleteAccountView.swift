// DeleteAccountView.swift
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct DeleteAccountView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: FirebaseAuthManager

    @State private var password = ""
    @State private var confirmText = ""
    @State private var isProcessing = false
    @State private var errorMessage: String? = nil

    // URL del Cloud Function deleteUserData (2nd Gen — Cloud Run)
    private let deleteUserDataURL = URL(string: "https://deleteuserdata-7wqffoff5q-uc.a.run.app")!

    var canSubmit: Bool {
        !isProcessing &&
        password.count >= 6 &&
        confirmText.lowercased() == "eliminar"
    }

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Acción irreversible", systemImage: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.headline)
                    Text("Al eliminar tu cuenta se borrarán para siempre:")
                        .font(.subheadline)
                    bullet("Tu perfil, foto e información de Erasmus")
                    bullet("Todos tus posts, eventos y mensajes")
                    bullet("Tu historial de chats, grupos y reacciones")
                    Text("No podrás recuperar nada.")
                        .font(.subheadline).fontWeight(.semibold)
                        .padding(.top, 4)
                }
                .padding(.vertical, 4)
            }

            Section(header: Text("Contraseña actual"), footer: Text("Por seguridad confirma tu contraseña.")) {
                SecureField("Tu contraseña", text: $password)
            }

            Section(header: Text("Confirmación"), footer: Text("Escribe la palabra ELIMINAR para confirmar.")) {
                TextField("ELIMINAR", text: $confirmText)
                    .autocapitalization(.allCharacters)
                    .disableAutocorrection(true)
            }

            if let errorMessage = errorMessage {
                Section { Text(errorMessage).foregroundColor(.red).font(.footnote) }
            }

            Section {
                Button(role: .destructive, action: { Task { await submit() } }) {
                    HStack {
                        if isProcessing { ProgressView() }
                        Text("Eliminar mi cuenta para siempre")
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                }
                .disabled(!canSubmit)
            }
        }
        .navigationTitle("Eliminar cuenta")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func bullet(_ s: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text("•").foregroundColor(.red)
            Text(s).font(.subheadline)
        }
    }

    private func submit() async {
        guard let user = Auth.auth().currentUser, let email = user.email else { return }
        isProcessing = true
        defer { isProcessing = false }
        errorMessage = nil

        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        do {
            try await user.reauthenticate(with: credential)
            // 1. Pide a Cloud Functions (HTTP) que borre todos los datos del usuario
            let token = try await user.getIDToken()
            var req = URLRequest(url: deleteUserDataURL)
            req.httpMethod = "POST"
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = "{}".data(using: .utf8)
            let (_, response) = try await URLSession.shared.data(for: req)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                throw NSError(domain: "DeleteAccount", code: -1, userInfo: [NSLocalizedDescriptionKey: "Error en el servidor al borrar tus datos."])
            }
            // 2. Borra la cuenta de Auth en cliente
            try await user.delete()
            // 3. Limpiar sesión local
            try? Auth.auth().signOut()
            await MainActor.run {
                authManager.currentUser = nil
                authManager.isAuthenticated = false
            }
        } catch {
            errorMessage = friendlyError(error)
        }
    }

    private func friendlyError(_ error: Error) -> String {
        let code = (error as NSError).code
        switch code {
        case AuthErrorCode.wrongPassword.rawValue: return "Contraseña incorrecta."
        case AuthErrorCode.requiresRecentLogin.rawValue: return "Por seguridad necesitas iniciar sesión otra vez."
        default: return "No se pudo eliminar: \(error.localizedDescription)"
        }
    }
}
