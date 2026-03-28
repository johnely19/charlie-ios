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
                    .task {
                        // Restore token into APIClient on every cold launch
                        if let token = AuthManager.shared.loadToken() {
                            await APIClient.shared.setToken(token)
                        }
                        // Load data — cache-first so map renders even offline
                        await discoveryStore.load()
                        await NotificationManager.shared.requestPermission()
                    }
            } else {
                OnboardingView(onComplete: {
                    isAuthenticated = true
                    // After onboarding, load data (token already set + cache already warm)
                    Task {
                        if let token = AuthManager.shared.loadToken() {
                            await APIClient.shared.setToken(token)
                        }
                        await discoveryStore.load()
                    }
                })
            }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        application.registerForRemoteNotifications()
        return true
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                 willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        return [.banner, .badge, .sound]
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                 didReceive response: UNNotificationResponse) async {
        let userInfo = response.notification.request.content.userInfo
        let type = userInfo["type"] as? String ?? ""
        let contextKey = userInfo["contextKey"] as? String ?? ""
        NotificationCenter.default.post(
            name: .charlieNotificationTapped,
            object: nil,
            userInfo: ["type": type, "contextKey": contextKey]
        )
    }

    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        print("[APNs] Device token: \(token)")
        // TODO: POST to /api/notifications/register
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("[APNs] Failed: \(error)")
    }
}

extension Notification.Name {
    static let charlieNotificationTapped = Notification.Name("charlieNotificationTapped")
    static let charlieOpenPlaceCard = Notification.Name("charlieOpenPlaceCard")
}
