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

/// Codable container for app settings persisted via ONEDataStore.
private struct AppSettingsData: Codable {
    var offWorkPassword: String = ""
    var startupCommands: [StartupCommand] = []
    var offWorkShortcut: OffWorkShortcut?
    var feHelperShortcut: OffWorkShortcut?
    var appearanceMode: String = "system"
}

/// App-level settings (password, startup commands, etc.)
class AppSettings: ObservableObject {
    static let shared = AppSettings()
    private static let filename = "settings.json"

    @Published var offWorkPassword: String { didSet { persist() } }
    @Published var startupCommands: [StartupCommand] { didSet { persist() } }
    @Published var offWorkShortcut: OffWorkShortcut? { didSet { persist() } }
    @Published var feHelperShortcut: OffWorkShortcut? { didSet { persist() } }
    @Published var appearanceMode: AppearanceMode = .system {
        didSet { persist(); NSApp.appearance = appearanceMode.nsAppearance }
    }

    private func persist() {
        let data = AppSettingsData(
            offWorkPassword: offWorkPassword,
            startupCommands: startupCommands,
            offWorkShortcut: offWorkShortcut,
            feHelperShortcut: feHelperShortcut,
            appearanceMode: appearanceMode.rawValue
        )
        ONEDataStore.shared.save(data, to: Self.filename)
    }

    private init() {
        if let saved = ONEDataStore.shared.load(AppSettingsData.self, from: Self.filename) {
            offWorkPassword = saved.offWorkPassword
            startupCommands = saved.startupCommands
            offWorkShortcut = saved.offWorkShortcut
            feHelperShortcut = saved.feHelperShortcut
            appearanceMode = AppearanceMode(rawValue: saved.appearanceMode) ?? .system
        } else {
            // Fallback: migrate from UserDefaults
            offWorkPassword = UserDefaults.standard.string(forKey: "one_offwork_password") ?? ""
            if let d = UserDefaults.standard.data(forKey: "one_startup_commands"),
               let cmds = try? JSONDecoder().decode([StartupCommand].self, from: d) {
                startupCommands = cmds
            } else { startupCommands = [] }
            if let d = UserDefaults.standard.data(forKey: "one_offwork_shortcut"),
               let sc = try? JSONDecoder().decode(OffWorkShortcut.self, from: d) {
                offWorkShortcut = sc
            } else { offWorkShortcut = nil }
            if let d = UserDefaults.standard.data(forKey: "one_fehelper_shortcut"),
               let sc = try? JSONDecoder().decode(OffWorkShortcut.self, from: d) {
                feHelperShortcut = sc
            } else { feHelperShortcut = nil }
            if let raw = UserDefaults.standard.string(forKey: "one_appearance_mode"),
               let mode = AppearanceMode(rawValue: raw) {
                appearanceMode = mode
            }
            persist()
        }
        NSApp.appearance = appearanceMode.nsAppearance
    }

    var hasPassword: Bool { !offWorkPassword.isEmpty }
}
