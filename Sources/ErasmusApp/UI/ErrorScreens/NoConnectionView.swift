// NoConnectionView.swift — pantalla full screen sin conexión
import SwiftUI

struct NoConnectionView: View {
    var onRetry: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.orange.opacity(0.2), Color.red.opacity(0.15)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)
                Image(systemName: "wifi.slash")
                    .font(.system(size: 56, weight: .light))
                    .foregroundColor(.orange)
            }

            VStack(spacing: 10) {
                Text("Sin conexión a internet")
                    .font(.title2).fontWeight(.bold)
                Text("Comprueba tu Wi-Fi o datos móviles y vuelve a intentarlo. Tus cambios se guardarán automáticamente cuando vuelvas a estar online.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button(action: onRetry) {
                Label("Reintentar", systemImage: "arrow.clockwise")
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(14)
            }
            .padding(.horizontal, 40)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Sin conexión a internet. Pulsa Reintentar para volver a intentar.")
    }
}

#Preview {
    NoConnectionView(onRetry: {})
}
