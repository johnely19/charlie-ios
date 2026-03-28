import Foundation
import Security

final class AuthManager {
    static let shared = AuthManager()

    private let keychainService = "com.charlie.travel"
    private let tokenKey = "authToken"

    private init() {}

    // TODO: Implement token auth with Keychain storage
}
