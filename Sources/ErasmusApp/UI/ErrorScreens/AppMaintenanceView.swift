// AppMaintenanceView.swift — vista de mantenimiento programado (kill switch)
import SwiftUI

/// Pantalla de mantenimiento. La lógica para activarla desde Firestore vendría
/// de leer `appConfig/global.maintenanceMode == true` en remoto.
struct AppMaintenanceView: View {
    let message: String
    let estimatedReturn: String?

    init(
        message: String = "Estamos haciendo mejoras en la app. Volveremos en breve.",
        estimatedReturn: String? = nil
    ) {
        self.message = message
        self.estimatedReturn = estimatedReturn
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.15)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)
                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(.blue)
            }

            VStack(spacing: 10) {
                Text("Volvemos enseguida")
                    .font(.title2).fontWeight(.bold)
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                if let estimated = estimatedReturn {
                    Label(estimated, systemImage: "clock.fill")
                        .font(.caption).foregroundColor(.blue)
                        .padding(.top, 4)
                }
            }

            Spacer()

            VStack(spacing: 4) {
                Text("¿Necesitas ayuda?")
                    .font(.caption).foregroundColor(.secondary)
                Link("soporte@erasmusconnect.app", destination: URL(string: "mailto:soporte@erasmusconnect.app")!)
                    .font(.caption).foregroundColor(.blue)
            }
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("App en mantenimiento. \(message)")
    }
}

/// Pantalla cuando la cuenta del usuario ha sido suspendida por moderación.
struct AccountSuspendedView: View {
    var onContactSupport: () -> Void = {}
    var onSignOut: () -> Void = {}

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "exclamationmark.shield.fill")
                .font(.system(size: 64, weight: .light))
                .foregroundColor(.red)
                .padding(28)
                .background(Color.red.opacity(0.12))
                .clipShape(Circle())

            VStack(spacing: 10) {
                Text("Cuenta suspendida")
                    .font(.title2).fontWeight(.bold)
                Text("Tu cuenta ha sido suspendida por incumplir las normas de la comunidad. Si crees que es un error, contacta con nosotros.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            VStack(spacing: 10) {
                Button(action: onContactSupport) {
                    Label("Contactar con soporte", systemImage: "envelope.fill")
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(Color.blue).foregroundColor(.white)
                        .cornerRadius(12)
                }
                Button(action: onSignOut) {
                    Text("Cerrar sesión")
                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                        .background(Color(UIColor.secondarySystemBackground))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Cuenta suspendida")
    }
}

#Preview("Maintenance") { AppMaintenanceView(estimatedReturn: "Volvemos a las 18:00") }
#Preview("Suspended") { AccountSuspendedView() }
