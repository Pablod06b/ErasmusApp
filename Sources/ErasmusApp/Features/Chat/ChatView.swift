// ChatView.swift
import SwiftUI

struct ChatView: View {
    @ObservedObject var chatManager = ChatManager.shared
    @State private var showNewChatSheet = false
    @State private var searchText = ""
    
    var filteredConversations: [Conversation] {
        if searchText.isEmpty {
            return chatManager.conversations
        } else {
            return chatManager.conversations.filter { 
                $0.otherUser?.name.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Buscar conversas...", text: $searchText)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.15))
                .cornerRadius(10)
                
                Button(action: { showNewChatSheet = true }) {
                    Image(systemName: "square.and.pencil")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            
            // Conversations list
            if filteredConversations.isEmpty {
                EmptyChatsView()
            } else {
                List(filteredConversations) { conversation in
                    NavigationLink(destination: ChatDetailView(conversation: conversation)) {
                        ConversationRowView(conversation: conversation)
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
                .listStyle(PlainListStyle())
            }
            
            Spacer()
        }
        .navigationTitle("")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .sheet(isPresented: $showNewChatSheet) {
            NewChatView()
        }
        .onAppear {
            chatManager.startListeningToConversations()
        }
    }
}

// MARK: - Conversation Row View
struct ConversationRowView: View {
    let conversation: Conversation
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile image
            if let user = conversation.otherUser {
                AsyncImage(url: URL(string: "https://picsum.photos/300/300?random=\(user.id)")) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Circle()
                        .fill(LinearGradient(colors: [.blue.opacity(0.3), .purple.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.8))
                        )
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(conversation.otherUser?.name ?? "Usuario")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Text(conversation.lastMessageTime, style: .time)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text(conversation.lastMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                        
                        Spacer()
                        
                        if conversation.unreadCount > 0 {
                            Text("\(conversation.unreadCount)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(minWidth: 20, minHeight: 20)
                                .background(Color.blue)
                                .clipShape(Circle())
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Empty Chats View
struct EmptyChatsView: View {
    var body: some View {
        VStack(spacing: 20) {
            EmptyStateView(
                icon: "message.circle",
                title: "No hay conversaciones",
                message: "Inicia una conversación con otros estudiantes Erasmus"
            )
            .padding(.horizontal, 20)
            
            Button(action: {}) {
                Text("Buscar estudiantes")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Chat Detail View
struct ChatDetailView: View {
    let conversation: Conversation
    @ObservedObject var chatManager = ChatManager.shared
    @EnvironmentObject var authManager: FirebaseAuthManager
    @State private var newMessageText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Messages list
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(chatManager.messages) { message in
                        MessageBubbleView(message: message, isFromCurrentUser: message.senderId == (authManager.currentUser?.id ?? ""))
                            .id(message.id)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .onAppear {
                if let id = conversation.id {
                    chatManager.startListeningToMessages(conversationId: id)
                }
            }
            
            // Message input
            MessageInputView(
                messageText: $newMessageText,
                onSend: sendMessage
            )
        }
        .navigationTitle(conversation.otherUser?.name ?? "Chat")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: {}) {
                    Image(systemName: "phone")
                        .foregroundColor(.blue)
                }
            }
        }
    }
    
    private func sendMessage() {
        guard !newMessageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard let conversationId = conversation.id else { return }
        
        chatManager.sendMessage(conversationId: conversationId, content: newMessageText)
        newMessageText = ""
    }
}

// MARK: - Message Bubble View
struct MessageBubbleView: View {
    let message: ChatMessage
    let isFromCurrentUser: Bool
    
    var body: some View {
        HStack {
            if isFromCurrentUser {
                Spacer(minLength: 50)
            }
            
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.body)
                    .foregroundColor(isFromCurrentUser ? .white : .primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(isFromCurrentUser ? 
                                AnyShapeStyle(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)) :
                                AnyShapeStyle(Color.gray.opacity(0.3))
                            )
                    )
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            }
            
            if !isFromCurrentUser {
                Spacer(minLength: 50)
            }
        }
    }
}

// MARK: - Message Input View
struct MessageInputView: View {
    @Binding var messageText: String
    let onSend: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            HStack {
                TextField("Escribe un mensaje...", text: $messageText, axis: .vertical)
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

// MARK: - New Chat View
struct NewChatView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var searchResults: [ChatUser] = []
    @State private var isSearching = false
    
    var filteredUsers: [ChatUser] {
        return searchResults
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Buscar estudiantes...", text: $searchText)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.15))
                .cornerRadius(10)
                .padding(.horizontal, 16)
                
                // Users list
                List(filteredUsers) { user in
                    Button(action: {
                        Task {
                             let _ = await ChatManager.shared.createNewChat(with: user.id)
                             dismiss()
                        }
                    }) {
                        HStack(spacing: 12) {
                            AsyncImage(url: URL(string: "https://picsum.photos/300/300?random=\(user.id)")) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Circle()
                                    .fill(LinearGradient(colors: [.blue.opacity(0.3), .purple.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .font(.title2)
                                            .foregroundColor(.white.opacity(0.8))
                                    )
                            }
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(user.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text(user.university ?? "Erasmus Student")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .listStyle(PlainListStyle())
                
                if isSearching {
                    ProgressView()
                        .padding()
                }
            }
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
            .onAppear {
                Task {
                    isSearching = true
                    searchResults = await ChatManager.shared.searchUsers(query: "")
                    isSearching = false
                }
            }
            .onChange(of: searchText) { newValue in
                Task {
                    isSearching = true
                    searchResults = await ChatManager.shared.searchUsers(query: newValue)
                    isSearching = false
                }
            }
        }
    }
}
