import SwiftUI
import MapKit
import UIKit
import UserNotifications

@main
struct CharlieApp: App {
    @State private var discoveryStore = DiscoveryStore()
    @State private var isAuthenticated = AuthManager.shared.isAuthenticated
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            if isAuthenticated {
                MapView()
                    .environment(discoveryStore)
                    .task { await NotificationManager.shared.requestPermission() }
            } else {
                OnboardingView(onComplete: { isAuthenticated = true })
            }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        application.registerForRemoteNotifications()
        return true
    }

    // Handle notification tap — foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        return [.banner, .badge, .sound]
    }

    // Handle notification tap — background/cold launch
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        let userInfo = response.notification.request.content.userInfo
        let type = userInfo["type"] as? String ?? ""
        let contextKey = userInfo["contextKey"] as? String ?? ""

        // Post notification for the app to handle deep linking
        NotificationCenter.default.post(
            name: .charlieNotificationTapped,
            object: nil,
            userInfo: ["type": type, "contextKey": contextKey]
        )
    }

    // APNs token registration (placeholder — needed for server-side push)
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02x", $0) }.joined()
        print("[APNs] Device token: \(tokenString)")
        // TODO: POST token to /api/notifications/register when endpoint exists
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("[APNs] Failed to register: \(error)")
    }
}

extension Notification.Name {
    static let charlieNotificationTapped = Notification.Name("charlieNotificationTapped")
}