import SwiftUI
import MapKit
import UIKit

@Observable
class DiscoveryStore {
    var discoveries: [Discovery] = []
    var triageStore = TriageStore()
    var contexts: [Context] = []
    var activeContext: Context?
    var isLoading = false
    var error: String?

    var filteredDiscoveries: [Discovery] {
        guard let ctx = activeContext else { return discoveries }
        return discoveries.filter { discovery in
            guard discovery.contextKey == ctx.key else { return false }
            let state = triageStore.state(for: discovery.id, in: ctx.key)
            return state == .unreviewed || state == .resurfaced
        }
    }

    var savedDiscoveriesForRoute: [Discovery] {
        guard let ctx = activeContext else { return [] }
        return discoveries.filter { d in
            d.contextKey == ctx.key && triageStore.state(for: d.id, in: ctx.key) == .saved
        }
    }

    var hasEnoughSavedForRoute: Bool {
        savedDiscoveriesForRoute.count >= 3
    }

    func triageState(for discoveryId: String) -> TriageState {
        guard let ctx = activeContext else { return .unreviewed }
        return triageStore.state(for: discoveryId, in: ctx.key)
    }

    func load() async {
        isLoading = true
        do {
            async let discos = APIClient.shared.discoveries()
            async let mani = APIClient.shared.manifest()
            async let triage = APIClient.shared.triageEntries()
            let (d, m, t) = try await (discos, mani, triage)
            discoveries = d
            contexts = m.contexts
            activeContext = m.contexts.first(where: { $0.active }) ?? m.contexts.first
            triageStore.loadFromServer(t)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func triage(discovery: Discovery, state: TriageState) async {
        guard let ctx = activeContext else { return }
        triageStore.setState(state, for: discovery.id, in: ctx.key)

        // Haptic feedback based on state
        if state == .saved {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } else if state == .dismissed {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        do {
            try await APIClient.shared.setTriage(discoveryId: discovery.id, contextKey: ctx.key, state: state)
        } catch {
            self.error = error.localizedDescription
        }
    }
}

extension Context {
    var accommodationCoordinate: CLLocationCoordinate2D? {
        guard let lat = accommodation?.lat, let lng = accommodation?.lng else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }

    var mapRegion: MKCoordinateRegion {
        // Default regions for known cities
        switch city?.lowercased() {
        case "nyc", "new york":
            return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060), latitudinalMeters: 20000, longitudinalMeters: 20000)
        case "toronto":
            return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 43.6532, longitude: -79.3832), latitudinalMeters: 15000, longitudinalMeters: 15000)
        default:
            return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 43.6532, longitude: -79.3832), latitudinalMeters: 50000, longitudinalMeters: 50000)
        }
    }
}