import Foundation
import Combine

/// App-level settings (password, startup commands, etc.)
class AppSettings: ObservableObject {
    static let shared = AppSettings()

    private let kPassword    = "ws_offwork_password"
    private let kStartupCmds = "ws_startup_commands"
    private let kShortcut    = "magicer_offwork_shortcut"

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

    @Published var offWorkShortcut: OffWorkShortcut? {
        didSet {
            if let s = offWorkShortcut, let data = try? JSONEncoder().encode(s) {
                UserDefaults.standard.set(data, forKey: kShortcut)
            } else {
                UserDefaults.standard.removeObject(forKey: kShortcut)
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
        if let data = UserDefaults.standard.data(forKey: kShortcut),
           let sc = try? JSONDecoder().decode(OffWorkShortcut.self, from: data) {
            offWorkShortcut = sc
        } else {
            offWorkShortcut = nil
        }
    }

    var hasPassword: Bool { !offWorkPassword.isEmpty }
}
