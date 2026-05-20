// AppErrorManager.swift
import SwiftUI

enum AppMessageKind {
    case error      // rojo
    case info       // azul
    case success    // verde

    var color: Color {
        switch self {
        case .error: return .red
        case .info: return .blue
        case .success: return .green
        }
    }
}

/// Centraliza mensajes recuperables (errores, info, éxito) y los muestra
/// como banner sobre la UI. Cualquier manager puede llamar a `report`.
@MainActor
final class AppErrorManager: ObservableObject {
    static let shared = AppErrorManager()

    @Published var currentError: AppError? = nil

    private init() {}

    /// Reporta un mensaje a la UI. Por defecto es de tipo error (rojo).
    /// - icon: nombre de SF Symbol que se muestra a la izquierda
    /// - kind: error (rojo), info (azul) o success (verde)
    /// - duration: segundos antes de auto-cerrarse
    func report(
        _ message: String,
        icon: String = "exclamationmark.triangle.fill",
        kind: AppMessageKind = .error,
        duration: TimeInterval = 4
    ) {
        let err = AppError(message: message, icon: icon, kind: kind)
        withAnimation(.spring()) { currentError = err }
        Task {
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            if currentError?.id == err.id {
                withAnimation(.easeInOut) { currentError = nil }
            }
        }
    }

    /// Atajo para mensajes positivos (verde, 2s).
    func success(_ message: String, icon: String = "checkmark.circle.fill") {
        report(message, icon: icon, kind: .success, duration: 2)
    }

    /// Atajo para info (azul, 2s).
    func info(_ message: String, icon: String = "info.circle.fill") {
        report(message, icon: icon, kind: .info, duration: 2)
    }

    func dismiss() {
        withAnimation(.easeInOut) { currentError = nil }
    }
}

struct AppError: Identifiable, Equatable {
    let id = UUID()
    let message: String
    let icon: String
    let kind: AppMessageKind

    static func == (lhs: AppError, rhs: AppError) -> Bool { lhs.id == rhs.id }
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
            .accessibilityLabel("Cerrar mensaje")
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(error.kind.color.opacity(0.92))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 4)
        .padding(.horizontal, 16)
    }
}
