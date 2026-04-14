import Foundation

/// Executes all enabled startup commands on app launch.
enum StartupCommandRunner {
    static func run() {
        let commands = AppSettings.shared.startupCommands.filter { $0.isEnabled }
        guard !commands.isEmpty else { return }

        for cmd in commands {
            DispatchQueue.global(qos: .utility).async {
                let task = Process()
                task.executableURL = URL(fileURLWithPath: "/bin/sh")
                task.arguments = ["-c", cmd.command]
                task.standardOutput = FileHandle.nullDevice
                task.standardError = FileHandle.nullDevice
                do { try task.run() } catch {
                    NSLog("[Magicer] Startup command '\(cmd.label)' failed: \(error)")
                }
            }
        }
    }
}
