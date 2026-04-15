import AppKit
import CoreGraphics
import Combine

extension Notification.Name {
    static let openFeHelperPanel = Notification.Name("magicer.openFeHelperPanel")
}

/// Listens for user-configured global shortcuts.
/// Registers BOTH a global monitor (app in background) and a local monitor (app in foreground).
/// Global monitor requires Input Monitoring permission; local monitor works without any permission.
final class HotkeyManager {
    static let shared = HotkeyManager()

    private var offWorkMonitors:  [Any?] = []
    private var feHelperMonitors: [Any?] = []
    private var cancellables = Set<AnyCancellable>()

    /// Set to true while a shortcut is being recorded to prevent accidental trigger.
    static var isAnyRecording = false

    private init() {}

    func start() {
        // Request Input Monitoring permission so global monitor fires when app is in background.
        // CGPreflightListenEventAccess() returns false without permission;
        // CGRequestListenEventAccess() shows the system-level permission dialog once.
        if !CGPreflightListenEventAccess() {
            CGRequestListenEventAccess()
        }

        AppSettings.shared.$offWorkShortcut
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sc in
                self?.removeMonitors(&(self!.offWorkMonitors))
                if let sc { self?.offWorkMonitors = Self.makeMonitors(for: sc) { Self.handleOffWork() } }
            }
            .store(in: &cancellables)

        AppSettings.shared.$feHelperShortcut
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sc in
                self?.removeMonitors(&(self!.feHelperMonitors))
                if let sc { self?.feHelperMonitors = Self.makeMonitors(for: sc) { Self.handleFeHelper() } }
            }
            .store(in: &cancellables)
    }

    // MARK: - Private helpers

    private static func makeMonitors(for shortcut: OffWorkShortcut, action: @escaping () -> Void) -> [Any?] {
        // Global: fires when app is NOT frontmost (requires Input Monitoring permission)
        let global = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            guard shortcut.matches(event) else { return }
            DispatchQueue.main.async { action() }
        }

        // Local: fires when app IS frontmost — skip if user is in shortcut recording mode
        let local = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard shortcut.matches(event), !HotkeyManager.isAnyRecording else { return event }
            DispatchQueue.main.async { action() }
            return nil // consume so it doesn't propagate
        }

        return [global, local]
    }

    private func removeMonitors(_ monitors: inout [Any?]) {
        monitors.forEach { if let m = $0 { NSEvent.removeMonitor(m) } }
        monitors.removeAll()
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

    // MARK: - Permission query (for UI display)

    static var hasInputMonitoringPermission: Bool {
        CGPreflightListenEventAccess()
    }

    static func requestInputMonitoringPermission() {
        CGRequestListenEventAccess()
    }

    static func openInputMonitoringSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent") {
            NSWorkspace.shared.open(url)
        }
    }
}
