import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    @Published var notifications: [AppNotification] = []
    
    var unreadCount: Int {
        notifications.filter { !$0.isRead }.count
    }
    
    var currentToast: AppNotification? {
        return notifications.first(where: { !$0.isRead })
    }
    
    private init() {}
    
    func startListening() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        listener = db.collection("users").document(uid).collection("notifications")
            .order(by: "date", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let documents = snapshot?.documents else { return }
                self.notifications = documents.compactMap { try? $0.data(as: AppNotification.self) }
            }
    }
    
    func stopListening() {
        listener?.remove()
        listener = nil
    }
    
    func addNotification(type: NotificationType, title: String, message: String, relatedItemId: String? = nil, targetUserId: String) {
        let newNotification = AppNotification(
            id: nil,
            type: type,
            title: title,
            message: message,
            date: Date(),
            isRead: false,
            relatedItemId: relatedItemId
        )
        
        do {
            try db.collection("users").document(targetUserId).collection("notifications").addDocument(from: newNotification)
        } catch {
            print("Error sending notification: \(error)")
        }
    }
    
    func markAsRead(notificationId: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(uid).collection("notifications").document(notificationId).updateData([
            "isRead": true
        ])
    }
    
    func markAllAsRead() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let batch = db.batch()

        for notif in notifications where !notif.isRead {
            if let id = notif.id {
                let ref = db.collection("users").document(uid).collection("notifications").document(id)
                batch.updateData(["isRead": true], forDocument: ref)
            }
        }

        batch.commit()
    }

    func deleteNotification(notificationId: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(uid).collection("notifications").document(notificationId).delete()
        // Optimistic UI update
        notifications.removeAll { $0.id == notificationId }
    }

    func deleteNotifications(at offsets: IndexSet) {
        let toDelete = offsets.compactMap { notifications[$0].id }
        for id in toDelete {
            deleteNotification(notificationId: id)
        }
    }
}
