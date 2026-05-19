// BlockedUsersView.swift
import SwiftUI

struct BlockedUsersView: View {
    @StateObject private var socialManager = SocialManager.shared
    @State private var blockedProfiles: [UserProfile] = []
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Cargando usuarios bloqueados...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if blockedProfiles.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(blockedProfiles) { profile in
                        HStack(spacing: 12) {
                            UserAvatarView(
                                photoURL: profile.photoURL.isEmpty ? nil : profile.photoURL,
                                name: profile.displayName,
                                size: 44
                            )
                            VStack(alignment: .leading, spacing: 2) {
                                Text(profile.displayName)
                                    .font(.subheadline).fontWeight(.semibold)
                                if !profile.username.isEmpty {
                                    Text("@\(profile.username)")
                                        .font(.caption).foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            Button("Desbloquear") {
                                Task { await unblock(profile.id) }
                            }
                            .font(.caption).fontWeight(.semibold)
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(Color.red.opacity(0.12))
                            .foregroundColor(.red)
                            .clipShape(Capsule())
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Usuarios bloqueados")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadBlocked() }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.badge.checkmark")
                .font(.system(size: 56))
                .foregroundColor(.green.opacity(0.6))
            Text("No tienes a nadie bloqueado")
                .font(.headline)
            Text("Cuando bloquees a alguien aparecerá aquí. Puedes desbloquearlo en cualquier momento.")
                .font(.subheadline).foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func loadBlocked() async {
        isLoading = true
        await socialManager.loadBlockedUsers()
        blockedProfiles = await socialManager.fetchBlockedProfiles()
        isLoading = false
    }

    private func unblock(_ userId: String) async {
        try? await socialManager.unblock(userId: userId)
        blockedProfiles.removeAll { $0.id == userId }
    }
}
