import SwiftUI
import FirebaseCore
import FirebaseMessaging
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Push Notifications setup
        UNUserNotificationCenter.current().delegate = self
        
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: { _, _ in }
        )
        
        application.registerForRemoteNotifications()
        Messaging.messaging().delegate = self
        
        return true
    }
    
    // Fallback for APNs Registration
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    // Firebase FCM Token Received
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token: \(String(describing: fcmToken))")
        // NOTE: In the future, this token should be saved to the authenticated User's Firestore document.
    }
}

@main
struct ErasmusApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // MARK: - App Initialization
    init() {
        // Initialize app settings
        print("🚀 Erasmus App inicializado")
        
        // Configure Firebase
        FirebaseConfig.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

