import Foundation

actor DiskCache {
    static let shared = DiskCache()

    private let cacheDirectory: URL

    private init() {
        let urls = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = urls[0].appendingPathComponent("CharlieCache", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    func save<T: Codable>(_ value: T, key: String) {
        let url = cacheDirectory.appendingPathComponent("\(key).json")
        do {
            let data = try JSONEncoder().encode(value)
            try data.write(to: url, options: .atomic)
        } catch {
            print("[DiskCache] Failed to save \(key): \(error)")
        }
    }

    func load<T: Codable>(_ type: T.Type, key: String) -> T? {
        let url = cacheDirectory.appendingPathComponent("\(key).json")
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    func age(of key: String) -> TimeInterval? {
        let url = cacheDirectory.appendingPathComponent("\(key).json")
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let modified = attrs[.modificationDate] as? Date else { return nil }
        return Date().timeIntervalSince(modified)
    }

    func clear(key: String) {
        let url = cacheDirectory.appendingPathComponent("\(key).json")
        try? FileManager.default.removeItem(at: url)
    }

    func clearAll() {
        try? FileManager.default.removeItem(at: cacheDirectory)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
}