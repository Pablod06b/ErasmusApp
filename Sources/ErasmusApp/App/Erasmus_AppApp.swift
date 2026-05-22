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
        // Mensajería (FCM)
        Messaging.messaging().apnsToken = deviceToken
        // Firebase Auth — necesita el APNS token para Phone Auth (verificación silenciosa)
        #if DEBUG
        Auth.auth().setAPNSToken(deviceToken, type: .sandbox)
        #else
        Auth.auth().setAPNSToken(deviceToken, type: .prod)
        #endif
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("APNS register error: \(error.localizedDescription)")
    }

    // Reenvía silent push notifications a Firebase Auth (Phone Auth las usa para
    // verificar el dispositivo sin reCAPTCHA visible). Si Auth no la consume,
    // la procesamos normalmente.
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if Auth.auth().canHandleNotification(userInfo) {
            completionHandler(.noData)
            return
        }
        // FCM también gestiona algunas; dejamos que Messaging las vea
        completionHandler(.newData)
    }

    // Necesario para que Auth procese el callback del reCAPTCHA si cae en él
    func application(_ application: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        if Auth.auth().canHandle(url) { return true }
        return false
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
