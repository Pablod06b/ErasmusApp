import SwiftUI

struct NotificationsView: View {
    @StateObject private var manager = NotificationManager.shared
    @StateObject private var socialManager = SocialManager.shared
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Group {
                if manager.notifications.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 48))
                            .foregroundColor(.gray.opacity(0.4))
                        Text("Sin notificaciones")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Aquí aparecerán tus notificaciones cuando lleguen")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(manager.notifications) { notification in
                            NotificationRow(
                                notification: notification,
                                socialManager: socialManager,
                                notificationManager: manager
                            )
                            .listRowSeparator(.hidden)
                            .listRowBackground(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(notification.isRead
                                          ? Color(UIColor.systemBackground)
                                          : Color.blue.opacity(0.05))
                                    .padding(.vertical, 2)
                            )
                            .onTapGesture {
                                if let id = notification.id {
                                    manager.markAsRead(notificationId: id)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Notificaciones")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    let unread = manager.notifications.filter { !$0.isRead }
                    if !unread.isEmpty {
                        Button("Marcar todo") { manager.markAllAsRead() }
                            .font(.subheadline)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Hecho") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .onAppear { manager.startListening() }
    }
}

// MARK: - Notification Row
struct NotificationRow: View {
    let notification: AppNotification
    let socialManager: SocialManager
    let notificationManager: NotificationManager

    @State private var friendRequestHandled = false
    @State private var isProcessing = false

    var body: some View {
        HStack(spacing: 14) {
            // Icon circle
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: notification.type.rawValue)
                    .font(.title3)
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(notification.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                    if !notification.isRead {
                        Circle().fill(Color.blue).frame(width: 8, height: 8)
                    }
                }

                Text(notification.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                Text(notification.date.formatted(.relative(presentation: .named)))
                    .font(.caption2)
                    .foregroundColor(.gray)

                // Friend Request Actions
                if notification.type == .friendRequest && !friendRequestHandled {
                    HStack(spacing: 10) {
                        Button(action: acceptFriendRequest) {
                            HStack(spacing: 4) {
                                if isProcessing {
                                    ProgressView().scaleEffect(0.7)
                                } else {
                                    Image(systemName: "checkmark").font(.caption)
                                }
                                Text("Aceptar")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(Color.blue)
                            .cornerRadius(20)
                        }
                        .disabled(isProcessing)

                        Button(action: rejectFriendRequest) {
                            Text("Rechazar")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(Color(UIColor.systemGray5))
                                .cornerRadius(20)
                        }
                        .disabled(isProcessing)
                    }
                    .padding(.top, 4)
                } else if notification.type == .friendRequest && friendRequestHandled {
                    Text("Solicitud gestionada ✓")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 4)
    }

    private var iconColor: Color {
        switch notification.type {
        case .friendRequest: return .blue
        case .friendAccepted: return .green
        case .newFollower: return .purple
        case .message: return .teal
        case .like: return .red
        case .comment: return .orange
        case .newEvent, .eventReminder: return .purple
        case .planJoin, .planInvite: return .green
        case .groupInvite: return .indigo
        case .recommendation: return .orange
        case .housing: return .teal
        case .system: return .gray
        }
    }

    private func acceptFriendRequest() {
        guard let fromUserId = notification.fromUserId,
              let requestId = notification.relatedItemId ?? notification.id else { return }
        isProcessing = true
        Task {
            do {
                try await socialManager.acceptFriendRequest(requestId: requestId, fromUserId: fromUserId)
                friendRequestHandled = true
                if let id = notification.id { notificationManager.markAsRead(notificationId: id) }
            } catch { print("Accept error: \(error)") }
            isProcessing = false
        }
    }

    private func rejectFriendRequest() {
        guard let fromUserId = notification.fromUserId,
              let requestId = notification.relatedItemId ?? notification.id else { return }
        isProcessing = true
        Task {
            do {
                try await socialManager.rejectFriendRequest(requestId: requestId, fromUserId: fromUserId)
                friendRequestHandled = true
                if let id = notification.id { notificationManager.markAsRead(notificationId: id) }
            } catch { print("Reject error: \(error)") }
            isProcessing = false
        }
    }
}
