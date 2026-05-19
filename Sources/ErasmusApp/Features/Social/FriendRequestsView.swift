// FriendRequestsView.swift
import SwiftUI

struct FriendRequestsView: View {
    @StateObject private var socialManager = SocialManager.shared
    @State private var actioningId: String? = nil

    var pendingRequests: [FriendRequest] {
        socialManager.friendRequests.filter { $0.status == .pending }
    }

    var body: some View {
        Group {
            if pendingRequests.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(pendingRequests) { request in
                        FriendRequestRow(
                            request: request,
                            isLoading: actioningId == request.id,
                            onAccept: { await accept(request) },
                            onReject: { await reject(request) }
                        )
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Solicitudes de amistad")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { socialManager.startListeningForRequests() }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.badge.plus")
                .font(.system(size: 56))
                .foregroundColor(.gray.opacity(0.5))
            Text("Sin solicitudes pendientes")
                .font(.headline)
            Text("Cuando alguien te envíe una solicitud de amistad aparecerá aquí.")
                .font(.subheadline).foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func accept(_ request: FriendRequest) async {
        actioningId = request.id
        try? await socialManager.acceptFriendRequest(requestId: request.id, fromUserId: request.fromUserId)
        actioningId = nil
    }

    private func reject(_ request: FriendRequest) async {
        actioningId = request.id
        try? await socialManager.rejectFriendRequest(requestId: request.id, fromUserId: request.fromUserId)
        actioningId = nil
    }
}

private struct FriendRequestRow: View {
    let request: FriendRequest
    let isLoading: Bool
    var onAccept: () async -> Void
    var onReject: () async -> Void

    var body: some View {
        HStack(spacing: 12) {
            UserAvatarView(photoURL: request.fromUserPhotoURL, name: request.fromUserName, size: 50)

            VStack(alignment: .leading, spacing: 3) {
                Text(request.fromUserName)
                    .font(.subheadline).fontWeight(.semibold)
                Text("Quiere ser tu amigo")
                    .font(.caption).foregroundColor(.secondary)
                Text(request.createdAt, style: .relative)
                    .font(.caption2).foregroundColor(.secondary.opacity(0.7))
            }
            Spacer(minLength: 4)
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                } else {
                    Button { Task { await onReject() } } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.red)
                            .frame(width: 34, height: 34)
                            .background(Color.red.opacity(0.12))
                            .clipShape(Circle())
                    }
                    Button { Task { await onAccept() } } label: {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 34, height: 34)
                            .background(
                                LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                            )
                            .clipShape(Circle())
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(14)
    }
}
