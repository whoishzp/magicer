import Foundation

/// Centralized file-based data store for all ONE app persistence.
/// All modules MUST use this class for data storage instead of UserDefaults.
/// Data directory: `~/.one/data/`
/// GitHub Sync module syncs this entire directory.
class ONEDataStore {
    static let shared = ONEDataStore()

    let dataDir: URL

    private let fm = FileManager.default
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        e.dateEncodingStrategy = .iso8601
        return e
    }()
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private init() {
        dataDir = fm.homeDirectoryForCurrentUser
            .appendingPathComponent(".one/data", isDirectory: true)
        try? fm.createDirectory(at: dataDir, withIntermediateDirectories: true)
    }

    // MARK: - JSON file operations

    func save<T: Encodable>(_ value: T, to filename: String) {
        let url = dataDir.appendingPathComponent(filename)
        guard let data = try? encoder.encode(value) else { return }
        try? data.write(to: url, options: .atomic)
    }

    func load<T: Decodable>(_ type: T.Type, from filename: String) -> T? {
        let url = dataDir.appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? decoder.decode(type, from: data)
    }

    // MARK: - Raw data operations

    func saveRaw(_ data: Data, to filename: String) {
        let url = dataDir.appendingPathComponent(filename)
        try? data.write(to: url, options: .atomic)
    }

    func loadRaw(from filename: String) -> Data? {
        let url = dataDir.appendingPathComponent(filename)
        return try? Data(contentsOf: url)
    }

    func remove(filename: String) {
        let url = dataDir.appendingPathComponent(filename)
        try? fm.removeItem(at: url)
    }

    func exists(filename: String) -> Bool {
        fm.fileExists(atPath: dataDir.appendingPathComponent(filename).path)
    }

    // MARK: - Subdirectory operations

    func subdirectory(_ name: String) -> URL {
        let url = dataDir.appendingPathComponent(name, isDirectory: true)
        try? fm.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    func listFiles(in subdirectory: String, extension ext: String? = nil) -> [URL] {
        let dir = dataDir.appendingPathComponent(subdirectory, isDirectory: true)
        guard let files = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else {
            return []
        }
        if let ext = ext {
            return files.filter { $0.pathExtension == ext }
        }
        return files
    }

    // MARK: - Scalar helpers

    func saveString(_ value: String, forKey key: String, in filename: String = "kv.json") {
        var dict = load([String: String].self, from: filename) ?? [:]
        dict[key] = value
        save(dict, to: filename)
    }

    func loadString(forKey key: String, from filename: String = "kv.json") -> String? {
        load([String: String].self, from: filename)?[key]
    }

    func saveDouble(_ value: Double, forKey key: String, in filename: String = "kv.json") {
        var dict = load([String: Double].self, from: filename) ?? [:]
        dict[key] = value
        save(dict, to: filename)
    }

    func loadDouble(forKey key: String, from filename: String = "kv.json") -> Double {
        load([String: Double].self, from: filename)?[key] ?? 0
    }
}
