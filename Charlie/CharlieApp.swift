import SwiftUI

@main
struct CharlieApp: App {
    @State private var discoveryStore = DiscoveryStore()

    var body: some Scene {
        WindowGroup {
            MapView()
                .environment(discoveryStore)
        }
    }
}