import Foundation

struct Companion: Codable, Identifiable {
    let id: String           // userId
    let name: String
    let avatarEmoji: String? // e.g. "🧡"
}

struct CompanionSave: Codable, Identifiable {
    let id: String           // discoveryId
    let discoveryId: String
    let savedBy: String      // userId
    let savedByName: String
    let contextKey: String
    let savedAt: Date
}

// Extend Context to hold companion info
extension Context {
    var isShared: Bool {
        // Check if context key has companion data in UserDefaults (local flag)
        UserDefaults.standard.bool(forKey: "shared.\(key)")
    }
}