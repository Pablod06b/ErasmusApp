import Foundation
import FirebaseFirestore
import FirebaseAuth

class ChatManager: ObservableObject {
    static let shared = ChatManager()
    private let db = Firestore.firestore()
    
    @Published var conversations: [Conversation] = []
    @Published var messages: [ChatMessage] = []
    
    private init() {}
    
    // MARK: - User Search
    func searchUsers(query: String) async -> [ChatUser] {
        guard !query.isEmpty else { return [] }
        do {
            let snapshot = try await db.collection("users").getDocuments()
            let allUsers = snapshot.documents.compactMap { doc -> ChatUser? in
                let data = doc.data()
                let id = doc.documentID
                let name = data["displayName"] as? String ?? "Usuario"
                let avatarUrl = data["photoURL"] as? String
                let university = data["university"] as? String
                return ChatUser(id: id, name: name, avatarUrl: avatarUrl, university: university)
            }
            
            return allUsers.filter { $0.name.localizedCaseInsensitiveContains(query) && $0.id != Auth.auth().currentUser?.uid }
        } catch {
            print("Error searching users: \(error)")
            return []
        }
    }
    
    // MARK: - Conversations
    func startListeningToConversations() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("conversations")
            .whereField("participants", arrayContains: currentUserId)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents, error == nil else {
                    print("Error fetching conversations: \(error?.localizedDescription ?? "Unknown")")
                    return
                }
                
                self.conversations = documents.compactMap { doc -> Conversation? in
                    try? doc.data(as: Conversation.self)
                }.sorted(by: { $0.lastMessageTime > $1.lastMessageTime })
                
                // Here we might need to fetch user details for 'otherUser' if we don't store them denormalized
                // For now, we assume we might need a separate step or enrich this model.
                // Simplified for this step: We might populate 'otherUser' with a placeholder or fetch it.
                // Let's create a helper to fetch other participant details.
                Task {
                    await self.enrichConversationsWithUsers()
                }
            }
    }
    
    private func enrichConversationsWithUsers() async {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        var enrichedConversations = self.conversations
        
        for i in 0..<enrichedConversations.count {
            let participants = enrichedConversations[i].participants
            if let otherUserId = participants.first(where: { $0 != currentUserId }) {
                // Fetch user data from 'users' collection (assuming it exists or using Auth profiles if stored)
                // If we don't have a 'users' collection yet, we might use placeholders or basic auth info if readable
                // For this MVP, we will try to fetch from a 'users' collection which is standard.
                // If it fails, we fall back to a placeholder.
                
                // Placeholder logic for now until User Profile is robust
                enrichedConversations[i].otherUser = ChatUser(id: otherUserId, name: "User", avatarUrl: nil, university: nil)
            }
        }
        
        DispatchQueue.main.async {
            self.conversations = enrichedConversations
        }
    }
    
    // MARK: - Messages
    func startListeningToMessages(conversationId: String? = nil, groupId: String? = nil) {
        let collectionRef: CollectionReference
        
        if let groupId = groupId {
            // Group Chat Path: groups/{groupId}/messages
            collectionRef = db.collection("groups").document(groupId).collection("messages")
        } else if let conversationId = conversationId {
            // DM Path: conversations/{conversationId}/messages
            collectionRef = db.collection("conversations").document(conversationId).collection("messages")
        } else {
            return
        }
        
        collectionRef
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents, error == nil else {
                    print("Error fetching messages: \(error?.localizedDescription ?? "Unknown")")
                    return
                }
                
                self.messages = documents.compactMap { doc -> ChatMessage? in
                    try? doc.data(as: ChatMessage.self)
                }
            }
    }
    
    func sendMessage(conversationId: String, content: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let newMessage = ChatMessage(
            id: nil, // auto-generated
            senderId: currentUserId,
            content: content,
            timestamp: Date(),
            type: .text
        )
        
        do {
            // Add message
            try db.collection("conversations").document(conversationId).collection("messages").addDocument(from: newMessage)
            
            // Update conversation last message
            db.collection("conversations").document(conversationId).updateData([
                "lastMessage": content,
                "lastMessageTime": Date()
            ])
        } catch {
            print("Error sending message: \(error)")
        }
    }
    
    func sendGroupMessage(groupId: String, content: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let newMessage = ChatMessage(
            id: nil,
            senderId: currentUserId,
            content: content,
            timestamp: Date(),
            type: .text
        )
        
        do {
            try db.collection("groups").document(groupId).collection("messages").addDocument(from: newMessage)
        } catch {
            print("Error sending group message: \(error)")
        }
    }
    func createNewChat(with otherUserId: String) async -> String? {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return nil }
        
        // Check if conversation already exists (implementation trade-off: client side check or complex query)
        // For simple MVP: Create a new one. Ideal: Check query.
        
        let newConversation = Conversation(
            id: nil,
            participants: [currentUserId, otherUserId],
            lastMessage: "",
            lastMessageTime: Date(),
            otherUser: nil
        )
        
        do {
            let ref = try db.collection("conversations").addDocument(from: newConversation)
            return ref.documentID
        } catch {
            print("Error creating conversation: \(error)")
            return nil
        }
    }
}
