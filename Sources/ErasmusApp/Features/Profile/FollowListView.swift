// FollowListView.swift — modal de seguidores / seguidos / amigos / publicaciones
import SwiftUI
import FirebaseFirestore

enum FollowListKind: String, Identifiable {
    case followers
    case following
    case friends
    case posts   // si lo pulsas en stats, hacer scroll a la sección de posts (no modal)

    var id: String { rawValue }

    var title: String {
        switch self {
        case .followers: return "Seguidores"
        case .following: return "Siguiendo"
        case .friends:   return "Amigos"
        case .posts:     return "Publicaciones"
        }
    }

    var icon: String {
        switch self {
        case .followers: return "person.2.fill"
        case .following: return "person.crop.circle.badge.checkmark"
        case .friends:   return "person.3.fill"
        case .posts:     return "newspaper.fill"
        }
    }
}

/// Modal estilo Instagram que muestra una lista de usuarios (seguidores/seguidos/amigos).
struct FollowListView: View {
    let kind: FollowListKind
    let userIds: [String]
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: FirebaseAuthManager

    @State private var profiles: [UserProfile] = []
    @State private var isLoading = true
    @State private var searchText = ""

    private var filtered: [UserProfile] {
        guard !searchText.isEmpty else { return profiles }
        return profiles.filter {
            $0.displayName.localizedCaseInsensitiveContains(searchText) ||
            $0.username.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    AppLoadingView(message: "Cargando...")
                } else if profiles.isEmpty {
                    AppEmptyView(
                        icon: kind.icon,
                        title: emptyTitle,
                        message: emptyMessage
                    )
                } else {
                    List {
                        ForEach(filtered) { profile in
                            NavigationLink(destination: UserProfileView(userToDisplay: profile.toExtendedUserProfile())
                                .environmentObject(authManager)) {
                                UserRowView(profile: profile)
                            }
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        }
                    }
                    .listStyle(.plain)
                    .searchable(text: $searchText, prompt: "Buscar")
                }
            }
            .navigationTitle(kind.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
            .task { await load() }
        }
    }

    private var emptyTitle: String {
        switch kind {
        case .followers: return "Sin seguidores"
        case .following: return "No sigue a nadie"
        case .friends:   return "Sin amigos"
        case .posts:     return "Sin publicaciones"
        }
    }

    private var emptyMessage: String {
        switch kind {
        case .followers: return "Cuando alguien le siga aparecerá aquí."
        case .following: return "Las personas a las que siga aparecerán aquí."
        case .friends:   return "Las amistades aparecerán aquí cuando alguien acepte la petición."
        case .posts:     return "Aún no ha publicado nada."
        }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }

        guard !userIds.isEmpty else { profiles = []; return }

        // Firestore "in" tiene límite de 30. Si hay más, hacemos batches.
        let db = Firestore.firestore()
        var loaded: [UserProfile] = []
        let chunks = userIds.chunked(into: 30)

        for chunk in chunks {
            do {
                let snap = try await db.collection("users")
                    .whereField(FieldPath.documentID(), in: chunk)
                    .getDocuments()
                let parsed = snap.documents.compactMap { try? $0.data(as: UserProfile.self) }
                loaded.append(contentsOf: parsed)
            } catch {
                print("Error fetching follow list: \(error)")
            }
        }

        profiles = loaded
    }
}

// MARK: - User Row
private struct UserRowView: View {
    let profile: UserProfile
    @EnvironmentObject var authManager: FirebaseAuthManager
    @StateObject private var socialManager = SocialManager.shared
    @State private var isFollowing = false

    var body: some View {
        HStack(spacing: 12) {
            UserAvatarView(
                photoURL: profile.photoURL.isEmpty ? nil : profile.photoURL,
                name: profile.displayName,
                size: 48
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(profile.displayName)
                    .font(.subheadline).fontWeight(.semibold)
                if !profile.username.isEmpty {
                    Text("@\(profile.username)")
                        .font(.caption).foregroundColor(.secondary)
                }
                if !profile.destination.isEmpty {
                    Label(profile.destination, systemImage: "location.fill")
                        .font(.caption2).foregroundColor(.secondary)
                }
            }

            Spacer()

            // Solo muestra el botón si no es mi propio perfil
            if profile.id != authManager.currentUser?.id {
                Button(action: toggleFollow) {
                    Text(isFollowing ? "Siguiendo" : "Seguir")
                        .font(.caption).fontWeight(.semibold)
                        .padding(.horizontal, 14).padding(.vertical, 6)
                        .background(isFollowing ? Color(UIColor.tertiarySystemBackground) : Color.blue)
                        .foregroundColor(isFollowing ? .primary : .white)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(isFollowing ? Color.gray.opacity(0.4) : Color.clear, lineWidth: 1)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            isFollowing = authManager.currentUser?.followingIds.contains(profile.id) ?? false
        }
    }

    private func toggleFollow() {
        let wasFollowing = isFollowing
        isFollowing.toggle()
        Task {
            do {
                if wasFollowing {
                    try await socialManager.unfollow(userId: profile.id)
                } else {
                    try await socialManager.follow(userId: profile.id)
                }
            } catch {
                isFollowing = wasFollowing // revert
            }
        }
    }
}

// `Array.chunked(into:)` ya está definido en otro archivo del proyecto.
