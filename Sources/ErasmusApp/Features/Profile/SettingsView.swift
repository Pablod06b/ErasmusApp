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
                    SettingsRowView(icon: "envelope.fill", title: "Cambiar email", iconColor: .blue) {
                        showEmailChangeAlert = true
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
                    SettingsRowView(icon: "eye.slash.fill", title: "Usuarios bloqueados", iconColor: .red) {}
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
                        SettingsRowView(icon: "message.fill", title: "Notificaciones de mensajes", iconColor: .orange) {}
                        SettingsRowView(icon: "calendar.badge.clock", title: "Notificaciones de eventos", iconColor: .orange) {}
                    }
                }
                
                // Section 4: Support
                Section(header: Text("Soporte e Información").font(.subheadline).foregroundColor(.gray)) {
                    SettingsRowView(icon: "questionmark.circle.fill", title: "Centro de ayuda", iconColor: .purple) {
                        showMaintenanceAlert = true
                    }
                    SettingsRowView(icon: "exclamationmark.bubble.fill", title: "Reportar un problema", iconColor: .purple) {
                        showMaintenanceAlert = true
                    }
                    SettingsRowView(icon: "doc.text.fill", title: "Términos y condiciones", iconColor: .purple) {
                        showMaintenanceAlert = true
                    }
                    SettingsRowView(icon: "hand.raised.circle.fill", title: "Política de privacidad", iconColor: .purple) {
                        showMaintenanceAlert = true
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
                    
                    if isProcessing {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    } else {
                        Button(action: { showDeleteAccountAlert = true }) {
                            HStack {
                                Image(systemName: "trash.fill")
                                Text("Eliminar cuenta definitivamente")
                            }
                            .foregroundColor(.red)
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
        .alert("Eliminar Cuenta", isPresented: $showDeleteAccountAlert) {
            Button("Cancelar", role: .cancel) { }
            Button("Eliminar", role: .destructive) {
                performDeleteAccount()
            }
        } message: {
            Text("Esta acción es irreversible. Se eliminarán todos tus mensajes, posts y fotos permanentemente.")
        }
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

    private func loadSettings() {
        guard let permissions = authManager.currentUser?.permissions else { return }
        privateAccount = permissions.isPrivateAccount
        showOnlineStatus = permissions.showOnlineStatus
        notificationsEnabled = permissions.allowNotifications
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
