import Foundation

enum TriageState: String, Codable {
    case unreviewed
    case saved
    case dismissed
    case resurfaced
}

struct TriageEntry: Codable {
    let state: TriageState
    let updatedAt: Date
    let contextKey: String
}
