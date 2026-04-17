import Foundation

/// Runs `/bin/sh -c` for script-type reminder rules and appends output to a per-rule log file.
enum ScheduledScriptExecutor {

    static func run(rule: ReminderRule) {
        guard rule.actionKind == .script else { return }
        let cmd = rule.shellCommand.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cmd.isEmpty else {
            NSLog("[Magicer] Script rule '\(rule.name)' has empty command; skip.")
            return
        }

        DispatchQueue.global(qos: .utility).async {
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/bin/sh")
            task.arguments = ["-c", cmd]

            let outPipe = Pipe()
            let errPipe = Pipe()
            task.standardOutput = outPipe
            task.standardError = errPipe

            let started = Date()
            do {
                try task.run()
                task.waitUntilExit()
                let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
                let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
                let outStr = String(data: outData, encoding: .utf8) ?? ""
                let errStr = String(data: errData, encoding: .utf8) ?? ""
                let code = task.terminationStatus

                if !rule.logDirectoryPath.isEmpty {
                    let expanded = (rule.logDirectoryPath as NSString).expandingTildeInPath
                    let dirURL = URL(fileURLWithPath: expanded, isDirectory: true)
                    do {
                        try FileManager.default.createDirectory(at: dirURL, withIntermediateDirectories: true)
                        let logURL = dirURL.appendingPathComponent("magicer-\(rule.id.uuidString).log")
                        try append(
                            to: logURL,
                            ruleName: rule.name,
                            started: started,
                            exitCode: Int(code),
                            stdout: outStr,
                            stderr: errStr
                        )
                    } catch {
                        NSLog("[Magicer] Script log write failed for '\(rule.name)': \(error)")
                    }
                } else if code != 0 {
                    NSLog("[Magicer] Script '\(rule.name)' exited \(code)")
                }
            } catch {
                NSLog("[Magicer] Script rule '\(rule.name)' failed: \(error)")
            }
        }
    }

    private static func append(
        to url: URL,
        ruleName: String,
        started: Date,
        exitCode: Int,
        stdout: String,
        stderr: String
    ) throws {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime]

        var chunk = ""
        chunk += "\n---------- \(iso.string(from: started)) · \(ruleName) ----------\n"
        chunk += "exit: \(exitCode)\n"
        chunk += "--- stdout ---\n"
        chunk += stdout.isEmpty ? "(empty)\n" : stdout
        if !stdout.hasSuffix("\n") { chunk += "\n" }
        chunk += "--- stderr ---\n"
        chunk += stderr.isEmpty ? "(empty)\n" : stderr
        if !stderr.hasSuffix("\n") { chunk += "\n" }

        let data = chunk.data(using: .utf8) ?? Data()
        if FileManager.default.fileExists(atPath: url.path) {
            let fh = try FileHandle(forWritingTo: url)
            defer { try? fh.close() }
            try fh.seekToEnd()
            try fh.write(contentsOf: data)
        } else {
            try data.write(to: url, options: .atomic)
        }
    }
}
