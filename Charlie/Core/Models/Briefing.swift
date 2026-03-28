import Foundation

struct Briefing: Identifiable, Codable {
    let id: String
    let greeting: Greeting
    let contextLabel: String
    let contextEmoji: String
    let totalCount: Int
    let highlights: [BriefingHighlight]
    let timestamp: Date
}

enum Greeting: String, Codable {
    case morning
    case afternoon
    case evening

    static var current: Greeting {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return .morning
        case 12..<17: return .afternoon
        default: return .evening
        }
    }

    var displayText: String {
        switch self {
        case .morning: return "Good morning"
        case .afternoon: return "Good afternoon"
        case .evening: return "Good evening"
        }
    }
}

struct BriefingHighlight: Identifiable, Codable {
    let id: String
    let type: HighlightType
    let count: Int
    let label: String
}

enum HighlightType: String, Codable {
    case new
    case saved
    case surfacing
    case reviewed
}