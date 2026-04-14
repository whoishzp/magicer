import Foundation
import Darwin

/// Minimal POSIX socket HTTP server that exposes reminder rules to local AI agents.
/// Listens on 127.0.0.1:18879. Only accepts connections from localhost.
final class ReminderHTTPServer {
    static let shared = ReminderHTTPServer()
    let port: UInt16 = 18879
    private var serverFd: Int32 = -1

    private init() {}

    func start() {
        DispatchQueue.global(qos: .utility).async { self.runLoop() }
    }

    // MARK: - Socket loop

    private func runLoop() {
        serverFd = socket(AF_INET, SOCK_STREAM, 0)
        guard serverFd >= 0 else { return }

        var reuse: Int32 = 1
        setsockopt(serverFd, SOL_SOCKET, SO_REUSEADDR, &reuse, socklen_t(MemoryLayout<Int32>.size))

        var addr = sockaddr_in()
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = port.bigEndian
        inet_pton(AF_INET, "127.0.0.1", &addr.sin_addr)

        let bindResult = withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                Darwin.bind(serverFd, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        guard bindResult == 0 else { Darwin.close(serverFd); return }
        guard Darwin.listen(serverFd, 8) == 0 else { Darwin.close(serverFd); return }

        while true {
            let clientFd = Darwin.accept(serverFd, nil, nil)
            guard clientFd >= 0 else { break }
            DispatchQueue.global(qos: .utility).async { self.handleClient(clientFd) }
        }
    }

    // MARK: - Request handling

    private func handleClient(_ fd: Int32) {
        defer { Darwin.close(fd) }

        var buf = [UInt8](repeating: 0, count: 32768)
        let n = Darwin.recv(fd, &buf, buf.count - 1, 0)
        guard n > 0 else { return }

        let raw = String(bytes: buf.prefix(n), encoding: .utf8) ?? ""
        let lines = raw.components(separatedBy: "\r\n")
        guard let requestLine = lines.first else { return }
        let parts = requestLine.split(separator: " ").map(String.init)
        guard parts.count >= 2 else { return }

        let method = parts[0]
        let fullPath = parts[1]
        let path = fullPath.components(separatedBy: "?").first ?? fullPath

        let body: String
        if let range = raw.range(of: "\r\n\r\n") {
            body = String(raw[range.upperBound...])
        } else {
            body = ""
        }

        let (status, json) = route(method: method, path: path, body: body)
        let response = httpResponse(status: status, body: json)
        response.withCString { ptr in _ = Darwin.send(fd, ptr, strlen(ptr), 0) }
    }

    // MARK: - Router

    private func route(method: String, path: String, body: String) -> (Int, String) {
        let segments = path.split(separator: "/").map(String.init)

        switch (method, segments) {
        case ("GET", ["reminders"]):
            var result = ""
            DispatchQueue.main.sync {
                result = encodeRules(RulesStore.shared.rules)
            }
            return (200, result)

        case ("POST", ["reminders"]):
            guard let data = body.data(using: .utf8),
                  let rule = decodeRule(data) else {
                return (400, "{\"error\":\"invalid body\"}")
            }
            DispatchQueue.main.async { RulesStore.shared.rules.append(rule) }
            return (201, encodeRule(rule))

        case ("PUT", ["reminders", let id]):
            guard UUID(uuidString: id) != nil,
                  let data = body.data(using: .utf8),
                  let updated = decodeRule(data) else {
                return (400, "{\"error\":\"invalid\"}")
            }
            DispatchQueue.main.async { RulesStore.shared.updateRule(updated) }
            return (200, "{\"ok\":true}")

        case ("PUT", ["reminders", let id, "toggle"]):
            guard let uuid = UUID(uuidString: id) else {
                return (400, "{\"error\":\"invalid id\"}")
            }
            DispatchQueue.main.async {
                if let idx = RulesStore.shared.rules.firstIndex(where: { $0.id == uuid }) {
                    RulesStore.shared.rules[idx].isEnabled.toggle()
                }
            }
            return (200, "{\"ok\":true}")

        case ("DELETE", ["reminders", let id]):
            guard let uuid = UUID(uuidString: id) else {
                return (400, "{\"error\":\"invalid id\"}")
            }
            DispatchQueue.main.async {
                let offsets = IndexSet(
                    RulesStore.shared.rules.indices.filter { RulesStore.shared.rules[$0].id == uuid }
                )
                RulesStore.shared.deleteRules(at: offsets)
            }
            return (200, "{\"ok\":true}")

        default:
            return (404, "{\"error\":\"not found\"}")
        }
    }

    // MARK: - Codec helpers (ISO8601 for cross-language interop)

    private func makeEncoder() -> JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = .prettyPrinted
        return e
    }

    private func makeDecoder() -> JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }

    private func encodeRules(_ rules: [ReminderRule]) -> String {
        (try? String(data: makeEncoder().encode(rules), encoding: .utf8)) ?? "[]"
    }

    private func encodeRule(_ rule: ReminderRule) -> String {
        (try? String(data: makeEncoder().encode(rule), encoding: .utf8)) ?? "{}"
    }

    private func decodeRule(_ data: Data) -> ReminderRule? {
        try? makeDecoder().decode(ReminderRule.self, from: data)
    }

    // MARK: - Response builder

    private func httpResponse(status: Int, body: String) -> String {
        let bodyBytes = body.utf8.count
        return """
        HTTP/1.1 \(status) OK\r
        Content-Type: application/json\r
        Content-Length: \(bodyBytes)\r
        Access-Control-Allow-Origin: *\r
        \r
        \(body)
        """
    }
}
