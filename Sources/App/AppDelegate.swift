import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private let menuBar = MenuBarManager()
    private var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMainMenu()
        menuBar.onOpenSettings = { [weak self] in self?.openSettings() }
        menuBar.setup()
        RuleTimerManager.shared.start()
        ReminderHTTPServer.shared.start()
        HotkeyManager.shared.start()
        StartupCommandRunner.run()
        // Open Fe助手 panel via global hotkey: bring window first, then switch tab
        NotificationCenter.default.addObserver(
            forName: .openFeHelperPanel, object: nil, queue: .main
        ) { [weak self] notification in
            self?.openSettings()
            // SettingsView will also receive this notification and switch the tab
        }
        openSettings()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        openSettings(); return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        return .terminateNow
    }

    // MARK: - Main Menu

    private func setupMainMenu() {
        let mainMenu = NSMenu()

        // ── App menu ────────────────────────────────────────────────────────
        let appItem = NSMenuItem()
        mainMenu.addItem(appItem)
        let appMenu = NSMenu()
        appItem.submenu = appMenu
        appMenu.addItem(NSMenuItem(
            title: "退出 Magicer",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        ))

        // ── Window menu ─────────────────────────────────────────────────────
        let windowItem = NSMenuItem()
        mainMenu.addItem(windowItem)
        let windowMenu = NSMenu(title: "Window")
        windowItem.submenu = windowMenu
        windowMenu.addItem(NSMenuItem(
            title: "最小化",
            action: #selector(NSWindow.miniaturize(_:)),
            keyEquivalent: "m"
        ))
        windowMenu.addItem(NSMenuItem(
            title: "关闭窗口",
            action: #selector(NSWindow.performClose(_:)),
            keyEquivalent: "w"
        ))

        NSApp.mainMenu = mainMenu
        NSApp.windowsMenu = windowMenu
    }

    // MARK: - Settings Window

    @objc func openSettings() {
        if let w = settingsWindow {
            w.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = HideOnCloseWindow(
            contentRect: NSRect(x: 0, y: 0, width: 860, height: 560),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered, defer: false
        )
        window.title = "Magicer"
        window.collectionBehavior = [.fullScreenPrimary]
        window.toolbarStyle = .unifiedCompact
        window.contentView = NSHostingView(rootView: SettingsView())
        window.center()
        window.setFrameAutosaveName("WorkStopSettings")
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow = window

        NotificationCenter.default.addObserver(
            forName: NSWindow.didUpdateNotification, object: window, queue: .main
        ) { [weak window] _ in
            if window?.title != "Magicer" { window?.title = "Magicer" }
        }
    }
}
