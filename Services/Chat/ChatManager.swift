import Foundation
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
#if canImport(UIKit)
import UIKit
#endif

@MainActor
class ChatManager: ObservableObject {
    static let shared = ChatManager()
    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    @Published var conversations: [Conversation] = []
    @Published var messages: [ChatMessage] = []
    @Published var isLoadingConversations = false
    @Published var isLoadingMessages = false
    @Published var messagesError: String? = nil

    private var conversationsListener: ListenerRegistration?
    private var messagesListener: ListenerRegistration?

    private init() {}

    deinit {
        conversationsListener?.remove()
        messagesListener?.remove()
    }

    // MARK: - Conversations

    func startListeningToConversations() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        isLoadingConversations = true

        conversationsListener?.remove()
        conversationsListener = db.collection("conversations")
            .whereField("participants", arrayContains: currentUserId)
            .order(by: "lastMessageTime", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    if let error = error {
                        print("Conversations listener error: \(error.localizedDescription)")
                        AppErrorManager.shared.report("No se pudieron cargar tus mensajes.", icon: "message.badge.fill")
                        self.isLoadingConversations = false
                        return
                    }
                    guard let documents = snapshot?.documents else {
                        self.isLoadingConversations = false
                        return
                    }
                    let convs = documents.compactMap { try? $0.data(as: Conversation.self) }
                    self.isLoadingConversations = false
                    await self.enrichConversations(convs, currentUserId: currentUserId)
                }
            }
    }

    func stopListeningToConversations() {
        conversationsListener?.remove()
        conversationsListener = nil
    }

    private func enrichConversations(_ convs: [Conversation], currentUserId: String) async {
        let blocked = await MainActor.run { SocialManager.shared.blockedUserIds }
        // Filtra conversaciones con usuarios bloqueados
        let visible = convs.filter { conv in
            guard let other = conv.participants.first(where: { $0 != currentUserId }) else { return true }
            return !blocked.contains(other)
        }
        var enriched = visible
        for i in 0..<enriched.count {
            guard let otherUserId = enriched[i].participants.first(where: { $0 != currentUserId }) else { continue }
            if let user = await fetchChatUser(userId: otherUserId) {
                enriched[i].otherUser = user
            }
        }
        conversations = enriched
    }

    private func fetchChatUser(userId: String) async -> ChatUser? {
        do {
            let doc = try await db.collection("users").document(userId).getDocument()
            guard doc.exists, let data = doc.data() else { return nil }
            return ChatUser(
                id: userId,
                name: data["displayName"] as? String ?? "Usuario",
                avatarUrl: data["photoURL"] as? String,
                university: data["university"] as? String
            )
        } catch {
            return nil
        }
    }

    // MARK: - Create or Get Conversation

    func getOrCreateConversation(with otherUserId: String) async -> String? {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return nil }

        let conversationId = [currentUserId, otherUserId].sorted().joined(separator: "_")
        let ref = db.collection("conversations").document(conversationId)

        do {
            let doc = try await ref.getDocument()
            if !doc.exists {
                try await ref.setData([
                    "participants": [currentUserId, otherUserId],
                    "lastMessage": "",
                    "lastMessageTime": FieldValue.serverTimestamp(),
                    "unreadCount": 0
                ])
            }
            return conversationId
        } catch {
            print("Error creating conversation: \(error)")
            return nil
        }
    }

    // MARK: - Direct Messages

    /// Conteo de fallos consecutivos del listener de mensajes.
    /// Solo mostramos el banner de error tras 3 fallos seguidos para evitar
    /// flashes transitorios al recién crear una conversación o por latencia.
    private var messagesErrorStreak: Int = 0

    func startListeningToMessages(conversationId: String) {
        guard !conversationId.isEmpty else { return }
        isLoadingMessages = true
        messagesError = nil
        messagesErrorStreak = 0
        messages = []
        messagesListener?.remove()

        messagesListener = db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    if let error = error {
                        print("Messages listener error: \(error.localizedDescription)")
                        self.messagesErrorStreak += 1
                        self.isLoadingMessages = false
                        // Solo enseña el banner si falla >=3 veces seguidas
                        if self.messagesErrorStreak >= 3 {
                            self.messagesError = "No podemos cargar los mensajes. Comprueba tu conexión."
                        }
                        return
                    }
                    guard let documents = snapshot?.documents else {
                        self.isLoadingMessages = false
                        return
                    }
                    // Reset error streak en éxito
                    self.messagesErrorStreak = 0
                    self.messagesError = nil
                    self.messages = documents.compactMap { doc -> ChatMessage? in
                        // Manual decode to handle Firestore Timestamp → Date
                        let data = doc.data()
                        guard
                            let senderId = data["senderId"] as? String,
                            let content = data["content"] as? String,
                            let ts = data["timestamp"] as? Timestamp
                        else { return nil }
                        let typeRaw = data["type"] as? String ?? "text"
                        let msgType = MessageType(rawValue: typeRaw) ?? .text
                        return ChatMessage(
                            id: doc.documentID,
                            senderId: senderId,
                            content: content,
                            timestamp: ts.dateValue(),
                            type: msgType
                        )
                    }
                    self.isLoadingMessages = false
                }
            }
    }

    // MARK: - Group Messages

    func startListeningToGroupMessages(groupId: String) {
        guard !groupId.isEmpty else { return }
        messages = []
        isLoadingMessages = false
        messagesError = nil
        messagesListener?.remove()

        messagesListener = db.collection("groups")
            .document(groupId)
            .collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    if let error = error {
                        print("Group messages error: \(error.localizedDescription)")
                        return
                    }
                    guard let documents = snapshot?.documents else { return }
                    self.messages = documents.compactMap { doc -> ChatMessage? in
                        let data = doc.data()
                        guard
                            let senderId = data["senderId"] as? String,
                            let content = data["content"] as? String,
                            let ts = data["timestamp"] as? Timestamp
                        else { return nil }
                        let typeRaw = data["type"] as? String ?? "text"
                        let msgType = MessageType(rawValue: typeRaw) ?? .text
                        return ChatMessage(
                            id: doc.documentID,
                            senderId: senderId,
                            content: content,
                            timestamp: ts.dateValue(),
                            type: msgType
                        )
                    }
                }
            }
    }

    func stopListeningToMessages() {
        messagesListener?.remove()
        messagesListener = nil
        messages = []
        isLoadingMessages = false
        messagesError = nil
    }

    /// Marca la conversación como leída en este momento por el usuario actual.
    /// Llamar al abrir ChatDetailView.
    func markConversationAsRead(conversationId: String) async {
        guard let uid = Auth.auth().currentUser?.uid, !conversationId.isEmpty else { return }
        try? await db.collection("conversations").document(conversationId).updateData([
            "lastReadAt.\(uid)": FieldValue.serverTimestamp()
        ])
    }

    // MARK: - Send Message

    func sendMessage(conversationId: String, content: String) async -> Bool {
        guard let currentUserId = Auth.auth().currentUser?.uid,
              !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !conversationId.isEmpty else { return false }

        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        let messageData: [String: Any] = [
            "senderId": currentUserId,
            "content": trimmed,
            "timestamp": FieldValue.serverTimestamp(),
            "type": "text"
        ]

        do {
            try await db.collection("conversations")
                .document(conversationId)
                .collection("messages")
                .addDocument(data: messageData)

            try await db.collection("conversations").document(conversationId).updateData([
                "lastMessage": trimmed,
                "lastMessageTime": FieldValue.serverTimestamp()
            ])

            // Write notification to each recipient so Cloud Function sends FCM push
            let convDoc = try await db.collection("conversations").document(conversationId).getDocument()
            if let participants = convDoc.data()?["participants"] as? [String] {
                let senderName = Auth.auth().currentUser?.displayName ?? "Alguien"
                for recipientId in participants where recipientId != currentUserId {
                    let notif: [String: Any] = [
                        "type": "message.fill",
                        "title": senderName,
                        "body": trimmed.count > 60 ? String(trimmed.prefix(60)) + "…" : trimmed,
                        "fromUserId": currentUserId,
                        "relatedItemId": conversationId,
                        "createdAt": FieldValue.serverTimestamp(),
                        "read": false
                    ]
                    try await db.collection("users").document(recipientId)
                        .collection("notifications").addDocument(data: notif)
                }
            }
            AppAnalytics.logMessageSend(conversationId: conversationId, type: "text")
            return true
        } catch {
            print("Error sending message: \(error.localizedDescription)")
            AppErrorManager.shared.report("No se pudo enviar el mensaje. Inténtalo de nuevo.", icon: "exclamationmark.bubble.fill")
            return false
        }
    }

    #if canImport(UIKit)
    /// Sube una imagen a Storage y crea un mensaje tipo "image" con la URL en `content`.
    func sendImageMessage(conversationId: String, image: UIImage) async -> Bool {
        guard let currentUserId = Auth.auth().currentUser?.uid,
              !conversationId.isEmpty,
              let data = image.jpegData(compressionQuality: 0.8) else { return false }
        let fileName = "\(UUID().uuidString).jpg"
        let path = "chat/\(conversationId)/\(currentUserId)/\(fileName)"
        let ref = storage.reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        do {
            _ = try await ref.putDataAsync(data, metadata: metadata)
            let urlStr = try await ref.downloadURL().absoluteString

            try await db.collection("conversations")
                .document(conversationId)
                .collection("messages")
                .addDocument(data: [
                    "senderId": currentUserId,
                    "content": urlStr,
                    "timestamp": FieldValue.serverTimestamp(),
                    "type": "image"
                ])

            try await db.collection("conversations").document(conversationId).updateData([
                "lastMessage": "📷 Foto",
                "lastMessageTime": FieldValue.serverTimestamp()
            ])
            AppAnalytics.logMessageSend(conversationId: conversationId, type: "image")
            return true
        } catch {
            print("Error sending image: \(error.localizedDescription)")
            AppErrorManager.shared.report("No se pudo enviar la imagen.", icon: "photo.fill")
            return false
        }
    }
    #endif

    func sendGroupMessage(groupId: String, content: String) async {
        guard let currentUserId = Auth.auth().currentUser?.uid,
              !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        let messageData: [String: Any] = [
            "senderId": currentUserId,
            "content": trimmed,
            "timestamp": FieldValue.serverTimestamp(),
            "type": "text"
        ]

        do {
            try await db.collection("groups")
                .document(groupId)
                .collection("messages")
                .addDocument(data: messageData)
        } catch {
            print("Error sending group message: \(error.localizedDescription)")
            AppErrorManager.shared.report("No se pudo enviar el mensaje al grupo.", icon: "exclamationmark.bubble.fill")
        }
    }

    // MARK: - Search Users

    func searchUsers(query: String) async -> [ChatUser] {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return [] }
        do {
            let snapshot = try await db.collection("users").limit(to: PageSize.users).getDocuments()
            return snapshot.documents.compactMap { doc -> ChatUser? in
                guard doc.documentID != currentUserId else { return nil }
                let data = doc.data()
                let name = data["displayName"] as? String ?? "Usuario"
                guard query.isEmpty || name.localizedCaseInsensitiveContains(query) else { return nil }
                return ChatUser(
                    id: doc.documentID,
                    name: name,
                    avatarUrl: data["photoURL"] as? String,
                    university: data["university"] as? String
                )
            }
        } catch {
            print("Error searching users: \(error)")
            return []
        }
    }
}
