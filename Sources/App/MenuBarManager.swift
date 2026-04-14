import AppKit
import ServiceManagement
import SwiftUI

/// Owns the NSStatusItem and builds/rebuilds the menu bar menu.
/// Handles off-work toggles and auto-launch toggling.
final class MenuBarManager: NSObject {
    private var statusItem: NSStatusItem!

    /// Called when the user clicks "打开设置…" from the menu.
    var onOpenSettings: (() -> Void)?

    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let btn = statusItem.button {
            btn.image = NSImage(systemSymbolName: "clock.badge.exclamationmark", accessibilityDescription: "WorkStop")
            btn.image?.isTemplate = true
        }
        rebuildMenu()
    }

    func rebuildMenu() {
        let menu = NSMenu()

        let titleItem = NSMenuItem(title: "WorkStop — 工作提醒", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)
        menu.addItem(.separator())

        menu.addItem(NSMenuItem(title: "打开设置…", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(.separator())

        let isOff = OffWorkManager.shared.isActive
        let offItem = NSMenuItem(
            title: isOff ? "取消下班" : "下班 🌙",
            action: isOff ? #selector(cancelOffWork) : #selector(enterOffWork),
            keyEquivalent: ""
        )
        offItem.tag = 2
        menu.addItem(offItem)
        menu.addItem(.separator())

        let loginItem = NSMenuItem(title: "开机自启", action: #selector(toggleLoginItem), keyEquivalent: "")
        loginItem.state = (SMAppService.mainApp.status == .enabled) ? .on : .off
        loginItem.tag = 1
        menu.addItem(loginItem)

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "退出 WorkStop", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        // NSMenu requires a target for @objc actions
        menu.items.forEach { $0.target = self }
        statusItem.menu = menu
    }

    // MARK: - Actions

    @objc private func openSettings() { onOpenSettings?() }

    @objc private func enterOffWork() {
        OffWorkManager.shared.enter()
        rebuildMenu()
    }

    @objc private func cancelOffWork() {
        OffWorkManager.shared.exit(restore: true)
        rebuildMenu()
    }

    @objc private func toggleLoginItem() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            let alert = NSAlert()
            alert.messageText = "开机自启设置失败：\(error.localizedDescription)"
            alert.runModal()
        }
        if let item = statusItem.menu?.item(withTag: 1) {
            item.state = (SMAppService.mainApp.status == .enabled) ? .on : .off
        }
    }
}
