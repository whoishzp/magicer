import AppKit

// MARK: - Internal Root View

class OverlayRootView: NSView {
    override var isFlipped: Bool { true }
}

// MARK: - Layout Builders (extension on OverlayManager)

extension OverlayManager {

    // MARK: Dispatch

    static func buildContent(in root: NSView, rule: ReminderRule, theme: ThemeColors, size: CGSize) {
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

    // MARK: - Factory Helpers

    static func lbl(_ text: String, size: CGFloat, weight: NSFont.Weight,
                    color: NSColor, wrap: Bool = false, mono: Bool = false) -> NSTextField {
        let f: NSTextField = wrap ? NSTextField(wrappingLabelWithString: text) : NSTextField(labelWithString: text)
        f.font = mono ? .monospacedSystemFont(ofSize: size, weight: weight) : .systemFont(ofSize: size, weight: weight)
        f.textColor = color
        f.alignment = .center
        f.drawsBackground = false
        f.backgroundColor = .clear
        f.translatesAutoresizingMaskIntoConstraints = false
        return f
    }

    static func lblLeft(_ text: String, size: CGFloat, weight: NSFont.Weight,
                        color: NSColor, wrap: Bool = false, mono: Bool = false) -> NSTextField {
        let f = lbl(text, size: size, weight: weight, color: color, wrap: wrap, mono: mono)
        f.alignment = .left; return f
    }

    static func makeSeparator() -> NSBox {
        let b = NSBox(); b.boxType = .separator; b.translatesAutoresizingMaskIntoConstraints = false; return b
    }

    static func addCloseButton(_ btn: CloseButtonView, below anchor: NSLayoutYAxisAnchor,
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

    static func addCountdown(_ cd: NSTextField, below anchor: NSLayoutYAxisAnchor,
                             offset: CGFloat, root: NSView) {
        root.addSubview(cd)
        NSLayoutConstraint.activate([
            cd.centerXAnchor.constraint(equalTo: root.centerXAnchor),
            cd.topAnchor.constraint(equalTo: anchor, constant: offset),
        ])
        countdownLabels.append(cd)
    }

    // MARK: - 1. Dramatic (深红警告)

    static func buildDramatic(in root: NSView, rule: ReminderRule, theme: ThemeColors, size: CGSize) {
        let topOffset = size.height * 0.20
        let title = lbl("⚠  \(rule.name)", size: 62, weight: .black, color: theme.titleTextColor)
        let sep = makeSeparator()
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

    static func buildSerene(in root: NSView, rule: ReminderRule, theme: ThemeColors, size: CGSize) {
        let topOffset = size.height * 0.24
        let circle = lbl("◉", size: 110, weight: .ultraLight, color: theme.primary.withAlphaComponent(0.8))
        let sub = lbl(rule.name, size: 22, weight: .light, color: theme.primary.withAlphaComponent(0.9))
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

    static func buildNature(in root: NSView, rule: ReminderRule, theme: ThemeColors, size: CGSize) {
        let leftMargin: CGFloat = size.width * 0.15
        let topOffset = size.height * 0.22
        let bar = NSView(); bar.wantsLayer = true
        bar.layer?.backgroundColor = theme.primary.withAlphaComponent(0.7).cgColor
        bar.layer?.cornerRadius = 3
        bar.translatesAutoresizingMaskIntoConstraints = false
        let leaf = lbl("🌿", size: 80, weight: .regular, color: theme.primary)
        leaf.alignment = .left
        let title = lblLeft(rule.name, size: 44, weight: .bold, color: theme.titleTextColor)
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

    static func buildTerminal(in root: NSView, rule: ReminderRule, theme: ThemeColors, size: CGSize) {
        let leftMargin: CGFloat = size.width * 0.25
        let topOffset = size.height * 0.26
        let prompt = lblLeft("> \(rule.name) —", size: 18, weight: .regular,
                             color: theme.primary.withAlphaComponent(0.55), mono: true)
        let dashLine = lblLeft("─────────────────────────────────────────────────",
                               size: 13, weight: .regular, color: theme.primary.withAlphaComponent(0.25), mono: true)
        let bodyPre = lblLeft("  \(rule.reminderText)", size: 26, weight: .medium,
                              color: theme.bodyTextColor, wrap: true, mono: true)
        let cd = lblLeft("", size: 16, weight: .regular, color: theme.countdownColor, mono: true)
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

    static func buildGentle(in root: NSView, rule: ReminderRule, theme: ThemeColors, size: CGSize) {
        let topOffset = size.height * 0.18
        let flowers = lbl("🌸  🌸  🌸  🌸  🌸", size: 36, weight: .regular, color: .clear)
        let title = lbl(rule.name, size: 38, weight: .semibold, color: theme.titleTextColor)
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

    static func buildPlayful(in root: NSView, rule: ReminderRule, theme: ThemeColors, size: CGSize) {
        let topOffset = size.height * 0.20
        let decoTop = lbl("✨  💕  ✨", size: 44, weight: .regular, color: .clear)
        let title = lbl("✨ \(rule.name) ✨", size: 52, weight: .bold, color: theme.titleTextColor)
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

    static func buildColorful(in root: NSView, rule: ReminderRule, theme: ThemeColors, size: CGSize) {
        let leftMargin: CGFloat = size.width * 0.18
        let topOffset = size.height * 0.21
        let block = NSView(); block.wantsLayer = true
        block.layer?.backgroundColor = theme.primary.withAlphaComponent(0.15).cgColor
        block.layer?.cornerRadius = 12
        block.translatesAutoresizingMaskIntoConstraints = false
        let emoji = lblLeft("🍭", size: 64, weight: .regular, color: .clear)
        let title = lblLeft(rule.name, size: 52, weight: .heavy, color: theme.titleTextColor)
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

    static func buildTechnical(in root: NSView, rule: ReminderRule, theme: ThemeColors, size: CGSize) {
        let leftMargin: CGFloat = size.width * 0.22
        let topOffset = size.height * 0.24
        let header = lblLeft("SYSTEM  ═══════════════════════════════════════",
                             size: 15, weight: .medium, color: theme.primary.withAlphaComponent(0.7), mono: true)
        let statusRow = lblLeft("RULE     : \(rule.name)",
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
}
