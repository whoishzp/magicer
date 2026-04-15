import AppKit
import Combine

extension Notification.Name {
    static let openFeHelperPanel = Notification.Name("magicer.openFeHelperPanel")
}

/// Listens for user-configured global shortcuts.
/// Uses NSEvent.addGlobalMonitorForEvents (fires when the app is NOT frontmost — no Accessibility permission needed).
final class HotkeyManager {
    static let shared = HotkeyManager()

    private var offWorkMonitor:  Any?
    private var feHelperMonitor: Any?
    private var cancellables = Set<AnyCancellable>()

    private init() {}

    func start() {
        AppSettings.shared.$offWorkShortcut
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sc in
                if let m = self?.offWorkMonitor { NSEvent.removeMonitor(m); self?.offWorkMonitor = nil }
                if let sc { self?.offWorkMonitor = Self.makeMonitor(for: sc) { Self.handleOffWork() } }
            }
            .store(in: &cancellables)

        AppSettings.shared.$feHelperShortcut
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sc in
                if let m = self?.feHelperMonitor { NSEvent.removeMonitor(m); self?.feHelperMonitor = nil }
                if let sc { self?.feHelperMonitor = Self.makeMonitor(for: sc) { Self.handleFeHelper() } }
            }
            .store(in: &cancellables)
    }

    // MARK: - Private helpers

    private static func makeMonitor(for shortcut: OffWorkShortcut, action: @escaping () -> Void) -> Any? {
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            guard shortcut.matches(event) else { return }
            DispatchQueue.main.async { action() }
        }
    }

    private static func handleOffWork() {
        if OffWorkManager.shared.isActive {
            OffWorkManager.shared.exit(restore: true)
        } else {
            OffWorkManager.shared.enter()
        }
    }

    private static func handleFeHelper() {
        NotificationCenter.default.post(name: .openFeHelperPanel, object: nil)
    }
}
