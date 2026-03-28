import Foundation

struct PlaceCard: Codable, Identifiable {
    let id: String
    let name: String
    let type: DiscoveryType
    let address: String?
    let city: String?
    let rating: Double?
    let reviewCount: Int?
    let priceRange: String?
    let heroImage: String?
    let photos: [String]?
    let lat: Double?
    let lng: Double?
    let narrative: NarrativeBlock?
    let hours: HoursData?
    let menu: [MenuSection]?
    let website: String?
    let phone: String?
}

struct NarrativeBlock: Codable {
    let space: String?
    let food: String?
    let vibe: String?
}

struct HoursData: Codable {
    let monday: String?
    let tuesday: String?
    let wednesday: String?
    let thursday: String?
    let friday: String?
    let saturday: String?
    let sunday: String?
}

struct MenuSection: Codable {
    let title: String
    let items: [MenuItem]
}

struct MenuItem: Codable {
    let name: String
    let description: String?
    let price: String?
}
