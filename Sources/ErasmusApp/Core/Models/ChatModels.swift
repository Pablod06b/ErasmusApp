import Foundation
import FirebaseFirestore

struct ChatUser: Identifiable, Codable {
    let id: String
    let name: String
    let avatarUrl: String?
    let university: String?
}

extension ChatUser {
    static let sampleUsers: [ChatUser] = [
        ChatUser(id: "user1", name: "Elena Rodríguez", avatarUrl: nil, university: "Universidad de Salamanca"),
        ChatUser(id: "user2", name: "Pietro Bianchi", avatarUrl: nil, university: "Università di Firenze"),
        ChatUser(id: "user3", name: "Marie Dubois", avatarUrl: nil, university: "Université de Lyon"),
        ChatUser(id: "user4", name: "Klaus Weber", avatarUrl: nil, university: "Universität München"),
        ChatUser(id: "user5", name: "Emma Johnson", avatarUrl: nil, university: "University of Edinburgh"),
        ChatUser(id: "user6", name: "Carlos Silva", avatarUrl: nil, university: "Universidade do Porto")
    ]
}

struct Conversation: Identifiable, Codable {
    @DocumentID var id: String?
    let participants: [String] // User IDs
    var lastMessage: String
    var lastMessageTime: Date
    var unreadCount: Int = 0
    /// Timestamp por usuario de la última vez que abrió la conversación.
    /// Si lastReadAt[otherUserId] >= lastMessageTime del último mensaje mío, está leído.
    var lastReadAt: [String: Date]? = nil
    var otherUser: ChatUser? // Local helper, not stored in Firestore usually, but we might denormalize for simplicity or fetch separately

    enum CodingKeys: String, CodingKey {
        case id
        case participants
        case lastMessage
        case lastMessageTime
        case unreadCount
        case lastReadAt
    }
}

enum MessageType: String, Codable {
    case text
    case image
}

struct ChatMessage: Identifiable, Codable {
    @DocumentID var id: String?
    let senderId: String
    let content: String
    let timestamp: Date
    let type: MessageType

    enum CodingKeys: String, CodingKey {
        case id
        case senderId
        case content
        case timestamp
        case type
    }

    // Manual init used by ChatManager to decode from raw Firestore data
    init(id: String?, senderId: String, content: String, timestamp: Date, type: MessageType) {
        self.id = id
        self.senderId = senderId
        self.content = content
        self.timestamp = timestamp
        self.type = type
    }
}
