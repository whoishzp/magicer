import AppKit
import Combine

/// Listens for the user-configured off-work global shortcut.
/// Uses NSEvent.addGlobalMonitorForEvents (fires when the app is NOT frontmost).
/// No Accessibility permission is required to receive (non-consuming) key-down events.
final class HotkeyManager {
    static let shared = HotkeyManager()

    private var globalMonitor: Any?
    private var cancellable: AnyCancellable?

    private init() {}

    func start() {
        cancellable = AppSettings.shared.$offWorkShortcut
            .receive(on: DispatchQueue.main)
            .sink { [weak self] shortcut in
                self?.unregister()
                if let shortcut { self?.register(shortcut) }
            }
    }

    private func register(_ shortcut: OffWorkShortcut) {
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            guard shortcut.matches(event) else { return }
            DispatchQueue.main.async {
                if OffWorkManager.shared.isActive {
                    OffWorkManager.shared.exit(restore: true)
                } else {
                    OffWorkManager.shared.enter()
                }
            }
        }
    }

    private func unregister() {
        if let m = globalMonitor { NSEvent.removeMonitor(m); globalMonitor = nil }
    }
}
