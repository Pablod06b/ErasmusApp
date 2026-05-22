// VerifyEmailBanner.swift — banner que aparece si el email del usuario no está verificado
import SwiftUI

struct VerifyEmailBanner: View {
    @EnvironmentObject var authManager: FirebaseAuthManager
    @State private var isSending = false
    @State private var lastSentAt: Date? = nil
    @State private var checkingVerification = false

    private var canResend: Bool {
        guard let last = lastSentAt else { return true }
        return Date().timeIntervalSince(last) > 60
    }

    var body: some View {
        if authManager.isAuthenticated && !authManager.isEmailVerified {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Image(systemName: "envelope.badge.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 38, height: 38)
                        .background(Color.orange)
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Verifica tu email")
                            .font(.subheadline).fontWeight(.bold)
                        Text("Te lo enviamos al registrarte. Revisa tu bandeja (y spam).")
                            .font(.caption).foregroundColor(.secondary)
                            .lineLimit(2)
                    }

                    Spacer(minLength: 6)

                    HStack(spacing: 6) {
                        Button(action: { Task { await checkVerification() } }) {
                            if checkingVerification {
                                ProgressView().scaleEffect(0.7)
                            } else {
                                Text("Ya lo hice")
                                    .font(.caption2).fontWeight(.semibold)
                            }
                        }
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(Color.blue.opacity(0.15))
                        .foregroundColor(.blue)
                        .clipShape(Capsule())
                        .disabled(checkingVerification)

                        Button(action: { Task { await resend() } }) {
                            if isSending {
                                ProgressView().scaleEffect(0.7)
                            } else {
                                Text(canResend ? "Reenviar" : "Espera")
                                    .font(.caption2).fontWeight(.semibold)
                            }
                        }
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(Color.orange.opacity(0.15))
                        .foregroundColor(.orange)
                        .clipShape(Capsule())
                        .disabled(!canResend || isSending)
                    }
                }
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .overlay(
                    Rectangle()
                        .fill(LinearGradient(colors: [.orange, .red], startPoint: .leading, endPoint: .trailing))
                        .frame(height: 2)
                        .frame(maxWidth: .infinity, alignment: .top), alignment: .top
                )
            }
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    private func resend() async {
        guard canResend else { return }
        isSending = true
        defer { isSending = false }
        do {
            try await authManager.sendEmailVerification()
            lastSentAt = Date()
            AppErrorManager.shared.success("Email enviado", icon: "envelope.fill")
        } catch {
            AppErrorManager.shared.report("No se pudo enviar. Inténtalo de nuevo.")
        }
    }

    private func checkVerification() async {
        checkingVerification = true
        defer { checkingVerification = false }
        let verified = await authManager.refreshEmailVerification()
        if verified {
            AppErrorManager.shared.success("Email verificado", icon: "checkmark.seal.fill")
        } else {
            AppErrorManager.shared.report("Aún no detectamos la verificación. Asegúrate de haber pulsado el enlace.", icon: "envelope.badge.fill")
        }
    }
}
