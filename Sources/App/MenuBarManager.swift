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
            let img = NSImage(systemSymbolName: "clock.badge.exclamationmark",
                              accessibilityDescription: "Magicer") ?? NSImage(systemSymbolName: "clock", accessibilityDescription: "Magicer")
            img?.isTemplate = true
            btn.image = img
            // Also respond to direct left-click to open settings
            btn.action = #selector(handleStatusClick(_:))
            btn.target = self
            btn.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        statusItem.isVisible = true
        setupEditMenu()
        rebuildMenu()
    }

    @objc private func handleStatusClick(_ sender: NSStatusBarButton) {
        if let event = NSApp.currentEvent, event.type == .rightMouseUp {
            statusItem.menu = buildContextMenu()
            statusItem.button?.performClick(nil)
            statusItem.menu = nil
        } else {
            onOpenSettings?()
        }
    }

    private func buildContextMenu() -> NSMenu {
        let menu = NSMenu()
        let titleItem = NSMenuItem(title: "Magicer — 工作提醒", action: nil, keyEquivalent: "")
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
        menu.addItem(offItem)
        menu.addItem(.separator())
        let loginItem = NSMenuItem(title: "开机自启", action: #selector(toggleLoginItem), keyEquivalent: "")
        loginItem.state = (SMAppService.mainApp.status == .enabled) ? .on : .off
        menu.addItem(loginItem)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "退出 Magicer", action: #selector(quit), keyEquivalent: "q"))
        menu.items.forEach { $0.target = self }
        return menu
    }

    private func setupEditMenu() {
        let mainMenu = NSApp.mainMenu ?? NSMenu()
        NSApp.mainMenu = mainMenu

        // Ensure Edit menu exists
        if mainMenu.item(withTitle: "Edit") == nil {
            let editMenu = NSMenu(title: "Edit")
            editMenu.addItem(NSMenuItem(title: "Undo", action: Selector(("undo:")), keyEquivalent: "z"))
            editMenu.addItem(NSMenuItem(title: "Redo", action: Selector(("redo:")), keyEquivalent: "Z"))
            editMenu.addItem(.separator())
            editMenu.addItem(NSMenuItem(title: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x"))
            editMenu.addItem(NSMenuItem(title: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c"))
            editMenu.addItem(NSMenuItem(title: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v"))
            editMenu.addItem(NSMenuItem(title: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a"))
            let editItem = NSMenuItem(title: "Edit", action: nil, keyEquivalent: "")
            editItem.submenu = editMenu
            mainMenu.addItem(editItem)
        }
    }

    func rebuildMenu() {
        // Left-click opens settings directly; right-click shows context menu (handled in handleStatusClick)
        // No persistent menu on the statusItem to allow direct left-click action.
    }

    // MARK: - Actions

    @objc private func openSettings() { onOpenSettings?() }

    @objc private func enterOffWork() {
        OffWorkManager.shared.enter()
    }

    @objc private func cancelOffWork() {
        OffWorkManager.shared.exit(restore: true)
    }

    @objc private func quit() { NSApp.terminate(nil) }

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
    }
}
