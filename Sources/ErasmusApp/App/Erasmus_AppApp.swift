import SwiftUI
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
import FirebaseMessaging
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { _, _ in }
        application.registerForRemoteNotifications()
        Messaging.messaging().delegate = self
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }

    // Save FCM token to Firestore so we can send push notifications to this device
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        print("FCM token: \(token)")
        // Save as soon as user is authenticated (or retry on next launch if not yet)
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Firestore.firestore().collection("users").document(uid).updateData(["fcmToken": token])
    }

    // Show notifications while app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .badge, .sound])
    }

    // Handle user tapping a notification
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        let type = userInfo["type"] as? String ?? ""
        let relatedItemId = userInfo["relatedItemId"] as? String ?? ""
        let fromUserId = userInfo["fromUserId"] as? String ?? ""

        Task { @MainActor in
            let router = NavigationRouter.shared
            switch type {
            case "message.fill":
                if !relatedItemId.isEmpty {
                    router.pendingTarget = .chat(conversationId: relatedItemId)
                }
            case "person.badge.plus", "person.2.fill":
                router.pendingTarget = .notifications
            case "heart.fill", "bubble.right.fill":
                if !relatedItemId.isEmpty {
                    router.pendingTarget = .post(postId: relatedItemId)
                }
            default:
                if !fromUserId.isEmpty {
                    router.pendingTarget = .profile(userId: fromUserId)
                } else {
                    router.pendingTarget = .notifications
                }
            }
        }
        completionHandler()
    }
}

@main
struct ErasmusApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    init() {
        FirebaseConfig.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
