import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private let menuBar = MenuBarManager()
    private var settingsWindow: NSWindow?

    // Cmd+Q press-and-hold tracking
    private var cmdQDownTime: Date?
    private var cmdQDownMonitor: Any?
    private var cmdQUpMonitor: Any?
    /// Hold Cmd+Q for this many seconds to actually quit; shorter press just closes the window.
    private let cmdQQuitThreshold: TimeInterval = 1.5

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMainMenu()
        setupCmdQHandling()
        menuBar.onOpenSettings = { [weak self] in self?.openSettings() }
        menuBar.setup()
        RuleTimerManager.shared.start()
        ReminderHTTPServer.shared.start()
        HotkeyManager.shared.start()
        StartupCommandRunner.run()

        // CursorGood: load sessions, start MCP server, auto-register
        CGSessionManager.shared.loadAll()
        let cgPortRaw = UserDefaults.standard.integer(forKey: "cursorGoodPort")
        let cgPort: UInt16 = cgPortRaw > 0 ? UInt16(cgPortRaw) : 18880
        CGMcpServer.shared.start(port: cgPort)
        CGMcpRegister.register(port: cgPort)
        CGRuleInstaller.installIfNeeded(port: cgPort)

        // Open settings window via Fe助手 hotkey or CursorGood notification
        for name in [Notification.Name.openFeHelperPanel, .openCursorGoodPanel] {
            NotificationCenter.default.addObserver(
                forName: name, object: nil, queue: .main
            ) { [weak self] _ in
                self?.openSettings()
            }
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
        let quitItem = NSMenuItem(
            title: "退出 ONE",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: ""   // no key equivalent — Cmd+Q handled via local monitor
        )
        appMenu.addItem(quitItem)

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

    // MARK: - Cmd+Q Press-and-Hold

    private func setupCmdQHandling() {
        // keyDown: record timestamp, consume event so menu `terminate:` never fires
        cmdQDownMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self,
                  event.keyCode == 12,
                  event.modifierFlags.intersection([.command, .shift, .option, .control]) == .command
            else { return event }
            if event.isARepeat { return nil }   // swallow repeats silently
            self.cmdQDownTime = Date()
            return nil  // consume — prevent default terminate
        }

        // keyUp: decide short vs long press
        cmdQUpMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyUp) { [weak self] event in
            guard let self,
                  event.keyCode == 12,
                  let downTime = self.cmdQDownTime
            else { return event }
            self.cmdQDownTime = nil
            let held = Date().timeIntervalSince(downTime)
            if held >= self.cmdQQuitThreshold {
                NSApp.terminate(nil)
            } else {
                // Short press: close / hide the settings window
                if let w = self.settingsWindow, w.isVisible {
                    w.orderOut(nil)
                }
            }
            return nil
        }
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
        window.title = "ONE"
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
            if window?.title != "ONE" { window?.title = "ONE" }
        }
    }
}
