import Foundation
import Combine

/// App-level settings (password, startup commands, etc.)
class AppSettings: ObservableObject {
    static let shared = AppSettings()

    private let kPassword = "ws_offwork_password"
    private let kStartupCmds = "ws_startup_commands"

    @Published var offWorkPassword: String {
        didSet { UserDefaults.standard.set(offWorkPassword, forKey: kPassword) }
    }

    @Published var startupCommands: [StartupCommand] {
        didSet {
            if let data = try? JSONEncoder().encode(startupCommands) {
                UserDefaults.standard.set(data, forKey: kStartupCmds)
            }
        }
    }

    private init() {
        offWorkPassword = UserDefaults.standard.string(forKey: kPassword) ?? ""
        if let data = UserDefaults.standard.data(forKey: kStartupCmds),
           let cmds = try? JSONDecoder().decode([StartupCommand].self, from: data) {
            startupCommands = cmds
        } else {
            startupCommands = []
        }
    }

    var hasPassword: Bool { !offWorkPassword.isEmpty }
}
