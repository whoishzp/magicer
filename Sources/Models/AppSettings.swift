import Foundation
import Combine

/// App-level settings (password, startup commands, etc.)
class AppSettings: ObservableObject {
    static let shared = AppSettings()

    private let kPassword        = "ws_offwork_password"
    private let kStartupCmds    = "ws_startup_commands"
    private let kStartupCmdLogs = "ws_startup_command_logs"
    private let kShortcut        = "magicer_offwork_shortcut"
    private let kFeHelperShortcut = "magicer_fehelper_shortcut"

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

    /// 最近若干条启动/手动执行记录（时间倒序）
    @Published var startupCommandLogs: [StartupCommandLogEntry] {
        didSet {
            if let data = try? JSONEncoder().encode(startupCommandLogs) {
                UserDefaults.standard.set(data, forKey: kStartupCmdLogs)
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

    @Published var feHelperShortcut: OffWorkShortcut? {
        didSet {
            if let s = feHelperShortcut, let data = try? JSONEncoder().encode(s) {
                UserDefaults.standard.set(data, forKey: kFeHelperShortcut)
            } else {
                UserDefaults.standard.removeObject(forKey: kFeHelperShortcut)
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
        if let data = UserDefaults.standard.data(forKey: kStartupCmdLogs),
           let logs = try? JSONDecoder().decode([StartupCommandLogEntry].self, from: data) {
            startupCommandLogs = logs
        } else {
            startupCommandLogs = []
        }
        if let data = UserDefaults.standard.data(forKey: kShortcut),
           let sc = try? JSONDecoder().decode(OffWorkShortcut.self, from: data) {
            offWorkShortcut = sc
        } else {
            offWorkShortcut = nil
        }
        if let data = UserDefaults.standard.data(forKey: kFeHelperShortcut),
           let sc = try? JSONDecoder().decode(OffWorkShortcut.self, from: data) {
            feHelperShortcut = sc
        } else {
            feHelperShortcut = nil
        }
    }

    var hasPassword: Bool { !offWorkPassword.isEmpty }

    private let maxStartupCommandLogs = 50

    func appendStartupCommandLog(_ entry: StartupCommandLogEntry) {
        var next = [entry] + startupCommandLogs
        if next.count > maxStartupCommandLogs {
            next = Array(next.prefix(maxStartupCommandLogs))
        }
        startupCommandLogs = next
    }

    func clearStartupCommandLogs() {
        startupCommandLogs = []
    }
}
