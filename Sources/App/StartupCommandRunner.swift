import Foundation

/// Executes all enabled startup commands on app launch, and ad-hoc runs from settings.
enum StartupCommandRunner {
    static func run() {
        let commands = AppSettings.shared.startupCommands.filter { $0.isEnabled }
        guard !commands.isEmpty else { return }

        for cmd in commands {
            execute(label: cmd.label, command: cmd.command, source: .startup, finished: nil)
        }
    }

    /// Runs one command immediately (e.g. from settings). Records log + optional main-thread callback.
    static func runNow(_ cmd: StartupCommand, finished: ((StartupCommandLogEntry) -> Void)? = nil) {
        execute(label: cmd.label, command: cmd.command, source: .manual, finished: finished)
    }

    private static func execute(
        label: String,
        command: String,
        source: StartupCommandRunSource,
        finished: ((StartupCommandLogEntry) -> Void)?
    ) {
        let preview = String(command.prefix(200))

        DispatchQueue.global(qos: .utility).async {
            let entry: StartupCommandLogEntry
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/bin/sh")
            task.arguments = ["-c", command]
            task.standardOutput = FileHandle.nullDevice
            task.standardError = FileHandle.nullDevice

            do {
                try task.run()
                task.waitUntilExit()
                let code = task.terminationStatus
                let ok = code == 0
                entry = StartupCommandLogEntry(
                    date: Date(),
                    label: label,
                    commandPreview: preview,
                    source: source,
                    success: ok,
                    exitCode: Int(code),
                    errorDetail: ok ? nil : "退出码 \(code)"
                )
            } catch {
                NSLog("[Magicer] Startup command '\(label)' failed: \(error)")
                entry = StartupCommandLogEntry(
                    date: Date(),
                    label: label,
                    commandPreview: preview,
                    source: source,
                    success: false,
                    exitCode: nil,
                    errorDetail: error.localizedDescription
                )
            }

            DispatchQueue.main.async {
                AppSettings.shared.appendStartupCommandLog(entry)
                finished?(entry)
            }
        }
    }
}
