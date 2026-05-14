import Foundation
import FirebaseFirestore

struct AppNotification: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    let type: NotificationType
    let title: String
    let message: String
    let date: Date
    var isRead: Bool
    let relatedItemId: String?
    let fromUserId: String?
    let fromUserName: String?
    let fromUserPhotoURL: String?

    init(id: String? = nil, type: NotificationType, title: String, message: String, date: Date = Date(), isRead: Bool = false, relatedItemId: String? = nil, fromUserId: String? = nil, fromUserName: String? = nil, fromUserPhotoURL: String? = nil) {
        self.id = id
        self.type = type
        self.title = title
        self.message = message
        self.date = date
        self.isRead = isRead
        self.relatedItemId = relatedItemId
        self.fromUserId = fromUserId
        self.fromUserName = fromUserName
        self.fromUserPhotoURL = fromUserPhotoURL
    }
}

enum NotificationType: String, Codable, Equatable {
    case like = "heart.fill"
    case comment = "bubble.right.fill"
    case system = "bell.fill"
    case newEvent = "calendar"
    case friendRequest = "person.badge.plus"
    case friendAccepted = "person.2.fill"
    case newFollower = "person.crop.circle.badge.plus"
    case message = "message.fill"
    case planJoin = "person.3.fill"
    case planInvite = "map.fill"
    case groupInvite = "rectangle.3.group.fill"
    case eventReminder = "alarm.fill"
    case recommendation = "star.fill"
    case housing = "house.fill"
}
