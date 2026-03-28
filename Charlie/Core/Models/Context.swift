import Foundation

struct Context: Codable, Identifiable {
    let key: String
    let label: String
    let emoji: String
    let type: ContextType
    let city: String?
    let dates: String?
    let active: Bool
    let focus: [String]?
    let travel: TravelData?
    let accommodation: AccommodationInfo?

    var id: String { key }
}

enum ContextType: String, Codable {
    case trip, outing, radar
}

struct TravelData: Codable {
    let outbound: FlightInfo?
    let return: FlightInfo?
}

struct FlightInfo: Codable {
    let flight: String?
    let departs: String?
    let arrives: String?
    let from: String?
    let to: String?
}

struct AccommodationInfo: Codable {
    let name: String
    let address: String?
    let lat: Double?
    let lng: Double?
}
