import AppKit

// MARK: - OverlayManager

class OverlayManager {
    private static var windows: [NSWindow] = []
    private static var countdownTimer: Timer?
    private static var closeBtns: [CloseButtonView] = []
    private static var countdownLabels: [NSTextField] = []

    private static var keyMonitor: Any?
    private static var enterPressCount = 0
    private static var lastEnterTime: Date?

    static func show(rule: ReminderRule) {
        guard windows.isEmpty else { return }

        let theme = ThemeColors.find(rule.themeId)
        closeBtns.removeAll()
        countdownLabels.removeAll()
        enterPressCount = 0
        lastEnterTime = nil

        for screen in NSScreen.screens {
            let win = buildWindow(screen: screen, rule: rule, theme: theme)
            windows.append(win)
        }

        NSApp.activate(ignoringOtherApps: true)
        installKeyMonitor()

        let closeDelay = rule.canCloseImmediately ? 0 : rule.durationSeconds
        if closeDelay <= 0 {
            closeBtns.forEach { $0.isHidden = false }
            countdownLabels.forEach { $0.stringValue = "" }
        } else {
            startCountdown(seconds: closeDelay)
        }
    }

    static func dismiss() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        if let monitor = keyMonitor { NSEvent.removeMonitor(monitor); keyMonitor = nil }
        windows.forEach { $0.orderOut(nil) }
        windows.removeAll()
        closeBtns.removeAll()
        countdownLabels.removeAll()
        enterPressCount = 0
    }

    // MARK: - Enter Key Backdoor (4 presses within 3s)

    private static func installKeyMonitor() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 36 {
                let now = Date()
                if let last = lastEnterTime, now.timeIntervalSince(last) < 3.0 {
                    enterPressCount += 1
                } else {
                    enterPressCount = 1
                }
                lastEnterTime = now
                if enterPressCount >= 4 {
                    enterPressCount = 0
                    DispatchQueue.main.async {
                        countdownTimer?.invalidate(); countdownTimer = nil
                        countdownLabels.forEach { $0.stringValue = "" }
                        closeBtns.forEach { $0.isHidden = false }
                    }
                }
                return nil
            }
            return event
        }
    }

    // MARK: - Build Window

    private static func buildWindow(screen: NSScreen, rule: ReminderRule, theme: ThemeColors) -> NSWindow {
        let fr = screen.frame
        let win = NSWindow(
            contentRect: fr, styleMask: .borderless,
            backing: .buffered, defer: false, screen: screen
        )
        win.level = NSWindow.Level(rawValue: Int(NSWindow.Level.screenSaver.rawValue) + 100)
        win.isOpaque = true
        win.backgroundColor = theme.background
        win.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        win.ignoresMouseEvents = false
        win.acceptsMouseMovedEvents = true

        let root = RootView(frame: NSRect(origin: .zero, size: fr.size))
        root.wantsLayer = true
        root.layer?.backgroundColor = theme.background.cgColor
        root.autoresizingMask = [.width, .height]

        buildContent(in: root, rule: rule, theme: theme, size: fr.size)

        win.contentView = root
        win.orderFrontRegardless()
        win.setFrame(fr, display: true)
        return win
    }

    // MARK: - Layout Dispatch

    private static func buildContent(in root: NSView, rule: ReminderRule, theme: ThemeColors, size: CGSize) {
        switch theme.overlayLayout {
        case .dramatic:   buildDramatic(in: root, rule: rule, theme: theme, size: size)
        case .serene:     buildSerene(in: root, rule: rule, theme: theme, size: size)
        case .nature:     buildNature(in: root, rule: rule, theme: theme, size: size)
        case .terminal:   buildTerminal(in: root, rule: rule, theme: theme, size: size)
        case .gentle:     buildGentle(in: root, rule: rule, theme: theme, size: size)
        case .playful:    buildPlayful(in: root, rule: rule, theme: theme, size: size)
        case .colorful:   buildColorful(in: root, rule: rule, theme: theme, size: size)
        case .technical:  buildTechnical(in: root, rule: rule, theme: theme, size: size)
        }
    }

    // MARK: - Helpers

    private static func lbl(_ text: String, size: CGFloat, weight: NSFont.Weight,
                             color: NSColor, wrap: Bool = false, mono: Bool = false) -> NSTextField {
        let f: NSTextField = wrap ? NSTextField(wrappingLabelWithString: text) : NSTextField(labelWithString: text)
        f.font = mono
            ? .monospacedSystemFont(ofSize: size, weight: weight)
            : .systemFont(ofSize: size, weight: weight)
        f.textColor = color
        f.alignment = .center
        f.translatesAutoresizingMaskIntoConstraints = false
        return f
    }

    private static func lblLeft(_ text: String, size: CGFloat, weight: NSFont.Weight,
                                color: NSColor, wrap: Bool = false, mono: Bool = false) -> NSTextField {
        let f = lbl(text, size: size, weight: weight, color: color, wrap: wrap, mono: mono)
        f.alignment = .left
        return f
    }

    private static func separator(_ color: NSColor) -> NSBox {
        let b = NSBox(); b.boxType = .separator
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }

    private static func addCloseButton(_ btn: CloseButtonView, below anchor: NSLayoutYAxisAnchor,
                                        offset: CGFloat, root: NSView) {
        btn.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(btn)
        NSLayoutConstraint.activate([
            btn.centerXAnchor.constraint(equalTo: root.centerXAnchor),
            btn.topAnchor.constraint(equalTo: anchor, constant: offset),
            btn.widthAnchor.constraint(equalToConstant: 340),
            btn.heightAnchor.constraint(equalToConstant: 64),
        ])
        closeBtns.append(btn)
    }

    private static func addCountdown(_ cd: NSTextField, below anchor: NSLayoutYAxisAnchor,
                                      offset: CGFloat, root: NSView) {
        root.addSubview(cd)
        NSLayoutConstraint.activate([
            cd.centerXAnchor.constraint(equalTo: root.centerXAnchor),
            cd.topAnchor.constraint(equalTo: anchor, constant: offset),
        ])
        countdownLabels.append(cd)
    }

    // MARK: - 1. Dramatic (深红警告)
    // Massive alarm title, full-width red separator, large body centered

    private static func buildDramatic(in root: NSView, rule: ReminderRule, theme: ThemeColors, size: CGSize) {
        let topOffset = size.height * 0.20

        let title = lbl("⚠  工作中断提醒", size: 62, weight: .black, color: theme.titleTextColor)
        let sep = separator(theme.primary)
        let body = lbl(rule.reminderText, size: 28, weight: .medium, color: theme.bodyTextColor, wrap: true)
        let cd = lbl("", size: 20, weight: .regular, color: theme.countdownColor)
        let btn = CloseButtonView(theme: theme); btn.isHidden = true

        [title, sep, body, cd].forEach { root.addSubview($0) }
        NSLayoutConstraint.activate([
            title.centerXAnchor.constraint(equalTo: root.centerXAnchor),
            title.topAnchor.constraint(equalTo: root.topAnchor, constant: topOffset),
            sep.centerXAnchor.constraint(equalTo: root.centerXAnchor),
            sep.widthAnchor.constraint(equalToConstant: 600),
            sep.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 28),
            body.centerXAnchor.constraint(equalTo: root.centerXAnchor),
            body.widthAnchor.constraint(lessThanOrEqualToConstant: 700),
            body.topAnchor.constraint(equalTo: sep.bottomAnchor, constant: 40),
        ])
        addCountdown(cd, below: body.bottomAnchor, offset: 56, root: root)
        addCloseButton(btn, below: body.bottomAnchor, offset: 48, root: root)
    }

    // MARK: - 2. Serene (深蓝平静)
    // Large circle glyph at center, minimal text below, soft and breathing

    private static func buildSerene(in root: NSView, rule: ReminderRule, theme: ThemeColors, size: CGSize) {
        let topOffset = size.height * 0.24

        let circle = lbl("◉", size: 110, weight: .ultraLight, color: theme.primary.withAlphaComponent(0.8))
        let sub = lbl("休 息 一 下", size: 22, weight: .light, color: theme.primary.withAlphaComponent(0.9))
        let body = lbl(rule.reminderText, size: 24, weight: .regular, color: theme.bodyTextColor, wrap: true)
        let cd = lbl("", size: 18, weight: .light, color: theme.countdownColor)
        let btn = CloseButtonView(theme: theme); btn.isHidden = true

        [circle, sub, body, cd].forEach { root.addSubview($0) }
        NSLayoutConstraint.activate([
            circle.centerXAnchor.constraint(equalTo: root.centerXAnchor),
            circle.topAnchor.constraint(equalTo: root.topAnchor, constant: topOffset),
            sub.centerXAnchor.constraint(equalTo: root.centerXAnchor),
            sub.topAnchor.constraint(equalTo: circle.bottomAnchor, constant: 6),
            body.centerXAnchor.constraint(equalTo: root.centerXAnchor),
            body.widthAnchor.constraint(lessThanOrEqualToConstant: 560),
            body.topAnchor.constraint(equalTo: sub.bottomAnchor, constant: 36),
        ])
        addCountdown(cd, below: body.bottomAnchor, offset: 48, root: root)
        addCloseButton(btn, below: body.bottomAnchor, offset: 40, root: root)
    }

    // MARK: - 3. Nature (深绿清新)
    // Left-aligned with large leaf glyph, accent bar, earthy feel

    private static func buildNature(in root: NSView, rule: ReminderRule, theme: ThemeColors, size: CGSize) {
        let leftMargin: CGFloat = size.width * 0.15
        let topOffset = size.height * 0.22

        // Vertical accent bar
        let bar = NSView(); bar.wantsLayer = true
        bar.layer?.backgroundColor = theme.primary.withAlphaComponent(0.7).cgColor
        bar.layer?.cornerRadius = 3
        bar.translatesAutoresizingMaskIntoConstraints = false

        let leaf = lbl("🌿", size: 80, weight: .regular, color: theme.primary)
        leaf.alignment = .left
        let title = lblLeft("工作中断提醒", size: 44, weight: .bold, color: theme.titleTextColor)
        let body = lblLeft(rule.reminderText, size: 24, weight: .regular, color: theme.bodyTextColor, wrap: true)
        let cd = lbl("", size: 18, weight: .regular, color: theme.countdownColor)
        let btn = CloseButtonView(theme: theme); btn.isHidden = true

        [bar, leaf, title, body, cd].forEach { root.addSubview($0) }
        NSLayoutConstraint.activate([
            bar.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: leftMargin - 24),
            bar.topAnchor.constraint(equalTo: root.topAnchor, constant: topOffset),
            bar.widthAnchor.constraint(equalToConstant: 6),
            bar.heightAnchor.constraint(equalToConstant: 220),

            leaf.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: leftMargin),
            leaf.topAnchor.constraint(equalTo: root.topAnchor, constant: topOffset),

            title.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: leftMargin),
            title.topAnchor.constraint(equalTo: leaf.bottomAnchor, constant: 10),

            body.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: leftMargin),
            body.widthAnchor.constraint(lessThanOrEqualToConstant: 600),
            body.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 24),
        ])
        addCountdown(cd, below: body.bottomAnchor, offset: 52, root: root)
        addCloseButton(btn, below: body.bottomAnchor, offset: 44, root: root)
    }

    // MARK: - 4. Terminal (黑白极简)
    // Code/terminal style, monospace, brackets, hacker feel

    private static func buildTerminal(in root: NSView, rule: ReminderRule, theme: ThemeColors, size: CGSize) {
        let leftMargin: CGFloat = size.width * 0.25
        let topOffset = size.height * 0.26

        let prompt = lblLeft("> BREAK_TIME —", size: 18, weight: .regular,
                             color: theme.primary.withAlphaComponent(0.55), mono: true)
        let dashLine = lblLeft("─────────────────────────────────────────────────",
                               size: 13, weight: .regular, color: theme.primary.withAlphaComponent(0.25), mono: true)
        let bodyPre = lblLeft("  \(rule.reminderText)", size: 26, weight: .medium,
                              color: theme.bodyTextColor, wrap: true, mono: true)
        let cd = lblLeft("", size: 16, weight: .regular,
                         color: theme.countdownColor, mono: true)
        let btn = CloseButtonView(theme: theme); btn.isHidden = true

        [prompt, dashLine, bodyPre, cd].forEach { root.addSubview($0) }
        NSLayoutConstraint.activate([
            prompt.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: leftMargin),
            prompt.topAnchor.constraint(equalTo: root.topAnchor, constant: topOffset),
            dashLine.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: leftMargin),
            dashLine.topAnchor.constraint(equalTo: prompt.bottomAnchor, constant: 10),
            bodyPre.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: leftMargin),
            bodyPre.widthAnchor.constraint(lessThanOrEqualToConstant: 620),
            bodyPre.topAnchor.constraint(equalTo: dashLine.bottomAnchor, constant: 20),
        ])
        addCountdown(cd, below: bodyPre.bottomAnchor, offset: 36, root: root)
        addCloseButton(btn, below: bodyPre.bottomAnchor, offset: 28, root: root)
    }

    // MARK: - 5. Gentle (温柔杏)
    // Flower row top, rounded body container, warm and soft

    private static func buildGentle(in root: NSView, rule: ReminderRule, theme: ThemeColors, size: CGSize) {
        let topOffset = size.height * 0.18

        let flowers = lbl("🌸  🌸  🌸  🌸  🌸", size: 36, weight: .regular, color: .clear)
        let title = lbl("工作中断提醒", size: 38, weight: .semibold, color: theme.titleTextColor)

        // Rounded body container
        let container = NSView(); container.wantsLayer = true
        container.layer?.backgroundColor = theme.primary.withAlphaComponent(0.08).cgColor
        container.layer?.cornerRadius = 20
        container.layer?.borderWidth = 1.5
        container.layer?.borderColor = theme.primary.withAlphaComponent(0.2).cgColor
        container.translatesAutoresizingMaskIntoConstraints = false

        let body = lbl(rule.reminderText, size: 26, weight: .medium, color: theme.bodyTextColor, wrap: true)

        let cd = lbl("", size: 18, weight: .light, color: theme.countdownColor)
        let btn = CloseButtonView(theme: theme); btn.isHidden = true

        [flowers, title, container, cd].forEach { root.addSubview($0) }
        root.addSubview(body)

        NSLayoutConstraint.activate([
            flowers.centerXAnchor.constraint(equalTo: root.centerXAnchor),
            flowers.topAnchor.constraint(equalTo: root.topAnchor, constant: topOffset),

            title.centerXAnchor.constraint(equalTo: root.centerXAnchor),
            title.topAnchor.constraint(equalTo: flowers.bottomAnchor, constant: 20),

            container.centerXAnchor.constraint(equalTo: root.centerXAnchor),
            container.widthAnchor.constraint(equalToConstant: 600),
            container.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 28),

            body.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            body.widthAnchor.constraint(lessThanOrEqualToConstant: 540),
            body.topAnchor.constraint(equalTo: container.topAnchor, constant: 28),
            body.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -28),
        ])
        addCountdown(cd, below: container.bottomAnchor, offset: 32, root: root)
        addCloseButton(btn, below: container.bottomAnchor, offset: 24, root: root)
    }

    // MARK: - 6. Playful (少女粉)
    // Stars + hearts, decorative title, bubbly layout

    private static func buildPlayful(in root: NSView, rule: ReminderRule, theme: ThemeColors, size: CGSize) {
        let topOffset = size.height * 0.20

        let decoTop = lbl("✨  💕  ✨", size: 44, weight: .regular, color: .clear)
        let title = lbl("✨ 需要休息啦 ✨", size: 52, weight: .bold, color: theme.titleTextColor)
        let body = lbl(rule.reminderText, size: 26, weight: .medium, color: theme.bodyTextColor, wrap: true)
        let decoMid = lbl("♡  ♡  ♡  ♡  ♡  ♡", size: 24, weight: .regular, color: theme.primary.withAlphaComponent(0.4))
        let cd = lbl("", size: 18, weight: .regular, color: theme.countdownColor)
        let btn = CloseButtonView(theme: theme); btn.isHidden = true

        [decoTop, title, body, decoMid, cd].forEach { root.addSubview($0) }
        NSLayoutConstraint.activate([
            decoTop.centerXAnchor.constraint(equalTo: root.centerXAnchor),
            decoTop.topAnchor.constraint(equalTo: root.topAnchor, constant: topOffset),
            title.centerXAnchor.constraint(equalTo: root.centerXAnchor),
            title.topAnchor.constraint(equalTo: decoTop.bottomAnchor, constant: 8),
            body.centerXAnchor.constraint(equalTo: root.centerXAnchor),
            body.widthAnchor.constraint(lessThanOrEqualToConstant: 620),
            body.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 36),
            decoMid.centerXAnchor.constraint(equalTo: root.centerXAnchor),
            decoMid.topAnchor.constraint(equalTo: body.bottomAnchor, constant: 24),
        ])
        addCountdown(cd, below: decoMid.bottomAnchor, offset: 32, root: root)
        addCloseButton(btn, below: decoMid.bottomAnchor, offset: 24, root: root)
    }

    // MARK: - 7. Colorful (马卡龙)
    // Bold left-aligned title with color block, layered

    private static func buildColorful(in root: NSView, rule: ReminderRule, theme: ThemeColors, size: CGSize) {
        let leftMargin: CGFloat = size.width * 0.18
        let topOffset = size.height * 0.21

        // Color block
        let block = NSView(); block.wantsLayer = true
        block.layer?.backgroundColor = theme.primary.withAlphaComponent(0.15).cgColor
        block.layer?.cornerRadius = 12
        block.translatesAutoresizingMaskIntoConstraints = false

        let emoji = lblLeft("🍭", size: 64, weight: .regular, color: .clear)
        let title = lblLeft("工作中断提醒", size: 52, weight: .heavy, color: theme.titleTextColor)
        let accent = lblLeft("— BREAK TIME —", size: 16, weight: .semibold,
                             color: theme.primary.withAlphaComponent(0.6))
        let body = lbl(rule.reminderText, size: 26, weight: .medium, color: theme.bodyTextColor, wrap: true)
        let cd = lbl("", size: 18, weight: .regular, color: theme.countdownColor)
        let btn = CloseButtonView(theme: theme); btn.isHidden = true

        [block, emoji, title, accent, body, cd].forEach { root.addSubview($0) }
        NSLayoutConstraint.activate([
            block.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: leftMargin - 16),
            block.topAnchor.constraint(equalTo: root.topAnchor, constant: topOffset - 12),
            block.widthAnchor.constraint(equalToConstant: 520),
            block.heightAnchor.constraint(equalToConstant: 180),

            emoji.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: leftMargin),
            emoji.topAnchor.constraint(equalTo: root.topAnchor, constant: topOffset),

            title.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: leftMargin),
            title.topAnchor.constraint(equalTo: emoji.bottomAnchor, constant: 4),

            accent.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: leftMargin),
            accent.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 10),

            body.centerXAnchor.constraint(equalTo: root.centerXAnchor),
            body.widthAnchor.constraint(lessThanOrEqualToConstant: 640),
            body.topAnchor.constraint(equalTo: accent.bottomAnchor, constant: 48),
        ])
        addCountdown(cd, below: body.bottomAnchor, offset: 48, root: root)
        addCloseButton(btn, below: body.bottomAnchor, offset: 40, root: root)
    }

    // MARK: - 8. Technical (冷库冰蓝)
    // System log / grid style, label:value pairs, clean technical

    private static func buildTechnical(in root: NSView, rule: ReminderRule, theme: ThemeColors, size: CGSize) {
        let leftMargin: CGFloat = size.width * 0.22
        let topOffset = size.height * 0.24

        let header = lblLeft("SYSTEM  ═══════════════════════════════════════",
                             size: 15, weight: .medium, color: theme.primary.withAlphaComponent(0.7), mono: true)
        let statusRow = lblLeft("STATUS   : BREAK REQUIRED",
                                size: 16, weight: .regular, color: theme.bodyTextColor, mono: true)
        let reminderRow = lblLeft("REMINDER : \(rule.reminderText)",
                                  size: 16, weight: .regular, color: theme.bodyTextColor, wrap: true, mono: true)
        let footer = lblLeft("──────────────────────────────────────────────",
                             size: 13, weight: .regular, color: theme.primary.withAlphaComponent(0.3), mono: true)
        let cd = lbl("", size: 16, weight: .regular, color: theme.countdownColor, mono: true)
        let btn = CloseButtonView(theme: theme); btn.isHidden = true

        [header, statusRow, reminderRow, footer, cd].forEach { root.addSubview($0) }
        NSLayoutConstraint.activate([
            header.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: leftMargin),
            header.topAnchor.constraint(equalTo: root.topAnchor, constant: topOffset),
            statusRow.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: leftMargin),
            statusRow.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 18),
            reminderRow.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: leftMargin),
            reminderRow.widthAnchor.constraint(lessThanOrEqualToConstant: 680),
            reminderRow.topAnchor.constraint(equalTo: statusRow.bottomAnchor, constant: 10),
            footer.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: leftMargin),
            footer.topAnchor.constraint(equalTo: reminderRow.bottomAnchor, constant: 20),
        ])
        addCountdown(cd, below: footer.bottomAnchor, offset: 36, root: root)
        addCloseButton(btn, below: footer.bottomAnchor, offset: 28, root: root)
    }

    // MARK: - Countdown Timer

    private static func startCountdown(seconds: Int) {
        var remaining = seconds
        countdownLabels.forEach { $0.stringValue = "\(remaining) 秒后可关闭…" }

        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            remaining -= 1
            DispatchQueue.main.async {
                if remaining > 0 {
                    countdownLabels.forEach { $0.stringValue = "\(remaining) 秒后可关闭…" }
                } else {
                    timer.invalidate(); countdownTimer = nil
                    countdownLabels.forEach { $0.stringValue = "" }
                    closeBtns.forEach { $0.isHidden = false }
                }
            }
        }
        RunLoop.main.add(countdownTimer!, forMode: .common)
    }
}

// MARK: - RootView

private class RootView: NSView {
    override var isFlipped: Bool { true }
}

// MARK: - CloseButtonView

class CloseButtonView: NSView {
    private let theme: ThemeColors
    private var hovered = false { didSet { needsDisplay = true } }

    init(theme: ThemeColors) {
        self.theme = theme
        super.init(frame: .zero)
        wantsLayer = true
        updateTrackingAreas()
    }
    required init?(coder: NSCoder) { fatalError() }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach { removeTrackingArea($0) }
        addTrackingArea(NSTrackingArea(rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways], owner: self, userInfo: nil))
    }

    override func mouseEntered(with event: NSEvent) { hovered = true }
    override func mouseExited(with event: NSEvent)  { hovered = false }
    override func mouseUp(with event: NSEvent)      { OverlayManager.dismiss() }

    override func draw(_ dirtyRect: NSRect) {
        let bg = hovered
            ? theme.primary.withAlphaComponent(0.85)
            : theme.primary.withAlphaComponent(0.65)
        bg.setFill()
        NSBezierPath(roundedRect: bounds, xRadius: 14, yRadius: 14).fill()

        let text = "✓   我知道了，开始休息" as NSString
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 24),
            .foregroundColor: NSColor.white,
        ]
        let sz = text.size(withAttributes: attrs)
        let pt = CGPoint(x: (bounds.width - sz.width) / 2, y: (bounds.height - sz.height) / 2 + 1)
        text.draw(at: pt, withAttributes: attrs)
    }

    override func resetCursorRects() { addCursorRect(bounds, cursor: .pointingHand) }
}
