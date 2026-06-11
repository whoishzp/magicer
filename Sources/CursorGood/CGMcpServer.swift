import Foundation
import Network

/// MCP Streamable HTTP server for the CursorGood module.
/// Listens on 127.0.0.1:{port} and implements the MCP 2025-03-26 protocol.
final class CGMcpServer {
    static let shared = CGMcpServer()

    private var listener: NWListener?
    private(set) var port: UInt16 = 18880

    // MARK: - Start / Stop

    func start(port: UInt16 = 18880) {
        self.port = port
        let params = NWParameters.tcp
        params.allowLocalEndpointReuse = true

        guard let l = try? NWListener(using: params, on: NWEndpoint.Port(rawValue: port)!) else {
            NSLog("[CGMcpServer] Failed to bind port \(port)")
            return
        }
        l.stateUpdateHandler = { state in
            switch state {
            case .ready:   NSLog("[CGMcpServer] Listening on 127.0.0.1:\(port)")
            case .failed(let err): NSLog("[CGMcpServer] Listener failed: \(err)")
            default: break
            }
        }
        l.newConnectionHandler = { [weak self] conn in
            self?.handleConnection(conn)
        }
        l.start(queue: .global(qos: .userInitiated))
        listener = l
    }

    func stop() {
        listener?.cancel()
        listener = nil
    }

    // MARK: - Connection handling

    private func handleConnection(_ conn: NWConnection) {
        conn.start(queue: .global(qos: .userInitiated))
        receiveHTTPRequest(conn: conn)
    }

    private func receiveHTTPRequest(conn: NWConnection, accumulated: Data = Data()) {
        conn.receive(minimumIncompleteLength: 1, maximumLength: 1 << 22) { [weak self] data, _, isComplete, error in
            guard let self = self else { return }
            var buffer = accumulated
            if let data = data { buffer.append(data) }
            // Check if we've received the full HTTP request (headers + body)
            guard let raw = String(data: buffer, encoding: .utf8) else { return }
            if raw.contains("\r\n\r\n") {
                self.processHTTPRequest(raw: raw, conn: conn)
            } else if !isComplete {
                // Need more data
                self.receiveHTTPRequest(conn: conn, accumulated: buffer)
            }
        }
    }

    // MARK: - HTTP parsing & routing

    private func processHTTPRequest(raw: String, conn: NWConnection) {
        let lines = raw.components(separatedBy: "\r\n")
        guard let requestLine = lines.first else { return }
        let parts = requestLine.components(separatedBy: " ")
        guard parts.count >= 2 else { return }
        let method = parts[0]
        let path   = parts[1].components(separatedBy: "?")[0]

        // CORS preflight
        if method == "OPTIONS" {
            send(conn: conn, status: 204, headers: corsHeaders(), body: "")
            return
        }

        // Parse body
        let bodyStart = raw.range(of: "\r\n\r\n")
        let body = bodyStart.map { String(raw[$0.upperBound...]) } ?? ""

        switch (method, path) {
        case ("POST", "/mcp"):
            handleMcpPost(body: body, conn: conn)
        case ("GET", "/mcp"):
            // SSE notification channel — keep-alive
            sendSSEHeaders(conn: conn)
        case ("GET", "/sse"):
            handleLegacySSE(conn: conn)
        case ("POST", "/message"):
            // Legacy: not needed for Cursor 1.0+, return 405
            send(conn: conn, status: 405, headers: corsHeaders(), body: "")
        default:
            send(conn: conn, status: 404, headers: corsHeaders(), body: "Not found")
        }
    }

    // MARK: - MCP POST handler

    private func handleMcpPost(body: String, conn: NWConnection) {
        guard let data = body.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            send(conn: conn, status: 400, headers: corsHeaders(), body: "Bad JSON")
            return
        }

        let method = json["method"] as? String ?? ""
        let id     = json["id"]

        switch method {
        case "initialize":
            let result: [String: Any] = [
                "protocolVersion": "2025-03-26",
                "capabilities": ["tools": [:]],
                "serverInfo": ["name": "ONE-CursorGood", "version": "1.0"]
            ]
            sendJSONRPC(conn: conn, id: id, result: result)

        case "notifications/initialized":
            send(conn: conn, status: 200, headers: corsHeaders(), body: "")

        case "tools/list":
            let tools: [[String: Any]] = [[
                "name": "CursorGood",
                "description": "Send a message to the user via ONE and wait for their reply.",
                "inputSchema": [
                    "type": "object",
                    "required": ["message", "session_id"],
                    "properties": [
                        "message":            ["type": "string", "description": "Message to display to the user"],
                        "predefined_options": ["type": "array", "items": ["type": "string"], "description": "Quick reply buttons"],
                        "session_id":         ["type": "string", "description": "Cursor session ID"],
                        "session_topic":      ["type": "string", "description": "Human-readable session name for the list"]
                    ]
                ]
            ]]
            sendJSONRPC(conn: conn, id: id, result: ["tools": tools])

        case "tools/call":
            let params   = json["params"] as? [String: Any] ?? [:]
            let args     = params["arguments"] as? [String: Any] ?? [:]
            let callId   = "\(id ?? "unknown")"
            let msg      = args["message"] as? String ?? ""
            let opts     = args["predefined_options"] as? [String] ?? []
            let sessId   = args["session_id"] as? String ?? UUID().uuidString
            let sessTopic = args["session_topic"] as? String ?? ""

            // Stream response via SSE to keep connection alive while waiting
            sendSSEHeaders(conn: conn)

            Task { @MainActor in
                let result = await CGSessionManager.shared.promptUser(
                    callId:        callId,
                    sessionId:     sessId,
                    sessionTopic:  sessTopic,
                    message:       msg,
                    options:       opts
                )
                let content: [[String: Any]] = [["type": "text", "text": formatResponse(result)]]
                    + result.images.map { ["type": "image", "data": $0, "mimeType": "image/png"] }
                let rpcResult: [String: Any] = ["content": content, "isError": false]
                let rpc: [String: Any] = ["jsonrpc": "2.0", "id": id as Any, "result": rpcResult]
                if let d = try? JSONSerialization.data(withJSONObject: rpc),
                   let s = String(data: d, encoding: .utf8) {
                    sendSSEEvent(conn: conn, data: s, isLast: true)
                }
            }

        case "ping":
            sendJSONRPC(conn: conn, id: id, result: [:])

        default:
            let err: [String: Any] = ["code": -32601, "message": "Method not found"]
            sendJSONRPCError(conn: conn, id: id, error: err)
        }
    }

    // MARK: - Legacy SSE (not used by Cursor 1.0+, kept for compatibility)

    private func handleLegacySSE(conn: NWConnection) {
        sendSSEHeaders(conn: conn)
        // Just keep alive; not needed for Streamable HTTP clients
    }

    // MARK: - Helpers

    private func formatResponse(_ result: CGFeedbackResult) -> String {
        guard !result.text.isEmpty else {
            return """
            ╔══════════════════════════════════════╗
            ║  ⚠️  EMPTY_FEEDBACK                  ║
            ╚══════════════════════════════════════╝

            用户未输入内容，必须立即再次调用 CursorGood。
            """
        }
        return """
        ╔══════════════════════════════════════╗
        ║  ⚡ USER_INSTRUCTION_RECEIVED         ║
        ╚══════════════════════════════════════╝

        用户输入: \(result.text)
        """
    }

    private func corsHeaders() -> [String: String] {
        // Restrict to localhost origins to prevent cross-site request attacks from browsers.
        // Cursor and other local clients don't rely on CORS for MCP connections.
        [
            "Access-Control-Allow-Origin": "http://localhost",
            "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
            "Access-Control-Allow-Headers": "Content-Type, Accept"
        ]
    }

    private func sendJSONRPC(conn: NWConnection, id: Any?, result: Any) {
        var rpc: [String: Any] = ["jsonrpc": "2.0", "result": result]
        if let i = id { rpc["id"] = i }
        guard let data = try? JSONSerialization.data(withJSONObject: rpc),
              let body = String(data: data, encoding: .utf8) else { return }
        send(conn: conn, status: 200,
             headers: corsHeaders().merging(["Content-Type": "application/json"]) { $1 },
             body: body)
    }

    private func sendJSONRPCError(conn: NWConnection, id: Any?, error: [String: Any]) {
        var rpc: [String: Any] = ["jsonrpc": "2.0", "error": error]
        if let i = id { rpc["id"] = i }
        guard let data = try? JSONSerialization.data(withJSONObject: rpc),
              let body = String(data: data, encoding: .utf8) else { return }
        send(conn: conn, status: 200,
             headers: corsHeaders().merging(["Content-Type": "application/json"]) { $1 },
             body: body)
    }

    private func sendSSEHeaders(conn: NWConnection) {
        var hdrs = corsHeaders()
        hdrs["Content-Type"] = "text/event-stream"
        hdrs["Cache-Control"] = "no-cache"
        hdrs["Connection"] = "keep-alive"
        let header = buildHTTPResponse(status: 200, headers: hdrs, body: nil)
        conn.send(content: header.data(using: .utf8), completion: .idempotent)
    }

    private func sendSSEEvent(conn: NWConnection, data: String, isLast: Bool) {
        let payload = "data: \(data)\n\n"
        let completion: NWConnection.SendCompletion = isLast
            ? .contentProcessed { _ in conn.cancel() }
            : .idempotent
        conn.send(content: payload.data(using: .utf8), completion: completion)
    }

    private func send(conn: NWConnection, status: Int, headers: [String: String], body: String) {
        let response = buildHTTPResponse(status: status, headers: headers, body: body)
        conn.send(content: response.data(using: .utf8), completion: .contentProcessed { _ in conn.cancel() })
    }

    private func buildHTTPResponse(status: Int, headers: [String: String], body: String?) -> String {
        let statusText: String
        switch status {
        case 200: statusText = "OK"
        case 204: statusText = "No Content"
        case 400: statusText = "Bad Request"
        case 404: statusText = "Not Found"
        case 405: statusText = "Method Not Allowed"
        default:  statusText = "Unknown"
        }
        var h = headers
        if let b = body {
            h["Content-Length"] = "\(b.utf8.count)"
            if h["Content-Type"] == nil { h["Content-Type"] = "text/plain; charset=utf-8" }
        }
        let headerLines = h.map { "\($0.key): \($0.value)" }.joined(separator: "\r\n")
        let bodyPart = body.map { "\r\n\r\n\($0)" } ?? "\r\n\r\n"
        return "HTTP/1.1 \(status) \(statusText)\r\n\(headerLines)\(bodyPart)"
    }
}
