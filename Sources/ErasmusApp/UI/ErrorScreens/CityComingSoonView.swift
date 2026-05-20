// CityComingSoonView.swift — modal "Próximamente" cuando el user elige una ciudad no activa
import SwiftUI

struct CityComingSoonView: View {
    let city: AppCity
    @StateObject private var cityRequest = CityRequestManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var isWorking = false

    private var isSubscribed: Bool { cityRequest.hasRequested(city.name) }
    private var demandCount: Int { cityRequest.counts[city.name] ?? 0 }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Bandera enorme + ciudad
            VStack(spacing: 10) {
                Text(city.flag)
                    .font(.system(size: 80))
                Text(city.name)
                    .font(.largeTitle).fontWeight(.bold)
                Text(city.country)
                    .font(.subheadline).foregroundColor(.secondary)
            }

            // Mensaje principal
            VStack(spacing: 10) {
                Text("Próximamente en \(city.name)")
                    .font(.title3).fontWeight(.semibold)
                Text("Aún no hemos lanzado ErasmusConnect aquí. Apúntate y serás de los primeros en saberlo cuando llegue.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
            }

            // Contador de demanda
            if demandCount > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "person.2.fill")
                        .foregroundColor(.blue)
                    Text(demandCount == 1
                         ? "1 persona ya está esperando"
                         : "\(demandCount) personas ya están esperando")
                        .font(.subheadline).fontWeight(.medium)
                }
                .padding(.horizontal, 16).padding(.vertical, 8)
                .background(Color.blue.opacity(0.12))
                .clipShape(Capsule())
            }

            Spacer()

            // CTA principal
            VStack(spacing: 10) {
                Button(action: toggleSubscription) {
                    HStack {
                        if isWorking {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: isSubscribed ? "checkmark.circle.fill" : "bell.badge.fill")
                        }
                        Text(isSubscribed ? "Te avisaremos cuando llegue" : "Avísame cuando llegue")
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: isSubscribed ? [.green, .teal] : [.blue, .purple],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .cornerRadius(14)
                }
                .disabled(isWorking)

                Button("Cerrar") { dismiss() }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
        .task { await cityRequest.loadUserSubscriptions() }
    }

    private func toggleSubscription() {
        isWorking = true
        Task {
            if isSubscribed {
                _ = await cityRequest.unsubscribe(fromCity: city.name)
            } else {
                _ = await cityRequest.subscribe(toCity: city.name)
            }
            isWorking = false
        }
    }
}

#Preview {
    CityComingSoonView(city: AvailableCities.comingSoon[0])
}
