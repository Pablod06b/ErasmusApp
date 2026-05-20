// NetworkMonitor.swift — detección de conexión a internet
import Foundation
import Network
import SwiftUI

/// Observa el estado de la red usando NWPathMonitor.
/// Se inicia al arrancar la app y actualiza `isConnected` y `connectionType`.
@MainActor
final class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()

    @Published var isConnected: Bool = true
    @Published var connectionType: ConnectionType = .unknown

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor.queue")
    private var started = false

    enum ConnectionType {
        case wifi, cellular, ethernet, unknown
        case none
    }

    private init() {}

    /// Llamar una vez al inicio de la app (en ContentView.onAppear o ErasmusApp.init).
    func start() {
        guard !started else { return }
        started = true

        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self else { return }
                let connected = path.status == .satisfied
                let type: ConnectionType = {
                    if path.status != .satisfied { return .none }
                    if path.usesInterfaceType(.wifi) { return .wifi }
                    if path.usesInterfaceType(.cellular) { return .cellular }
                    if path.usesInterfaceType(.wiredEthernet) { return .ethernet }
                    return .unknown
                }()

                // Si cambia el estado, dispara una pequeña notificación visual
                let wasConnected = self.isConnected
                self.isConnected = connected
                self.connectionType = type

                if wasConnected && !connected {
                    AppErrorManager.shared.report(
                        "Sin conexión a internet",
                        icon: "wifi.slash",
                        kind: .error,
                        duration: 6
                    )
                } else if !wasConnected && connected {
                    AppErrorManager.shared.success("Conexión recuperada", icon: "wifi")
                }
            }
        }
        monitor.start(queue: queue)
    }

    func stop() {
        monitor.cancel()
        started = false
    }
}

// MARK: - Banner persistente para mostrar arriba cuando estamos offline
struct OfflineBannerView: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash")
                .font(.caption).fontWeight(.bold)
            Text("Sin conexión — los cambios se guardarán cuando vuelvas")
                .font(.caption).fontWeight(.medium)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(Color.orange.opacity(0.95))
        .accessibilityLabel("Sin conexión a internet")
    }
}
