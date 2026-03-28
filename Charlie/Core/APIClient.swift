import Foundation

enum APIError: Error, LocalizedError {
    case unauthorized
    case notFound
    case serverError(Int)
    case decodingError(Error)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Unauthorized"
        case .notFound:
            return "Not found"
        case .serverError(let code):
            return "Server error: \(code)"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

struct AuthResponse: Codable {
    let token: String
    let userId: String
    let name: String
}

actor APIClient {
    static let shared = APIClient()
    private let baseURL = URL(string: "https://compass-v2-lake.vercel.app")!

    private var token: String?

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()

    private init() {
        token = AuthManager.shared.loadToken()
    }

    func setToken(_ token: String) {
        self.token = token
        AuthManager.shared.saveToken(token)
    }

    // MARK: - Auth

    func authenticate(code: String) async throws -> AuthResponse {
        let url = baseURL.appendingPathComponent("api/auth/token")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["code": code]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)

        do {
            return try decoder.decode(AuthResponse.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    // MARK: - Data

    func discoveries() async throws -> [Discovery] {
        let url = baseURL.appendingPathComponent("discoveries")
        let request = try authorizedRequest(url: url, method: "GET")

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)

        do {
            return try decoder.decode([Discovery].self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    func manifest() async throws -> UserManifest {
        let url = baseURL.appendingPathComponent("manifest")
        let request = try authorizedRequest(url: url, method: "GET")

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)

        do {
            return try decoder.decode(UserManifest.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    func triageEntries() async throws -> [TriageEntry] {
        let url = baseURL.appendingPathComponent("triage")
        let request = try authorizedRequest(url: url, method: "GET")

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)

        do {
            return try decoder.decode([TriageEntry].self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    func setTriage(discoveryId: String, contextKey: String, state: TriageState) async throws {
        let url = baseURL.appendingPathComponent("triage")
        var request = try authorizedRequest(url: url, method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "discoveryId": discoveryId,
            "contextKey": contextKey,
            "state": state.rawValue
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
    }

    // MARK: - Chat (streaming)

    func chat(message: String, contextKey: String?) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    var urlComponents = URLComponents(url: self.baseURL.appendingPathComponent("chat"), resolvingAgainstBaseURL: false)
                    if let contextKey = contextKey {
                        urlComponents?.queryItems = [URLQueryItem(name: "contextKey", value: contextKey)]
                    }
                    guard let url = urlComponents?.url else {
                        continuation.finish(throwing: APIError.networkError(URLError(.badURL)))
                        return
                    }

                    var request = try await self.authorizedRequest(url: url, method: "POST")
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                    let body: [String: Any] = ["message": message]
                    request.httpBody = try? JSONSerialization.data(withJSONObject: body)

                    let (bytes, response) = try await URLSession.shared.bytes(for: request)
                    try self.validateResponse(response)

                    var buffer = Data()
                    for try await line in bytes.lines {
                        buffer.append(contentsOf: line.utf8)
                        buffer.append(contentsOf: "\n".utf8)

                        while let newlineRange = buffer.range(of: Data("\n".utf8)) {
                            let eventData = buffer.subdata(in: buffer.startIndex..<newlineRange.lowerBound)
                            buffer = buffer.subdata(in: newlineRange.upperBound..<buffer.endIndex)

                            if let eventString = String(data: eventData, encoding: .utf8),
                               eventString.hasPrefix("data: ") {
                                let data = String(eventString.dropFirst(6))
                                if data == "[DONE]" {
                                    continuation.finish()
                                    return
                                }
                                continuation.yield(data)
                            }
                        }
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: - Context Management

    func createContext(type: ContextType, label: String, emoji: String, city: String?, dates: String?, focus: [String]) async throws {
        struct Body: Codable {
            let type: String
            let label: String
            let emoji: String
            let city: String?
            let dates: String?
            let focus: [String]
        }
        let body = Body(type: type.rawValue, label: label, emoji: emoji, city: city, dates: dates, focus: focus)
        var request = URLRequest(url: baseURL.appendingPathComponent("api/user/manifest/contexts"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = token { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        request.httpBody = try JSONEncoder().encode(body)
        let (_, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, http.statusCode == 404 {
            // Endpoint may not exist yet — fail silently
            return
        }
    }

    func updateContext(key: String, label: String, emoji: String, dates: String?) async throws {
        struct Body: Codable { let label: String; let emoji: String; let dates: String? }
        var request = URLRequest(url: baseURL.appendingPathComponent("api/user/manifest/contexts/\(key)"))
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = token { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        request.httpBody = try JSONEncoder().encode(Body(label: label, emoji: emoji, dates: dates))
        _ = try? await URLSession.shared.data(for: request) // best-effort
    }

    // MARK: - Helpers

    private func authorizedRequest(url: URL, method: String) throws -> URLRequest {
        guard let token = token else {
            throw APIError.unauthorized
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }

    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError(URLError(.badServerResponse))
        }

        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401:
            throw APIError.unauthorized
        case 404:
            throw APIError.notFound
        default:
            throw APIError.serverError(httpResponse.statusCode)
        }
    }
}