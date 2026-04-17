import Foundation
import Combine
import AppKit

// MARK: - AppearanceMode

enum AppearanceMode: String, CaseIterable, Codable {
    case system = "system"
    case light  = "light"
    case dark   = "dark"

    var displayName: String {
        switch self {
        case .system: return "跟随系统"
        case .light:  return "浅色"
        case .dark:   return "深色"
        }
    }

    var nsAppearance: NSAppearance? {
        switch self {
        case .system: return nil
        case .light:  return NSAppearance(named: .aqua)
        case .dark:   return NSAppearance(named: .darkAqua)
        }
    }
}

/// App-level settings (password, startup commands, etc.)
class AppSettings: ObservableObject {
    static let shared = AppSettings()

    private let kPassword        = "ws_offwork_password"
    private let kStartupCmds    = "ws_startup_commands"
    private let kShortcut        = "magicer_offwork_shortcut"
    private let kFeHelperShortcut = "magicer_fehelper_shortcut"
    private let kAppearanceMode  = "magicer_appearance_mode"

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

    @Published var feHelperShortcut: OffWorkShortcut? {
        didSet {
            if let s = feHelperShortcut, let data = try? JSONEncoder().encode(s) {
                UserDefaults.standard.set(data, forKey: kFeHelperShortcut)
            } else {
                UserDefaults.standard.removeObject(forKey: kFeHelperShortcut)
            }
        }
    }

    @Published var appearanceMode: AppearanceMode = .system {
        didSet {
            UserDefaults.standard.set(appearanceMode.rawValue, forKey: kAppearanceMode)
            NSApp.appearance = appearanceMode.nsAppearance
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
        // v1.62 及更早版本曾持久化执行记录，已不再使用
        UserDefaults.standard.removeObject(forKey: "ws_startup_command_logs")
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
        if let raw = UserDefaults.standard.string(forKey: kAppearanceMode),
           let mode = AppearanceMode(rawValue: raw) {
            appearanceMode = mode
        }
        NSApp.appearance = appearanceMode.nsAppearance
    }

    var hasPassword: Bool { !offWorkPassword.isEmpty }
}
