import AppKit
import Combine

extension Notification.Name {
    static let openFeHelperPanel = Notification.Name("magicer.openFeHelperPanel")
}

/// Manages global shortcut registration for off-work toggle and Fe assistant.
///
/// Strategy (in priority order):
///   1. Carbon RegisterEventHotKey — system-wide, no permissions required.
///      Used whenever the shortcut has a valid keyCode (recorded after v1.60.0).
///   2. NSEvent local monitor — fires when Magicer is frontmost.
///      Always installed as a fallback / supplement.
///
/// The previous addGlobalMonitorForEvents approach is removed because it requires
/// Input Monitoring permission and is unreliable on macOS 15+.
final class HotkeyManager {
    static let shared = HotkeyManager()

    private var offWorkCarbonID:  UInt32?
    private var feHelperCarbonID: UInt32?

    private var offWorkLocalMonitor:  Any?
    private var feHelperLocalMonitor: Any?

    private var cancellables = Set<AnyCancellable>()

    /// True while a ShortcutRow is in recording mode — prevents local monitors from firing.
    static var isAnyRecording = false

    private init() {}

    func start() {
        AppSettings.shared.$offWorkShortcut
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sc in self?.updateOffWork(sc) }
            .store(in: &cancellables)

        AppSettings.shared.$feHelperShortcut
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sc in self?.updateFeHelper(sc) }
            .store(in: &cancellables)
    }

    // MARK: - Off-work

    private func updateOffWork(_ sc: OffWorkShortcut?) {
        // Unregister previous
        if let id = offWorkCarbonID { CarbonHotkeyManager.shared.unregister(id: id); offWorkCarbonID = nil }
        if let m = offWorkLocalMonitor { NSEvent.removeMonitor(m); offWorkLocalMonitor = nil }

        guard let sc else { return }

        // Carbon global hotkey
        offWorkCarbonID = CarbonHotkeyManager.shared.register(sc) { Self.handleOffWork() }

        // Local monitor (frontmost app fallback)
        offWorkLocalMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard sc.matches(event), !HotkeyManager.isAnyRecording else { return event }
            DispatchQueue.main.async { Self.handleOffWork() }
            return nil
        }
    }

    // MARK: - Fe helper

    private func updateFeHelper(_ sc: OffWorkShortcut?) {
        if let id = feHelperCarbonID { CarbonHotkeyManager.shared.unregister(id: id); feHelperCarbonID = nil }
        if let m = feHelperLocalMonitor { NSEvent.removeMonitor(m); feHelperLocalMonitor = nil }

        guard let sc else { return }

        feHelperCarbonID = CarbonHotkeyManager.shared.register(sc) { Self.handleFeHelper() }

        feHelperLocalMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard sc.matches(event), !HotkeyManager.isAnyRecording else { return event }
            DispatchQueue.main.async { Self.handleFeHelper() }
            return nil
        }
    }

    // MARK: - Actions

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

    // MARK: - Permission query (for UI display only)

    static var hasInputMonitoringPermission: Bool {
        // Carbon hotkeys don't need Input Monitoring; this flag is no longer needed.
        // Kept for potential future use — always return true to hide the warning UI.
        true
    }
}
