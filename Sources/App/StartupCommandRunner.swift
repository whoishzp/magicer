import Foundation

/// Executes all enabled startup commands on app launch, and ad-hoc runs from settings.
enum StartupCommandRunner {
    static func run() {
        let commands = AppSettings.shared.startupCommands.filter { $0.isEnabled }
        guard !commands.isEmpty else { return }

        for cmd in commands {
            runInBackground(label: cmd.label, command: cmd.command)
        }
    }

    /// Runs one command immediately (e.g. from settings “run now”), independent of `isEnabled`.
    static func runNow(_ cmd: StartupCommand) {
        runInBackground(label: cmd.label, command: cmd.command)
    }

    private static func runInBackground(label: String, command: String) {
        DispatchQueue.global(qos: .utility).async {
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/bin/sh")
            task.arguments = ["-c", command]
            task.standardOutput = FileHandle.nullDevice
            task.standardError = FileHandle.nullDevice
            do { try task.run() } catch {
                NSLog("[Magicer] Startup command '\(label)' failed: \(error)")
            }
        }
    }
}
