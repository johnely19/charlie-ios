import Foundation
import CoreLocation

struct Discovery: Codable, Identifiable {
    let id: String
    let name: String
    let type: DiscoveryType
    let contextKey: String
    let placeId: String?
    let heroImage: String?
    let address: String?
    let city: String?
    let rating: Double?
    let lat: Double?
    let lng: Double?
    let summary: String?
    let source: String?
    let pricePerWeek: Double?
    let bedrooms: Int?
    let swimQuality: String?
    let amenities: [String]?
    let julyAvailable: Bool?
    let listingUrl: String?
    let matchScore: Double?
    let driveFromToronto: String?

    var coordinate: CLLocationCoordinate2D? {
        guard let lat, let lng else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }

    var heroImageURL: URL? {
        guard let heroImage else { return nil }
        if heroImage.hasPrefix("http") {
            return URL(string: heroImage)
        }
        return URL(string: "https://compass-v2-lake.vercel.app" + heroImage)
    }

    // Deep link: charlie://placecards/{place_id}
    // Fallback: compass web URL
    var shareURL: URL {
        if let placeId = placeId {
            return URL(string: "https://compass-v2-lake.vercel.app/placecards/\(placeId)")
                ?? URL(string: "https://compass-v2-lake.vercel.app")!
        }
        return URL(string: "https://compass-v2-lake.vercel.app")!
    }

    var shareText: String {
        var text = "📍 \(name)"
        if let address = address { text += "\n\(address)" }
        if let rating = rating { text += "\n⭐️ \(String(format: "%.1f", rating))" }
        text += "\n\nvia Charlie"
        return text
    }
}

enum DiscoveryType: String, Codable {
    case restaurant, bar, cafe, gallery, museum, theatre
    case musicVenue = "music-venue"
    case grocery, shop, park, architecture, development
    case accommodation, neighbourhood, experience, hotel
    case unknown
}

extension Discovery: Hashable, Equatable {
    static func == (lhs: Discovery, rhs: Discovery) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
