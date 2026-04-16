import Foundation

/// Result of running one startup command (manual run uses this for UI feedback only; not persisted).
struct StartupCommandRunOutcome {
    let label: String
    let commandPreview: String
    let success: Bool
    let exitCode: Int?
    let errorDetail: String?
}

/// Executes all enabled startup commands on app launch, and ad-hoc runs from settings.
enum StartupCommandRunner {
    static func run() {
        let commands = AppSettings.shared.startupCommands.filter { $0.isEnabled }
        guard !commands.isEmpty else { return }

        for cmd in commands {
            execute(label: cmd.label, command: cmd.command, finished: nil)
        }
    }

    /// Runs one command immediately (e.g. from settings). Optional main-thread callback with outcome.
    static func runNow(_ cmd: StartupCommand, finished: ((StartupCommandRunOutcome) -> Void)? = nil) {
        execute(label: cmd.label, command: cmd.command, finished: finished)
    }

    private static func execute(
        label: String,
        command: String,
        finished: ((StartupCommandRunOutcome) -> Void)?
    ) {
        let preview = String(command.prefix(200))

        DispatchQueue.global(qos: .utility).async {
            let outcome: StartupCommandRunOutcome
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
                outcome = StartupCommandRunOutcome(
                    label: label,
                    commandPreview: preview,
                    success: ok,
                    exitCode: Int(code),
                    errorDetail: ok ? nil : "退出码 \(code)"
                )
                if !ok {
                    NSLog("[Magicer] Startup command '\(label)' exited with status \(code)")
                }
            } catch {
                NSLog("[Magicer] Startup command '\(label)' failed: \(error)")
                outcome = StartupCommandRunOutcome(
                    label: label,
                    commandPreview: preview,
                    success: false,
                    exitCode: nil,
                    errorDetail: error.localizedDescription
                )
            }

            if let finished = finished {
                DispatchQueue.main.async { finished(outcome) }
            }
        }
    }
}
