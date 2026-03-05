import Foundation
import FirebaseFirestore

struct AppNotification: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    let type: NotificationType
    let title: String
    let message: String
    let date: Date
    var isRead: Bool
    let relatedItemId: String? // ID of the post, user, or event
}

enum NotificationType: String, Codable, Equatable {
    case like = "heart.fill"
    case comment = "bubble.right.fill"
    case system = "bell.fill"
    case newEvent = "calendar"
}
