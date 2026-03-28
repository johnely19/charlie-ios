import Foundation

enum TriageState: String, Codable, CaseIterable {
    case unreviewed, saved, dismissed, resurfaced
}

struct TriageEntry: Codable {
    let discoveryId: String
    let state: TriageState
    let updatedAt: Date
    let contextKey: String
}
