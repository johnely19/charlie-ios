import Foundation
import MapKit
import SwiftUI

@Observable
class RouteOverlayManager {
    var routes: [MKRoute] = []
    var isVisible: Bool = false
    var isLoading: Bool = false
    var error: String? = nil

    /// Build walking routes: accommodation -> each saved discovery, sorted by proximity
    func buildRoutes(from origin: CLLocationCoordinate2D, to destinations: [CLLocationCoordinate2D]) async {
        guard !destinations.isEmpty else { return }
        isLoading = true
        routes = []

        var waypoints = destinations
        // Sort by proximity to origin for a reasonable walking order
        var current = origin
        var sorted: [CLLocationCoordinate2D] = []
        while !waypoints.isEmpty {
            let next = waypoints.min(by: {
                distance(from: current, to: $0) < distance(from: current, to: $1)
            })!
            sorted.append(next)
            waypoints.removeAll { $0.latitude == next.latitude && $0.longitude == next.longitude }
            current = next
        }

        // Build route segments: origin -> first, then each consecutive pair
        var allWaypoints = [origin] + sorted
        var fetchedRoutes: [MKRoute] = []

        for i in 0..<(allWaypoints.count - 1) {
            let from = allWaypoints[i]
            let to = allWaypoints[i + 1]
            if let route = await fetchRoute(from: from, to: to) {
                fetchedRoutes.append(route)
            }
        }

        routes = fetchedRoutes
        isLoading = false
    }

    func clear() {
        routes = []
        isVisible = false
    }

    private func fetchRoute(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) async -> MKRoute? {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: from))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: to))
        request.transportType = .walking

        do {
            let directions = MKDirections(request: request)
            let response = try await directions.calculate()
            return response.routes.first
        } catch {
            return nil
        }
    }

    private func distance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let a = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let b = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return a.distance(from: b)
    }
}