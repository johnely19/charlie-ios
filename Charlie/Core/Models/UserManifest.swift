import Foundation

struct UserManifest: Codable {
    let userId: String
    let name: String
    let contexts: [Context]
    let activeContextKey: String?
}
