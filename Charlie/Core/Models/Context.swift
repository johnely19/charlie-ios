import Foundation

struct Context: Codable, Identifiable {
    let key: String
    let label: String
    let emoji: String
    let type: ContextType
    let city: String?
    let dates: String?
    let active: Bool

    var id: String { key }
}

enum ContextType: String, Codable {
    case trip
    case outing
    case radar
}
