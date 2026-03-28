import Foundation

struct Discovery: Codable, Identifiable {
    let id: String
    let name: String
    let type: DiscoveryType
    let contextKey: String
    let placeId: String?
    let heroImage: String?
    let address: String?
    let rating: Double?
    let lat: Double?
    let lng: Double?
}

enum DiscoveryType: String, Codable {
    case restaurant
    case bar
    case cafe
    case gallery
    case museum
    case theatre
    case accommodation
    case other
}
