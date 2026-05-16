// ChatView.swift
import SwiftUI

// MARK: - Chat List (Mensajes tab)
struct ChatView: View {
    @StateObject var chatManager = ChatManager.shared
    @EnvironmentObject var authManager: FirebaseAuthManager
    @State private var showNewChatSheet = false
    @State private var navigateToConversationId: String? = nil
    @State private var searchText = ""

    var initialConversationId: String? = nil

    init(initialConversationId: String? = nil) {
        self.initialConversationId = initialConversationId
        _navigateToConversationId = State(initialValue: initialConversationId)
    }

    var filteredConversations: [Conversation] {
        guard !searchText.isEmpty else { return chatManager.conversations }
        return chatManager.conversations.filter {
            $0.otherUser?.name.localizedCaseInsensitiveContains(searchText) ?? false
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                        TextField("Buscar conversaciones...", text: $searchText)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(10)

                    Button(action: { showNewChatSheet = true }) {
                        Image(systemName: "square.and.pencil")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                if chatManager.isLoadingConversations {
                    Spacer()
                    ProgressView("Cargando mensajes...")
                    Spacer()
                } else if filteredConversations.isEmpty {
                    emptyState
                } else {
                    List(filteredConversations) { conversation in
                        NavigationLink(destination:
                            ChatDetailView(conversation: conversation)
                                .environmentObject(authManager)
                        ) {
                            ConversationRowView(conversation: conversation)
                        }
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .listRowSeparator(.hidden)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Mensajes")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showNewChatSheet) {
                NewChatView { conversationId in
                    showNewChatSheet = false
                    navigateToConversationId = conversationId
                }
                .environmentObject(authManager)
            }
            // Navigate to newly created conversation
            .background(
                NavigationLink(
                    destination: Group {
                        if let convId = navigateToConversationId,
                           let conv = chatManager.conversations.first(where: { $0.id == convId }) {
                            ChatDetailView(conversation: conv).environmentObject(authManager)
                        } else if let convId = navigateToConversationId {
                            ChatDetailView(conversation: Conversation(
                                id: convId, participants: [], lastMessage: "",
                                lastMessageTime: Date()
                            )).environmentObject(authManager)
                        }
                    },
                    isActive: Binding(
                        get: { navigateToConversationId != nil },
                        set: { if !$0 { navigateToConversationId = nil } }
                    ),
                    label: { EmptyView() }
                )
            )
        }
        .onAppear { chatManager.startListeningToConversations() }
        .onDisappear { chatManager.stopListeningToConversations() }
    }

    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "message.circle.fill")
                .font(.system(size: 70))
                .foregroundStyle(
                    LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            Text("Sin mensajes aún")
                .font(.title2).fontWeight(.bold)
            Text("Conecta con otros erasmus y empieza a chatear")
                .font(.subheadline).foregroundColor(.secondary)
                .multilineTextAlignment(.center).padding(.horizontal, 40)
            Button(action: { showNewChatSheet = true }) {
                Label("Nuevo mensaje", systemImage: "square.and.pencil")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(14)
            }
            .padding(.horizontal, 40)
            Spacer()
        }
    }
}

// MARK: - Conversation Row
struct ConversationRowView: View {
    let conversation: Conversation

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            UserAvatarView(
                photoURL: conversation.otherUser?.avatarUrl,
                name: conversation.otherUser?.name ?? "?",
                size: 52
            )

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(conversation.otherUser?.name ?? "Usuario")
                        .font(.headline).fontWeight(.semibold)
                    Spacer()
                    Text(conversation.lastMessageTime, style: .time)
                        .font(.caption).foregroundColor(.secondary)
                }
                HStack {
                    Text(conversation.lastMessage.isEmpty ? "Inicia la conversación" : conversation.lastMessage)
                        .font(.subheadline).foregroundColor(.secondary)
                        .lineLimit(1)
                    Spacer()
                    if conversation.unreadCount > 0 {
                        Text("\(conversation.unreadCount)")
                            .font(.caption2).fontWeight(.bold).foregroundColor(.white)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.blue).clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Chat Detail (conversación abierta)
struct ChatDetailView: View {
    let conversation: Conversation
    @StateObject var chatManager = ChatManager.shared
    @EnvironmentObject var authManager: FirebaseAuthManager
    @State private var messageText = ""
    @State private var sendError: String? = nil

    var conversationId: String { conversation.id ?? "" }

    var body: some View {
        VStack(spacing: 0) {
            // Error banner
            if let error = chatManager.messagesError {
                HStack {
                    Image(systemName: "wifi.exclamationmark")
                    Text("Error de conexión. Revisa las reglas de Firestore.")
                        .font(.caption)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.red.opacity(0.85))
                .transition(.move(edge: .top))
                .onTapGesture { chatManager.messagesError = nil }
            }

            if let sendErr = sendError {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                    Text(sendErr).font(.caption)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16).padding(.vertical, 8)
                .background(Color.orange.opacity(0.9))
                .onTapGesture { sendError = nil }
            }

            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 6) {
                        // Loading state
                        if chatManager.isLoadingMessages {
                            ProgressView().padding(.vertical, 40)
                        } else if chatManager.messages.isEmpty {
                            // Empty state
                            VStack(spacing: 12) {
                                Image(systemName: "bubble.left.and.bubble.right")
                                    .font(.system(size: 44))
                                    .foregroundColor(.gray.opacity(0.35))
                                Text("Empieza la conversación")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 60)
                        } else {
                            ForEach(chatManager.messages) { message in
                                MessageBubbleView(
                                    message: message,
                                    isFromCurrentUser: message.senderId == authManager.currentUser?.id,
                                    senderName: message.senderId == authManager.currentUser?.id
                                        ? nil
                                        : conversation.otherUser?.name
                                )
                                .id(message.id)
                            }
                        }

                        Color.clear.frame(height: 1).id("bottom")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .onChange(of: chatManager.messages.count) { _ in
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
            }

            // Input bar
            MessageInputBar(messageText: $messageText) {
                sendMessage()
            }
        }
        .navigationTitle(conversation.otherUser?.name ?? "Chat")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if let avatarUrl = conversation.otherUser?.avatarUrl,
                   let url = URL(string: avatarUrl) {
                    AsyncImage(url: url) { img in
                        img.resizable().scaledToFill()
                    } placeholder: {
                        Circle().fill(Color.blue.opacity(0.2))
                    }
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                }
            }
        }
        .onAppear {
            guard !conversationId.isEmpty else { return }
            chatManager.startListeningToMessages(conversationId: conversationId)
        }
        .onDisappear {
            chatManager.stopListeningToMessages()
        }
    }

    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        messageText = ""
        sendError = nil
        Task {
            let success = await chatManager.sendMessage(conversationId: conversationId, content: text)
            if !success {
                sendError = "No se pudo enviar. Comprueba tu conexión."
            }
        }
    }
}

// MARK: - Message Bubble
struct MessageBubbleView: View {
    let message: ChatMessage
    let isFromCurrentUser: Bool
    var senderName: String? = nil

    var body: some View {
        HStack(alignment: .bottom, spacing: 6) {
            if isFromCurrentUser { Spacer(minLength: 60) }

            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 3) {
                Text(message.content)
                    .font(.body)
                    .foregroundColor(isFromCurrentUser ? .white : .primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(isFromCurrentUser
                                  ? AnyShapeStyle(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing))
                                  : AnyShapeStyle(Color(UIColor.systemGray5)))
                    )

                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            }

            if !isFromCurrentUser { Spacer(minLength: 60) }
        }
    }
}

// MARK: - Message Input Bar
struct MessageInputBar: View {
    @Binding var messageText: String
    let onSend: () -> Void
    @FocusState private var isFocused: Bool

    var isEmpty: Bool { messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var body: some View {
        HStack(spacing: 10) {
            TextField("Escribe un mensaje...", text: $messageText, axis: .vertical)
                .lineLimit(1...5)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(22)
                .focused($isFocused)
                .onSubmit { if !isEmpty { onSend() } }

            Button(action: onSend) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 34))
                    .foregroundColor(isEmpty ? .gray.opacity(0.4) : .blue)
            }
            .disabled(isEmpty)
            .animation(.easeInOut(duration: 0.15), value: isEmpty)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .overlay(Rectangle().frame(height: 0.5).foregroundColor(.gray.opacity(0.2)), alignment: .top)
    }
}

// MARK: - New Chat View
struct NewChatView: View {
    let onConversationCreated: (String) -> Void
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: FirebaseAuthManager
    @State private var searchText = ""
    @State private var searchResults: [ChatUser] = []
    @State private var isSearching = false
    @State private var isCreating = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                    TextField("Buscar por nombre...", text: $searchText)
                        .onChange(of: searchText) { value in
                            Task { await search(query: value) }
                        }
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                if isSearching {
                    Spacer()
                    ProgressView("Buscando...")
                    Spacer()
                } else if searchResults.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "person.2").font(.system(size: 44)).foregroundColor(.gray.opacity(0.4))
                        Text(searchText.isEmpty ? "Escribe un nombre para buscar" : "Sin resultados para \"\(searchText)\"")
                            .font(.subheadline).foregroundColor(.secondary).multilineTextAlignment(.center)
                    }
                    Spacer()
                } else {
                    List(searchResults) { user in
                        Button(action: { startChat(with: user) }) {
                            HStack(spacing: 12) {
                                UserAvatarView(photoURL: user.avatarUrl, name: user.name, size: 44)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(user.name).font(.headline).foregroundColor(.primary)
                                    Text(user.university ?? "Erasmus Student")
                                        .font(.caption).foregroundColor(.secondary)
                                }
                                Spacer()
                                if isCreating {
                                    ProgressView().scaleEffect(0.8)
                                } else {
                                    Image(systemName: "message.fill")
                                        .foregroundColor(.blue).font(.subheadline)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                        .listRowSeparator(.hidden)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Nuevo mensaje")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
        .onAppear {
            Task { await search(query: "") }
        }
    }

    private func search(query: String) async {
        isSearching = true
        searchResults = await ChatManager.shared.searchUsers(query: query)
        isSearching = false
    }

    private func startChat(with user: ChatUser) {
        guard !isCreating else { return }
        isCreating = true
        Task {
            if let convId = await ChatManager.shared.getOrCreateConversation(with: user.id) {
                // Refresh conversations list
                ChatManager.shared.startListeningToConversations()
                onConversationCreated(convId)
            }
            isCreating = false
        }
    }
}

// MARK: - Reusable Avatar View
struct UserAvatarView: View {
    let photoURL: String?
    let name: String
    let size: CGFloat

    var body: some View {
        Group {
            if let urlStr = photoURL, !urlStr.isEmpty, let url = URL(string: urlStr) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    initialsView
                }
            } else {
                initialsView
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    private var initialsView: some View {
        ZStack {
            LinearGradient(
                colors: [avatarColor, avatarColor.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Text(initials)
                .font(.system(size: size * 0.36, weight: .semibold))
                .foregroundColor(.white)
        }
    }

    private var initials: String {
        let parts = name.split(separator: " ")
        let first = parts.first?.prefix(1) ?? ""
        let last = parts.count > 1 ? parts.last?.prefix(1) ?? "" : ""
        return "\(first)\(last)".uppercased()
    }

    private var avatarColor: Color {
        let colors: [Color] = [.blue, .purple, .teal, .orange, .pink, .green, .indigo]
        let index = abs(name.hashValue) % colors.count
        return colors[index]
    }
}
