import SwiftUI
import MapKit
import UIKit
import WidgetKit

@Observable
class DiscoveryStore {
    var discoveries: [Discovery] = []
    var triageStore = TriageStore()
    var contexts: [Context] = []
    var activeContext: Context?
    var isLoading = false
    var error: String?
    var isOffline = false
    var cacheAge: Date?

    @MainActor static var sharedForIntents: DiscoveryStore = {
        let store = DiscoveryStore()
        Task { await store.load() }
        return store
    }()

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

        // 1. Load from cache immediately for instant UI
        let cacheKey = "discoveries"
        let manifestKey = "manifest"

        if let cached = await DiskCache.shared.load([Discovery].self, key: cacheKey) {
            discoveries = cached
            isOffline = true // assume offline until network succeeds
            if let age = await DiskCache.shared.age(of: cacheKey) {
                cacheAge = Date().addingTimeInterval(-age)
            }
        }
        if let cachedManifest = await DiskCache.shared.load(UserManifest.self, key: manifestKey) {
            contexts = cachedManifest.contexts
            if activeContext == nil {
                activeContext = cachedManifest.contexts.first(where: { $0.active }) ?? cachedManifest.contexts.first
            }
        }

        // 2. Try network
        do {
            async let discos = APIClient.shared.discoveries()
            async let mani = APIClient.shared.manifest()
            async let triage = APIClient.shared.triageEntries()
            let (d, m, t) = try await (discos, mani, triage)
            discoveries = d
            contexts = m.contexts
            activeContext = m.contexts.first(where: { $0.active }) ?? m.contexts.first
            triageStore.loadFromServer(t)
            isOffline = false

            // 3. Save to cache
            await DiskCache.shared.save(d, key: cacheKey)
            await DiskCache.shared.save(m, key: manifestKey)
        } catch {
            // Network failed — use cache (already loaded above)
            isOffline = true
            self.error = nil // don't show error if we have cached data
            if discoveries.isEmpty {
                self.error = "Unable to connect. Check your network."
            }
        }

        isLoading = false
        updateWidgetData()

        // Schedule notifications after loading
        if let ctx = activeContext {
            let allForCtx = discoveries.filter { $0.contextKey == ctx.key }
            let saved = allForCtx.filter { triageStore.state(for: $0.id, in: ctx.key) == .saved }
            let unreviewed = allForCtx.filter { triageStore.state(for: $0.id, in: ctx.key) == .unreviewed }

            NotificationManager.shared.scheduleMorningBriefing(
                contextLabel: ctx.label,
                contextEmoji: ctx.emoji,
                savedCount: saved.count,
                unreviewedCount: unreviewed.count
            )
            NotificationManager.shared.scheduleTripReminder(for: ctx)
        }
    }

    func updateWidgetData() {
        guard let defaults = UserDefaults(suiteName: "group.com.charlie.travel") else { return }
        guard let ctx = activeContext else { return }

        let allForCtx = discoveries.filter { $0.contextKey == ctx.key }
        let saved = allForCtx.filter { triageStore.state(for: $0.id, in: ctx.key) == .saved }
        let unreviewed = allForCtx.filter { triageStore.state(for: $0.id, in: ctx.key) == .unreviewed }

        defaults.set(ctx.label, forKey: "widget.contextLabel")
        defaults.set(ctx.emoji, forKey: "widget.contextEmoji")
        defaults.set(saved.count, forKey: "widget.savedCount")
        defaults.set(unreviewed.count, forKey: "widget.unreviewedCount")
        defaults.set(saved.prefix(3).map(\.name), forKey: "widget.topPlaces")
        defaults.set(saved.first?.name, forKey: "widget.nextPlaceName")
        defaults.set(saved.first?.type.rawValue, forKey: "widget.nextPlaceType")

        WidgetCenter.shared.reloadAllTimelines()
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
            updateWidgetData()
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
        let c = city?.lowercased() ?? ""
        switch true {
        case c.contains("new york") || c.contains("nyc") || c.contains("brooklyn") || c.contains("manhattan"):
            // Center on Brooklyn for that neighbourhood feel
            return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 40.6782, longitude: -73.9442), latitudinalMeters: 18000, longitudinalMeters: 18000)
        case c.contains("boston"):
            return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 42.3601, longitude: -71.0589), latitudinalMeters: 12000, longitudinalMeters: 12000)
        case c.contains("toronto"):
            return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 43.6532, longitude: -79.3832), latitudinalMeters: 15000, longitudinalMeters: 15000)
        case c.contains("london"):
            return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278), latitudinalMeters: 20000, longitudinalMeters: 20000)
        case c.contains("paris"):
            return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522), latitudinalMeters: 15000, longitudinalMeters: 15000)
        case c.contains("los angeles") || c.contains("la"):
            return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437), latitudinalMeters: 25000, longitudinalMeters: 25000)
        case c.contains("chicago"):
            return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 41.8781, longitude: -87.6298), latitudinalMeters: 20000, longitudinalMeters: 20000)
        case c.contains("san francisco") || c.contains("sf"):
            return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), latitudinalMeters: 12000, longitudinalMeters: 12000)
        default:
            // Fallback to Toronto if completely unknown
            return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 43.6532, longitude: -79.3832), latitudinalMeters: 30000, longitudinalMeters: 30000)
        }
    }
}