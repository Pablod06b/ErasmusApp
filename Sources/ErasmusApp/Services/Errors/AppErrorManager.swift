// AppErrorManager.swift
import SwiftUI

/// Centraliza errores recuperables (red, Firestore, etc.) y los muestra
/// como banner sobre la UI. Cualquier manager puede llamar a `report`.
@MainActor
final class AppErrorManager: ObservableObject {
    static let shared = AppErrorManager()

    @Published var currentError: AppError? = nil

    private init() {}

    /// Llama desde un manager al detectar un fallo recuperable.
    /// Ejemplo: `AppErrorManager.shared.report("No se pudo cargar tu feed.", icon: "wifi.exclamationmark")`
    func report(_ message: String, icon: String = "exclamationmark.triangle.fill") {
        let err = AppError(message: message, icon: icon)
        withAnimation(.spring()) { currentError = err }
        // Auto-dismiss tras 4s
        Task {
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            if currentError?.id == err.id {
                withAnimation(.easeInOut) { currentError = nil }
            }
        }
    }

    func dismiss() {
        withAnimation(.easeInOut) { currentError = nil }
    }
}

struct AppError: Identifiable, Equatable {
    let id = UUID()
    let message: String
    let icon: String
}

// MARK: - Reusable banner view
struct AppErrorBannerView: View {
    let error: AppError
    var onDismiss: () -> Void = {}

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: error.icon)
                .font(.title3)
                .foregroundColor(.white)
            Text(error.message)
                .font(.subheadline).fontWeight(.medium)
                .foregroundColor(.white)
                .lineLimit(3)
            Spacer(minLength: 8)
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption).fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.85))
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(Color.red.opacity(0.92))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 4)
        .padding(.horizontal, 16)
    }
}
