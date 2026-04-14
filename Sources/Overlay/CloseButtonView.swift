import AppKit

/// AppKit close button rendered in every overlay window.
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
        addTrackingArea(NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways],
            owner: self, userInfo: nil
        ))
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
