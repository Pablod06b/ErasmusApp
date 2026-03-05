import SwiftUI

struct GroupChatView: View {
    let group: SocialGroup
    @ObservedObject var chatManager = ChatManager.shared
    @ObservedObject var groupManager = GroupManager.shared
    @EnvironmentObject var authManager: FirebaseAuthManager
    @State private var newMessageText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Messages list
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(chatManager.messages) { message in
                        let isFromCurrentUser = message.senderId == (authManager.currentUser?.id ?? "")
                        // Find sender profile
                        let senderProfile = groupManager.groupMembers.first { $0.id == message.senderId }
                        
                        HStack {
                            if isFromCurrentUser { Spacer(minLength: 50) }
                            
                            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 2) {
                                // Show sender name if not me
                                if !isFromCurrentUser {
                                    Text(senderProfile?.displayName ?? "Usuario")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.leading, 12)
                                }
                                
                                Text(message.content)
                                    .font(.body)
                                    .foregroundColor(isFromCurrentUser ? .white : .primary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 18)
                                            .fill(isFromCurrentUser ? 
                                                AnyShapeStyle(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)) :
                                                AnyShapeStyle(Color.gray.opacity(0.15))
                                            )
                                    )
                                
                                Text(message.timestamp, style: .time)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 4)
                            }
                            
                            if !isFromCurrentUser { Spacer(minLength: 50) }
                        }
                        .id(message.id)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .onAppear {
                chatManager.startListeningToMessages(groupId: group.id)
                // We ensure members are fetched so we can map names
                if groupManager.groupMembers.isEmpty {
                    Task { await groupManager.fetchMembers() }
                }
            }
            
            // Message input (Reused from ChatView if public or replicated)
            GroupMessageInputView(messageText: $newMessageText, onSend: sendMessage)
        }
    }
    
    private func sendMessage() {
        guard !newMessageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        chatManager.sendGroupMessage(groupId: group.id, content: newMessageText)
        newMessageText = ""
    }
}

// Replicated Input View to avoid scope issues if ChatView input is tight
struct GroupMessageInputView: View {
    @Binding var messageText: String
    let onSend: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            HStack {
                TextField("Mensaje al grupo...", text: $messageText, axis: .vertical)
                    .lineLimit(1...4)
                
                Button(action: {}) {
                    Image(systemName: "camera")
                    .foregroundColor(.blue)
                }
                
                Button(action: {}) {
                    Image(systemName: "photo")
                    .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.15))
            .cornerRadius(20)
            
            Button(action: onSend) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundColor(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .secondary : .blue)
            }
            .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.05))
    }
}
