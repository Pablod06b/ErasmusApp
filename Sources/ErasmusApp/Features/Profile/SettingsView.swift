// SettingsView.swift
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: FirebaseAuthManager
    
    @State private var showLogoutAlert = false
    @State private var showDeleteAccountAlert = false
    @State private var showPauseAccountAlert = false
    @State private var isProcessing = false
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var showEditProfile = false
    @State private var showPasswordResetAlert = false
    @State private var showEmailChangeAlert = false
    @State private var showMaintenanceAlert = false

    // Settings state — loaded from Firebase on appear
    @State private var privateAccount = false
    @State private var showOnlineStatus = true
    @State private var notificationsEnabled = true
    @State private var messageNotifsEnabled = true
    @State private var eventNotifsEnabled = true

    var body: some View {
        NavigationView {
            Form {
                // Section 1: Account
                Section(header: Text("Cuenta").font(.subheadline).foregroundColor(.gray)) {
                    SettingsRowView(icon: "person.circle.fill", title: "Editar perfil", iconColor: .blue) {
                        showEditProfile = true
                    }
                    SettingsRowView(icon: "key.fill", title: "Cambiar contraseña", iconColor: .blue) {
                        showPasswordResetAlert = true
                    }
                    NavigationLink(destination: EmailChangeView().environmentObject(authManager)) {
                        settingsRow(icon: "envelope.fill", title: "Cambiar email", color: .blue)
                    }
                }

                // Section 2: Privacy
                Section(header: Text("Privacidad").font(.subheadline).foregroundColor(.gray)) {
                    Toggle(isOn: $privateAccount) {
                        HStack {
                            Image(systemName: "lock.shield.fill").foregroundColor(.green)
                            Text("Cuenta privada")
                        }
                    }
                    .onChange(of: privateAccount) { value in
                        Task { try? await authManager.updateUserProfile(data: ["permissions.isPrivateAccount": value]) }
                    }
                    Toggle(isOn: $showOnlineStatus) {
                        HStack {
                            Image(systemName: "record.circle.fill").foregroundColor(.green)
                            Text("Mostrar estado en línea")
                        }
                    }
                    .onChange(of: showOnlineStatus) { value in
                        Task { try? await authManager.updateUserProfile(data: ["permissions.showOnlineStatus": value]) }
                    }
                    NavigationLink(destination: BlockedUsersView()) {
                        HStack(spacing: 12) {
                            Image(systemName: "eye.slash.fill")
                                .foregroundColor(.red)
                                .frame(width: 24)
                                .font(.system(size: 18))
                            Text("Usuarios bloqueados")
                                .foregroundColor(.primary)
                            Spacer()
                        }
                    }
                }

                // Section 3: Notifications
                Section(header: Text("Notificaciones").font(.subheadline).foregroundColor(.gray)) {
                    Toggle(isOn: $notificationsEnabled) {
                        HStack {
                            Image(systemName: "bell.badge.fill").foregroundColor(.orange)
                            Text("Notificaciones")
                        }
                    }
                    .onChange(of: notificationsEnabled) { value in
                        Task { try? await authManager.updateUserProfile(data: ["permissions.allowNotifications": value]) }
                    }
                    if notificationsEnabled {
                        Toggle(isOn: $messageNotifsEnabled) {
                            HStack {
                                Image(systemName: "message.fill").foregroundColor(.orange)
                                Text("Notificaciones de mensajes")
                            }
                        }
                        .onChange(of: messageNotifsEnabled) { value in
                            Task { try? await authManager.updateUserProfile(data: ["permissions.allowMessageNotifications": value]) }
                        }
                        Toggle(isOn: $eventNotifsEnabled) {
                            HStack {
                                Image(systemName: "calendar.badge.clock").foregroundColor(.orange)
                                Text("Notificaciones de eventos")
                            }
                        }
                        .onChange(of: eventNotifsEnabled) { value in
                            Task { try? await authManager.updateUserProfile(data: ["permissions.allowEventNotifications": value]) }
                        }
                    }
                }
                
                // Section 4: Support
                Section(header: Text("Soporte e Información").font(.subheadline).foregroundColor(.gray)) {
                    NavigationLink(destination: HelpCenterView()) {
                        settingsRow(icon: "questionmark.circle.fill", title: "Centro de ayuda", color: .purple)
                    }
                    NavigationLink(destination: BugReportView()) {
                        settingsRow(icon: "exclamationmark.bubble.fill", title: "Reportar un problema", color: .purple)
                    }
                    NavigationLink(destination: TermsView()) {
                        settingsRow(icon: "doc.text.fill", title: "Términos y condiciones", color: .purple)
                    }
                    NavigationLink(destination: PrivacyPolicyView()) {
                        settingsRow(icon: "hand.raised.circle.fill", title: "Política de privacidad", color: .purple)
                    }
                }
                
                // Section 5: Danger Zone
                Section {
                    Button(action: { showPauseAccountAlert = true }) {
                        HStack {
                            Image(systemName: "pause.circle.fill")
                            Text("Pausar cuenta temporalmente")
                        }
                        .foregroundColor(.orange)
                    }
                    
                    Button(action: { showLogoutAlert = true }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right.fill")
                            Text("Cerrar sesión")
                        }
                        .foregroundColor(.red)
                    }
                    
                    NavigationLink(destination: DeleteAccountView().environmentObject(authManager)) {
                        HStack {
                            Image(systemName: "trash.fill")
                                .foregroundColor(.red)
                            Text("Eliminar cuenta definitivamente")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Ajustes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
        .alert("Cerrar Sesión", isPresented: $showLogoutAlert) {
            Button("Cancelar", role: .cancel) { }
            Button("Cerrar Sesión", role: .destructive) {
                performLogout()
            }
        } message: {
            Text("¿Estás seguro de que quieres cerrar tu sesión actual?")
        }
        // Antiguo alert eliminado — ahora se usa DeleteAccountView (flujo completo con reauth + CF).
        .alert("Pausar Cuenta", isPresented: $showPauseAccountAlert) {
            Button("Cancelar", role: .cancel) { }
            Button("Pausar", role: .destructive) {
                performPauseAccount()
            }
        } message: {
            Text("Tu cuenta será pausada. Tu perfil y posts dejarán de ser visibles hasta que vuelvas a intentar iniciar sesión.")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .alert("Cambiar Email", isPresented: $showEmailChangeAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Para cambiar tu correo electrónico, por seguridad debes contactar con nuestro soporte.")
        }
        .alert("Próximamente", isPresented: $showMaintenanceAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Esta sección estará disponible en la próxima actualización.")
        }
        .alert("Restablecer Contraseña", isPresented: $showPasswordResetAlert) {
            Button("Cancelar", role: .cancel) { }
            Button("Enviar Enlace") {
                sendPasswordReset()
            }
        } message: {
            Text("Te enviaremos un correo electrónico a \(authManager.currentUser?.email ?? "tu email") para restablecer tu contraseña.")
        }
        .onAppear { loadSettings() }
        .sheet(isPresented: $showEditProfile) {
            EditProfileView(user: authManager.currentUser?.toExtendedUserProfile() ?? ExtendedUserProfile.sampleUser)
                .environmentObject(authManager)
        }
    }

    /// Fila visual para usar dentro de un NavigationLink (sin botón propio)
    private func settingsRow(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
                .font(.system(size: 18))
            Text(title)
                .foregroundColor(.primary)
            Spacer()
        }
    }

    private func loadSettings() {
        guard let permissions = authManager.currentUser?.permissions else { return }
        privateAccount = permissions.isPrivateAccount
        showOnlineStatus = permissions.showOnlineStatus
        notificationsEnabled = permissions.allowNotifications
        messageNotifsEnabled = permissions.allowMessageNotifications ?? true
        eventNotifsEnabled = permissions.allowEventNotifications ?? true
    }
    
    private func sendPasswordReset() {
        guard let email = authManager.currentUser?.email else { return }
        Task {
            do {
                try await authManager.resetPassword(email: email)
                await MainActor.run {
                    errorMessage = "Enlace enviado. Revisa tu bandeja de entrada."
                    showError = true // Reusing the visual alert to show success message
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Error al enviar: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
    
    // MARK: - Handlers
    private func performLogout() {
        do {
            try authManager.signOut()
            GroupManager.shared.reset()
            dismiss()
        } catch {
            errorMessage = "No se pudo cerrar sesión: \(error.localizedDescription)"
            showError = true
        }
    }
    
    private func performDeleteAccount() {
        isProcessing = true
        Task {
            do {
                try await authManager.deleteAccount()
                await MainActor.run {
                    isProcessing = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    errorMessage = "Error al eliminar la cuenta: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
    
    private func performPauseAccount() {
        // En un futuro cambiaríamos un flag en el documento del usuario en Firestore a `isPaused = true`
        // Por ahora simulamos la pausa cerrando la sesión de manera segura.
        performLogout()
    }
}

// MARK: - Row Component
struct SettingsRowView: View {
    let icon: String
    let title: String
    let iconColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .frame(width: 24)
                    .font(.system(size: 18))
                
                Text(title)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray.opacity(0.5))
                    .font(.system(size: 14))
            }
        }
    }
}
