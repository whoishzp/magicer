import Foundation

/// Writes ONE's CursorGood MCP entry to ~/.cursor/mcp.json.
/// Round 3 will replace auto-registration with manual "Install Skill" button.
enum CGMcpRegister {

    static func register(port: UInt16) {
        let mcpPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".cursor/mcp.json")

        var root: [String: Any] = [:]
        if let data = try? Data(contentsOf: mcpPath),
           let existing = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            root = existing
        }

        var servers = root["mcpServers"] as? [String: Any] ?? [:]
        servers["user-cursor-good"] = ["url": "http://127.0.0.1:\(port)/mcp"]
        root["mcpServers"] = servers

        if let data = try? JSONSerialization.data(withJSONObject: root,
                                                   options: [.prettyPrinted, .sortedKeys]) {
            try? data.write(to: mcpPath)
            NSLog("[CGMcpRegister] Registered ONE CursorGood at port \(port)")
        }
    }
}
