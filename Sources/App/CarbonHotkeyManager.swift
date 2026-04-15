import Foundation
import CarbonBridge

// Module-level var: lets the C callback reach the Swift singleton without capture.
private var _globalHotkeyDispatch: ((UInt32) -> Void)?

final class CarbonHotkeyManager {
    static let shared = CarbonHotkeyManager()

    private var actions: [UInt32: () -> Void] = [:]
    private var nextID: UInt32 = 1

    private init() {
        _globalHotkeyDispatch = { [weak self] hotkeyID in
            self?.dispatch(hotkeyID)
        }
        // Pass a non-capturing @convention(c) closure – reads a module global, not a local.
        let status = mg_install_hotkey_handler { id in
            _globalHotkeyDispatch?(id)
        }
        if status != 0 {
            NSLog("[CarbonHotkeyManager] InstallApplicationEventHandler failed: %d", status)
        }
    }

    // MARK: - Public API

    @discardableResult
    func register(_ shortcut: OffWorkShortcut, action: @escaping () -> Void) -> UInt32? {
        guard shortcut.hasCarbonSupport, nextID <= 31 else { return nil }
        let id = nextID; nextID += 1
        let handle = mg_register_hotkey(shortcut.keyCode, shortcut.carbonModifiers, id)
        guard handle != 0 else { return nil }
        actions[id] = action
        return id
    }

    func unregister(id: UInt32) {
        mg_unregister_hotkey(id)
        actions.removeValue(forKey: id)
    }

    func unregisterAll() {
        for id in actions.keys { unregister(id: id) }
    }

    // MARK: - Private

    private func dispatch(_ id: UInt32) {
        let action = actions[id]
        DispatchQueue.main.async { action?() }
    }
}
