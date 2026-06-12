import AppKit

// MARK: - Internal Root View

/// Full-screen overlay root view.
/// Paints a diagonal gradient + two large blurred-ish orbs as background,
/// then hosts all text sub-views via Auto Layout.
class OverlayRootView: NSView {
    override var isFlipped: Bool { true }
    var theme: ThemeColors?

    override func draw(_ dirtyRect: NSRect) {
        guard let theme = theme else {
            NSColor.black.setFill()
            dirtyRect.fill()
            return
        }
        let W = bounds.width, H = bounds.height

        // ── 1. Diagonal gradient base ──────────────────────────────────────
        let gradEnd = theme.background
            .blended(withFraction: 0.22, of: theme.orbColor1) ?? theme.background
        if let grad = NSGradient(starting: theme.background, ending: gradEnd) {
            grad.draw(in: bounds, angle: -45)
        }

        // ── 2. Orb 1 — large, top-left area ───────────────────────────────
        drawOrb(color: theme.orbColor1.withAlphaComponent(0.32),
                center: CGPoint(x: W * 0.22, y: H * 0.28),
                radius: H * 0.40)

        // ── 3. Orb 2 — medium, bottom-right area ──────────────────────────
        drawOrb(color: theme.orbColor2.withAlphaComponent(0.24),
                center: CGPoint(x: W * 0.78, y: H * 0.72),
                radius: H * 0.34)

        // ── 4. Accent orb — small, top-right ──────────────────────────────
        drawOrb(color: theme.orbColor2.withAlphaComponent(0.16),
                center: CGPoint(x: W * 0.85, y: H * 0.15),
                radius: H * 0.16)
    }

    private func drawOrb(color: NSColor, center: CGPoint, radius: CGFloat) {
        let rect = NSRect(x: center.x - radius, y: center.y - radius,
                          width: radius * 2, height: radius * 2)
        color.setFill()
        NSBezierPath(ovalIn: rect).fill()
    }
}

// MARK: - Layout Builders (extension on OverlayManager)

extension OverlayManager {

    // MARK: Dispatch — all themes use the same unified layout

    static func buildContent(in root: NSView, rule: ReminderRule, theme: ThemeColors, size: CGSize) {
        buildUnified(in: root, rule: rule, theme: theme, size: size)
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

    /// Creates a clock label showing HH:mm:ss — registered for per-second updates.
    static func clockLbl(size: CGFloat, weight: NSFont.Weight, color: NSColor) -> NSTextField {
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm:ss"
        let f = NSTextField(labelWithString: fmt.string(from: Date()))
        f.font = .monospacedSystemFont(ofSize: size, weight: weight)
        f.textColor = color
        f.alignment = .center
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

    // MARK: - Bottom-right placement (shared)

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

    // MARK: - Unified Layout
    // All 8 themes share this structure. Differentiation is purely through
    // the gradient+orb background rendered by OverlayRootView.draw().

    static func buildUnified(in root: NSView, rule: ReminderRule, theme: ThemeColors, size: CGSize) {
        switch rule.prominentItem {
        case .time:
            buildTimeProminent(in: root, rule: rule, theme: theme)
        case .text:
            buildTextProminent(in: root, rule: rule, theme: theme)
        }
    }

    // MARK: - Time-prominent layout (default)

    private static func buildTimeProminent(in root: NSView, rule: ReminderRule, theme: ThemeColors) {
        let nameLbl = lbl(rule.name, size: 16, weight: .light, color: theme.overlayNameColor)
        let clock = clockLbl(size: 90, weight: theme.clockFontWeight, color: theme.overlayClockColor)

        let dateFmt = DateFormatter(); dateFmt.dateFormat = "yyyy-MM-dd"
        let dateLbl = lbl(dateFmt.string(from: Date()), size: 20, weight: .light,
                          color: theme.overlayDateColor, mono: true)

        let sep = makeSeparator(color: theme.overlayClockColor)
        let body = lbl(rule.reminderText, size: 20, weight: .regular,
                       color: theme.overlayBodyColor, wrap: true)

        let cd  = lbl("", size: 13, weight: .regular, color: theme.overlayCountdownColor)
        let btn = CloseButtonView(theme: theme, text: buttonText(rule)); btn.isHidden = true

        [nameLbl, clock, dateLbl, sep, body].forEach { root.addSubview($0) }

        NSLayoutConstraint.activate([
            clock.centerXAnchor.constraint(equalTo: root.centerXAnchor),
            clock.centerYAnchor.constraint(equalTo: root.centerYAnchor, constant: -20),

            nameLbl.centerXAnchor.constraint(equalTo: root.centerXAnchor),
            nameLbl.bottomAnchor.constraint(equalTo: clock.topAnchor, constant: -14),

            dateLbl.centerXAnchor.constraint(equalTo: root.centerXAnchor),
            dateLbl.topAnchor.constraint(equalTo: clock.bottomAnchor, constant: 12),

            sep.centerXAnchor.constraint(equalTo: root.centerXAnchor),
            sep.widthAnchor.constraint(equalToConstant: 480),
            sep.heightAnchor.constraint(equalToConstant: 1),
            sep.topAnchor.constraint(equalTo: dateLbl.bottomAnchor, constant: 28),

            body.centerXAnchor.constraint(equalTo: root.centerXAnchor),
            body.widthAnchor.constraint(lessThanOrEqualToConstant: 640),
            body.topAnchor.constraint(equalTo: sep.bottomAnchor, constant: 24),
        ])
        addCountdown(cd, root: root)
        addCloseButton(btn, root: root)
    }

    // MARK: - Text-prominent layout

    private static func buildTextProminent(in root: NSView, rule: ReminderRule, theme: ThemeColors) {
        let nameLbl = lbl(rule.name, size: 16, weight: .light, color: theme.overlayNameColor)

        let body = lbl(rule.reminderText, size: 52, weight: .semibold,
                       color: theme.overlayBodyColor, wrap: true)

        let sep = makeSeparator(color: theme.overlayClockColor)

        let clock = clockLbl(size: 36, weight: theme.clockFontWeight, color: theme.overlayClockColor)

        let dateFmt = DateFormatter(); dateFmt.dateFormat = "yyyy-MM-dd"
        let dateLbl = lbl(dateFmt.string(from: Date()), size: 16, weight: .light,
                          color: theme.overlayDateColor, mono: true)

        let cd  = lbl("", size: 13, weight: .regular, color: theme.overlayCountdownColor)
        let btn = CloseButtonView(theme: theme, text: buttonText(rule)); btn.isHidden = true

        [nameLbl, body, sep, clock, dateLbl].forEach { root.addSubview($0) }

        NSLayoutConstraint.activate([
            body.centerXAnchor.constraint(equalTo: root.centerXAnchor),
            body.centerYAnchor.constraint(equalTo: root.centerYAnchor, constant: -30),
            body.widthAnchor.constraint(lessThanOrEqualToConstant: 800),

            nameLbl.centerXAnchor.constraint(equalTo: root.centerXAnchor),
            nameLbl.bottomAnchor.constraint(equalTo: body.topAnchor, constant: -18),

            sep.centerXAnchor.constraint(equalTo: root.centerXAnchor),
            sep.widthAnchor.constraint(equalToConstant: 480),
            sep.heightAnchor.constraint(equalToConstant: 1),
            sep.topAnchor.constraint(equalTo: body.bottomAnchor, constant: 32),

            clock.centerXAnchor.constraint(equalTo: root.centerXAnchor),
            clock.topAnchor.constraint(equalTo: sep.bottomAnchor, constant: 20),

            dateLbl.centerXAnchor.constraint(equalTo: root.centerXAnchor),
            dateLbl.topAnchor.constraint(equalTo: clock.bottomAnchor, constant: 8),
        ])
        addCountdown(cd, root: root)
        addCloseButton(btn, root: root)
    }

    // MARK: - Shared separator

    private static func makeSeparator(color: NSColor) -> NSView {
        let sep = NSView()
        sep.wantsLayer = true
        sep.layer?.backgroundColor = color.withAlphaComponent(0.15).cgColor
        sep.translatesAutoresizingMaskIntoConstraints = false
        return sep
    }
}
