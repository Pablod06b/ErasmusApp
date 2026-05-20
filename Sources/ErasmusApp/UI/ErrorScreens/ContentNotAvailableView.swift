// ContentNotAvailableView.swift — el contenido (post, evento, usuario...) ya no existe o no es accesible
import SwiftUI

struct ContentNotAvailableView: View {
    enum Kind {
        case post
        case event
        case profile
        case conversation
        case generic

        var icon: String {
            switch self {
            case .post: return "doc.text.magnifyingglass"
            case .event: return "calendar.badge.exclamationmark"
            case .profile: return "person.crop.circle.badge.questionmark"
            case .conversation: return "message.badge.waveform"
            case .generic: return "questionmark.circle"
            }
        }

        var title: String {
            switch self {
            case .post: return "Publicación no disponible"
            case .event: return "Evento no disponible"
            case .profile: return "Perfil no disponible"
            case .conversation: return "Conversación no disponible"
            case .generic: return "Contenido no disponible"
            }
        }

        var message: String {
            switch self {
            case .post: return "Esta publicación ha sido eliminada por su autor o por moderación."
            case .event: return "Este evento ya no está disponible. Puede haber sido cancelado o borrado."
            case .profile: return "El perfil que intentas ver ya no está activo o te ha bloqueado."
            case .conversation: return "Esta conversación ya no está disponible."
            case .generic: return "Lo que intentas ver ya no está disponible."
            }
        }
    }

    let kind: Kind
    var onBack: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: kind.icon)
                .font(.system(size: 70, weight: .ultraLight))
                .foregroundColor(.gray.opacity(0.5))

            VStack(spacing: 8) {
                Text(kind.title)
                    .font(.title3).fontWeight(.bold)
                Text(kind.message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            if let onBack = onBack {
                Button(action: onBack) {
                    Label("Volver", systemImage: "chevron.left")
                        .font(.subheadline).fontWeight(.semibold)
                        .padding(.horizontal, 18).padding(.vertical, 10)
                        .background(Color(UIColor.secondarySystemBackground))
                        .clipShape(Capsule())
                }
                .foregroundColor(.primary)
                .padding(.top, 4)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(kind.title). \(kind.message)")
    }
}

#Preview("Post") { ContentNotAvailableView(kind: .post, onBack: {}) }
#Preview("Event") { ContentNotAvailableView(kind: .event, onBack: {}) }
#Preview("Profile") { ContentNotAvailableView(kind: .profile, onBack: {}) }
