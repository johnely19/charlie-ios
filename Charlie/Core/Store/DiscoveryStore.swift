import SwiftUI
import MapKit

@Observable
class DiscoveryStore {
    var discoveries: [Discovery] = []
    var trieEntries: [String: TriageEntry] = [:] // keyed by discoveryId
    var contexts: [Context] = []
    var activeContext: Context?
    var isLoading = false
    var error: String?

    var filteredDiscoveries: [Discovery] {
        guard let ctx = activeContext else { return discoveries }
        return discoveries.filter { $0.contextKey == ctx.key }
    }

    func triageState(for discoveryId: String) -> TriageState {
        return trieEntries[discoveryId]?.state ?? .unreviewed
    }

    func load() async {
        isLoading = true
        do {
            async let discos = APIClient.shared.discoveries()
            async let mani = APIClient.shared.manifest()
            let (d, m) = try await (discos, mani)
            discoveries = d
            contexts = m.contexts
            activeContext = m.contexts.first(where: { $0.active }) ?? m.contexts.first
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func setTriage(discovery: Discovery, state: TriageState) async {
        guard let ctx = activeContext else { return }
        do {
            try await APIClient.shared.setTriage(discoveryId: discovery.id, contextKey: ctx.key, state: state)
            trieEntries[discovery.id] = TriageEntry(discoveryId: discovery.id, state: state, updatedAt: Date(), contextKey: ctx.key)
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