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

    /// Creates a clock label pre-filled with the current time and registered for per-second updates.
    static func clockLbl(size: CGFloat, weight: NSFont.Weight, color: NSColor,
                         align: NSTextAlignment = .center) -> NSTextField {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let f = NSTextField(labelWithString: fmt.string(from: Date()))
        f.font = .monospacedSystemFont(ofSize: size, weight: weight)
        f.textColor = color
        f.alignment = align
        f.drawsBackground = false
        f.backgroundColor = .clear
        f.translatesAutoresizingMaskIntoConstraints = false
        clockLabels.append(f)
        return f
    }

    /// Returns the effective close button label: custom text if set, otherwise "OK".
    static func buttonText(_ rule: ReminderRule) -> String {
        let t = rule.closeButtonText.trimmingCharacters(in: .whitespaces)
        return t.isEmpty ? "OK" : t
    }

    // MARK: - Bottom-right placement (shared by all themes)

    static func addCloseButton(_ btn: CloseButtonView, root: NSView) {
        btn.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(btn)
        NSLayoutConstraint.activate([
            btn.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -44),
            btn.bottomAnchor.constraint(equalTo: root.bottomAnchor, constant: -48),
        ])
        closeBtns.append(btn)
    }

    static func addCountdown(_ cd: NSTextField, root: NSView) {
        cd.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(cd)
        NSLayoutConstraint.activate([
            cd.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -44),
            cd.bottomAnchor.constraint(equalTo: root.bottomAnchor, constant: -100),
        ])
        countdownLabels.append(cd)
    }

    // MARK: - 1. Dramatic (深红警告)
    // Large clock is the focal point; title above, body below.

    static func buildDramatic(in root: NSView, rule: ReminderRule, theme: ThemeColors, size: CGSize) {
        let topOffset = size.height * 0.18
        let title = lbl("⚠  \(rule.name)", size: 38, weight: .black, color: theme.titleTextColor)
        let sep   = makeSeparator()
        let clock = clockLbl(size: 66, weight: .bold, color: theme.primary)
        let body  = lbl(rule.reminderText, size: 22, weight: .medium, color: theme.bodyTextColor, wrap: true)
        let cd    = lbl("", size: 13, weight: .regular, color: theme.countdownColor)
        let btn   = CloseButtonView(theme: theme, text: buttonText(rule)); btn.isHidden = true

        [title, sep, clock, body].forEach { root.addSubview($0) }
        NSLayoutConstraint.activate([
            title.centerXAnchor.constraint(equalTo: root.centerXAnchor),
            title.topAnchor.constraint(equalTo: root.topAnchor, constant: topOffset),
            sep.centerXAnchor.constraint(equalTo: root.centerXAnchor),
            sep.widthAnchor.constraint(equalToConstant: 700),
            sep.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 22),
            clock.centerXAnchor.constraint(equalTo: root.centerXAnchor),
            clock.topAnchor.constraint(equalTo: sep.bottomAnchor, constant: 36),
            body.centerXAnchor.constraint(equalTo: root.centerXAnchor),
            body.widthAnchor.constraint(lessThanOrEqualToConstant: 700),
            body.topAnchor.constraint(equalTo: clock.bottomAnchor, constant: 36),
        ])
        addCountdown(cd, root: root)
        addCloseButton(btn, root: root)
    }

    // MARK: - 2. Serene (深蓝平静)
    // Rule name small at top, then huge clock, body below.

    static func buildSerene(in root: NSView, rule: ReminderRule, theme: ThemeColors, size: CGSize) {
        let topOffset = size.height * 0.22
        let nameTag = lbl(rule.name, size: 18, weight: .light, color: theme.primary.withAlphaComponent(0.65))
        let clock   = clockLbl(size: 68, weight: .ultraLight, color: theme.primary)
        let body    = lbl(rule.reminderText, size: 22, weight: .regular, color: theme.bodyTextColor, wrap: true)
        let cd      = lbl("", size: 13, weight: .light, color: theme.countdownColor)
        let btn     = CloseButtonView(theme: theme, text: buttonText(rule)); btn.isHidden = true

        [nameTag, clock, body].forEach { root.addSubview($0) }
        NSLayoutConstraint.activate([
            nameTag.centerXAnchor.constraint(equalTo: root.centerXAnchor),
            nameTag.topAnchor.constraint(equalTo: root.topAnchor, constant: topOffset),
            clock.centerXAnchor.constraint(equalTo: root.centerXAnchor),
            clock.topAnchor.constraint(equalTo: nameTag.bottomAnchor, constant: 18),
            body.centerXAnchor.constraint(equalTo: root.centerXAnchor),
            body.widthAnchor.constraint(lessThanOrEqualToConstant: 560),
            body.topAnchor.constraint(equalTo: clock.bottomAnchor, constant: 40),
        ])
        addCountdown(cd, root: root)
        addCloseButton(btn, root: root)
    }

    // MARK: - 3. Nature (深绿清新)
    // Left-aligned: leaf → rule name → clock (prominent mono) → body.

    static func buildNature(in root: NSView, rule: ReminderRule, theme: ThemeColors, size: CGSize) {
        let leftMargin: CGFloat = size.width * 0.15
        let topOffset = size.height * 0.20
        let bar = NSView(); bar.wantsLayer = true
        bar.layer?.backgroundColor = theme.primary.withAlphaComponent(0.60).cgColor
        bar.layer?.cornerRadius = 3
        bar.translatesAutoresizingMaskIntoConstraints = false
        let leaf  = lblLeft("🌿", size: 52, weight: .regular, color: theme.primary)
        let title = lblLeft(rule.name, size: 30, weight: .bold, color: theme.titleTextColor)
        let clock = clockLbl(size: 46, weight: .bold, color: theme.primary, align: .left)
        let body  = lblLeft(rule.reminderText, size: 20, weight: .regular, color: theme.bodyTextColor, wrap: true)
        let cd    = lbl("", size: 13, weight: .regular, color: theme.countdownColor)
        let btn   = CloseButtonView(theme: theme, text: buttonText(rule)); btn.isHidden = true

        [bar, leaf, title, clock, body].forEach { root.addSubview($0) }
        NSLayoutConstraint.activate([
            bar.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: leftMargin - 22),
            bar.topAnchor.constraint(equalTo: root.topAnchor, constant: topOffset),
            bar.widthAnchor.constraint(equalToConstant: 5),
            bar.heightAnchor.constraint(equalToConstant: 270),
            leaf.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: leftMargin),
            leaf.topAnchor.constraint(equalTo: root.topAnchor, constant: topOffset),
            title.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: leftMargin),
            title.topAnchor.constraint(equalTo: leaf.bottomAnchor, constant: 8),
            clock.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: leftMargin),
            clock.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 10),
            body.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: leftMargin),
            body.widthAnchor.constraint(lessThanOrEqualToConstant: 600),
            body.topAnchor.constraint(equalTo: clock.bottomAnchor, constant: 24),
        ])
        addCountdown(cd, root: root)
        addCloseButton(btn, root: root)
    }

    // MARK: - 4. Terminal (黑白极简)
    // Terminal log style: header, RULE line, large clock line, NOTICE line, footer.

    static func buildTerminal(in root: NSView, rule: ReminderRule, theme: ThemeColors, size: CGSize) {
        let leftMargin: CGFloat = size.width * 0.22
        let topOffset = size.height * 0.22
        let header  = lblLeft("> ALERT ─────────────────────────────────────────",
                              size: 15, weight: .regular, color: theme.primary.withAlphaComponent(0.50), mono: true)
        let ruleLine = lblLeft("  RULE   : \(rule.name)",
                               size: 16, weight: .regular, color: theme.bodyTextColor, mono: true)
        let timePfx = lblLeft("  TIME   : ", size: 28, weight: .medium,
                              color: theme.bodyTextColor.withAlphaComponent(0.55), mono: true)
        let clock   = clockLbl(size: 28, weight: .bold, color: theme.primary, align: .left)
        let notice  = lblLeft("  NOTICE : \(rule.reminderText)",
                              size: 16, weight: .regular, color: theme.bodyTextColor, wrap: true, mono: true)
        let footer  = lblLeft("─────────────────────────────────────────────────",
                              size: 12, weight: .regular, color: theme.primary.withAlphaComponent(0.25), mono: true)
        let cd      = lbl("", size: 13, weight: .regular, color: theme.countdownColor, mono: true)
        let btn     = CloseButtonView(theme: theme, text: buttonText(rule)); btn.isHidden = true

        // Horizontal stack for "TIME   : <clock>"
        let timeRow = NSStackView(views: [timePfx, clock])
        timeRow.orientation = .horizontal
        timeRow.spacing = 0
        timeRow.alignment = .centerY
        timeRow.translatesAutoresizingMaskIntoConstraints = false

        [header, ruleLine, timeRow, notice, footer].forEach { root.addSubview($0) }
        NSLayoutConstraint.activate([
            header.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: leftMargin),
            header.topAnchor.constraint(equalTo: root.topAnchor, constant: topOffset),
            ruleLine.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: leftMargin),
            ruleLine.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 14),
            timeRow.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: leftMargin),
            timeRow.topAnchor.constraint(equalTo: ruleLine.bottomAnchor, constant: 10),
            notice.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: leftMargin),
            notice.widthAnchor.constraint(lessThanOrEqualToConstant: 660),
            notice.topAnchor.constraint(equalTo: timeRow.bottomAnchor, constant: 10),
            footer.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: leftMargin),
            footer.topAnchor.constraint(equalTo: notice.bottomAnchor, constant: 18),
        ])
        addCountdown(cd, root: root)
        addCloseButton(btn, root: root)
    }

    // MARK: - 5. Gentle (温柔杏)
    // Flower decoration → title → rounded card with clock → body below.

    static func buildGentle(in root: NSView, rule: ReminderRule, theme: ThemeColors, size: CGSize) {
        let topOffset = size.height * 0.17
        let flowers = lbl("🌸  🌸  🌸  🌸  🌸", size: 32, weight: .regular, color: .clear)
        let title   = lbl(rule.name, size: 34, weight: .semibold, color: theme.titleTextColor)

        // Rounded clock card
        let card = NSView(); card.wantsLayer = true
        card.layer?.backgroundColor = theme.primary.withAlphaComponent(0.08).cgColor
        card.layer?.cornerRadius = 18
        card.layer?.borderWidth = 1.5
        card.layer?.borderColor = theme.primary.withAlphaComponent(0.22).cgColor
        card.translatesAutoresizingMaskIntoConstraints = false

        let clock = clockLbl(size: 44, weight: .medium, color: theme.titleTextColor)
        let body  = lbl(rule.reminderText, size: 22, weight: .medium, color: theme.bodyTextColor, wrap: true)
        let cd    = lbl("", size: 13, weight: .light, color: theme.countdownColor)
        let btn   = CloseButtonView(theme: theme, text: buttonText(rule)); btn.isHidden = true

        [flowers, title, card, body].forEach { root.addSubview($0) }
        card.addSubview(clock)
        NSLayoutConstraint.activate([
            flowers.centerXAnchor.constraint(equalTo: root.centerXAnchor),
            flowers.topAnchor.constraint(equalTo: root.topAnchor, constant: topOffset),
            title.centerXAnchor.constraint(equalTo: root.centerXAnchor),
            title.topAnchor.constraint(equalTo: flowers.bottomAnchor, constant: 18),
            card.centerXAnchor.constraint(equalTo: root.centerXAnchor),
            card.widthAnchor.constraint(equalToConstant: 620),
            card.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 24),
            clock.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            clock.topAnchor.constraint(equalTo: card.topAnchor, constant: 22),
            clock.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -22),
            body.centerXAnchor.constraint(equalTo: root.centerXAnchor),
            body.widthAnchor.constraint(lessThanOrEqualToConstant: 560),
            body.topAnchor.constraint(equalTo: card.bottomAnchor, constant: 28),
        ])
        addCountdown(cd, root: root)
        addCloseButton(btn, root: root)
    }

    // MARK: - 6. Playful (少女粉)
    // Decorations → title → large clock → body → hearts.

    static func buildPlayful(in root: NSView, rule: ReminderRule, theme: ThemeColors, size: CGSize) {
        let topOffset = size.height * 0.19
        let decoTop = lbl("✨  💕  ✨", size: 38, weight: .regular, color: .clear)
        let title   = lbl("✨ \(rule.name) ✨", size: 44, weight: .bold, color: theme.titleTextColor)
        let clock   = clockLbl(size: 58, weight: .bold, color: theme.primary)
        let body    = lbl(rule.reminderText, size: 22, weight: .medium, color: theme.bodyTextColor, wrap: true)
        let decoMid = lbl("♡  ♡  ♡  ♡  ♡  ♡", size: 22, weight: .regular,
                          color: theme.primary.withAlphaComponent(0.38))
        let cd      = lbl("", size: 13, weight: .regular, color: theme.countdownColor)
        let btn     = CloseButtonView(theme: theme, text: buttonText(rule)); btn.isHidden = true

        [decoTop, title, clock, body, decoMid].forEach { root.addSubview($0) }
        NSLayoutConstraint.activate([
            decoTop.centerXAnchor.constraint(equalTo: root.centerXAnchor),
            decoTop.topAnchor.constraint(equalTo: root.topAnchor, constant: topOffset),
            title.centerXAnchor.constraint(equalTo: root.centerXAnchor),
            title.topAnchor.constraint(equalTo: decoTop.bottomAnchor, constant: 6),
            clock.centerXAnchor.constraint(equalTo: root.centerXAnchor),
            clock.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 28),
            body.centerXAnchor.constraint(equalTo: root.centerXAnchor),
            body.widthAnchor.constraint(lessThanOrEqualToConstant: 620),
            body.topAnchor.constraint(equalTo: clock.bottomAnchor, constant: 30),
            decoMid.centerXAnchor.constraint(equalTo: root.centerXAnchor),
            decoMid.topAnchor.constraint(equalTo: body.bottomAnchor, constant: 22),
        ])
        addCountdown(cd, root: root)
        addCloseButton(btn, root: root)
    }

    // MARK: - 7. Colorful (马卡龙)
    // Color block contains clock + title; body below.

    static func buildColorful(in root: NSView, rule: ReminderRule, theme: ThemeColors, size: CGSize) {
        let leftMargin: CGFloat = size.width * 0.18
        let topOffset = size.height * 0.19

        let block = NSView(); block.wantsLayer = true
        block.layer?.backgroundColor = theme.primary.withAlphaComponent(0.14).cgColor
        block.layer?.cornerRadius = 14
        block.translatesAutoresizingMaskIntoConstraints = false

        let clockInBlock = clockLbl(size: 50, weight: .heavy, color: theme.titleTextColor, align: .left)
        let titleInBlock = lblLeft(rule.name, size: 20, weight: .semibold,
                                   color: theme.primary.withAlphaComponent(0.70))
        let accent = lblLeft("— BREAK TIME —", size: 13, weight: .semibold,
                             color: theme.primary.withAlphaComponent(0.50))
        let body  = lbl(rule.reminderText, size: 22, weight: .medium, color: theme.bodyTextColor, wrap: true)
        let cd    = lbl("", size: 13, weight: .regular, color: theme.countdownColor)
        let btn   = CloseButtonView(theme: theme, text: buttonText(rule)); btn.isHidden = true

        [block, body].forEach { root.addSubview($0) }
        [clockInBlock, titleInBlock, accent].forEach { block.addSubview($0) }
        NSLayoutConstraint.activate([
            block.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: leftMargin),
            block.topAnchor.constraint(equalTo: root.topAnchor, constant: topOffset),
            block.widthAnchor.constraint(equalToConstant: 580),
            clockInBlock.leadingAnchor.constraint(equalTo: block.leadingAnchor, constant: 24),
            clockInBlock.topAnchor.constraint(equalTo: block.topAnchor, constant: 22),
            titleInBlock.leadingAnchor.constraint(equalTo: block.leadingAnchor, constant: 24),
            titleInBlock.topAnchor.constraint(equalTo: clockInBlock.bottomAnchor, constant: 6),
            accent.leadingAnchor.constraint(equalTo: block.leadingAnchor, constant: 24),
            accent.topAnchor.constraint(equalTo: titleInBlock.bottomAnchor, constant: 6),
            accent.bottomAnchor.constraint(equalTo: block.bottomAnchor, constant: -22),
            body.centerXAnchor.constraint(equalTo: root.centerXAnchor),
            body.widthAnchor.constraint(lessThanOrEqualToConstant: 640),
            body.topAnchor.constraint(equalTo: block.bottomAnchor, constant: 40),
        ])
        addCountdown(cd, root: root)
        addCloseButton(btn, root: root)
    }

    // MARK: - 8. Technical (冷库冰蓝)
    // System-log style: SYSTEM header, RULE row, large TIME row (clock), REMINDER row, footer.

    static func buildTechnical(in root: NSView, rule: ReminderRule, theme: ThemeColors, size: CGSize) {
        let leftMargin: CGFloat = size.width * 0.22
        let topOffset = size.height * 0.22
        let header  = lblLeft("SYSTEM  ══════════════════════════════════════════",
                              size: 14, weight: .medium, color: theme.primary.withAlphaComponent(0.65), mono: true)
        let ruleRow = lblLeft("RULE     : \(rule.name)",
                              size: 15, weight: .regular, color: theme.bodyTextColor, mono: true)
        let timePfx = lblLeft("TIME     : ", size: 26, weight: .medium,
                              color: theme.bodyTextColor.withAlphaComponent(0.55), mono: true)
        let clock   = clockLbl(size: 26, weight: .bold, color: theme.primary, align: .left)
        let reminderRow = lblLeft("REMINDER : \(rule.reminderText)",
                                  size: 15, weight: .regular, color: theme.bodyTextColor, wrap: true, mono: true)
        let footer  = lblLeft("──────────────────────────────────────────────────",
                              size: 12, weight: .regular, color: theme.primary.withAlphaComponent(0.28), mono: true)
        let cd      = lbl("", size: 13, weight: .regular, color: theme.countdownColor, mono: true)
        let btn     = CloseButtonView(theme: theme, text: buttonText(rule)); btn.isHidden = true

        let timeRow = NSStackView(views: [timePfx, clock])
        timeRow.orientation = .horizontal
        timeRow.spacing = 0
        timeRow.alignment = .centerY
        timeRow.translatesAutoresizingMaskIntoConstraints = false

        [header, ruleRow, timeRow, reminderRow, footer].forEach { root.addSubview($0) }
        NSLayoutConstraint.activate([
            header.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: leftMargin),
            header.topAnchor.constraint(equalTo: root.topAnchor, constant: topOffset),
            ruleRow.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: leftMargin),
            ruleRow.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 16),
            timeRow.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: leftMargin),
            timeRow.topAnchor.constraint(equalTo: ruleRow.bottomAnchor, constant: 10),
            reminderRow.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: leftMargin),
            reminderRow.widthAnchor.constraint(lessThanOrEqualToConstant: 680),
            reminderRow.topAnchor.constraint(equalTo: timeRow.bottomAnchor, constant: 10),
            footer.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: leftMargin),
            footer.topAnchor.constraint(equalTo: reminderRow.bottomAnchor, constant: 18),
        ])
        addCountdown(cd, root: root)
        addCloseButton(btn, root: root)
    }
}
