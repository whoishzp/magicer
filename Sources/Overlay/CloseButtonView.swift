import AppKit

/// Ghost-style close button rendered in the bottom-right corner of every overlay window.
/// Subtle by design: semi-transparent border + fill, brightens on hover.
class CloseButtonView: NSView {
    private let theme: ThemeColors
    private let text: String
    private var hovered = false { didSet { needsDisplay = true } }

    init(theme: ThemeColors, text: String) {
        self.theme = theme
        self.text = text
        super.init(frame: .zero)
        wantsLayer = true
        updateTrackingAreas()
    }
    required init?(coder: NSCoder) { fatalError() }

    override var intrinsicContentSize: NSSize {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 14, weight: .medium)
        ]
        let w = (text as NSString).size(withAttributes: attrs).width + 40
        return NSSize(width: max(w, 100), height: 38)
    }

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
        let bgAlpha: CGFloat = hovered ? 0.22 : 0.10
        theme.primary.withAlphaComponent(bgAlpha).setFill()
        let path = NSBezierPath(roundedRect: bounds, xRadius: 10, yRadius: 10)
        path.fill()

        theme.primary.withAlphaComponent(hovered ? 0.55 : 0.28).setStroke()
        path.lineWidth = 1.0
        path.stroke()

        let textAlpha: CGFloat = hovered ? 0.95 : 0.65
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 14, weight: .medium),
            .foregroundColor: theme.primary.withAlphaComponent(textAlpha),
        ]
        let sz = (text as NSString).size(withAttributes: attrs)
        let pt = CGPoint(x: (bounds.width - sz.width) / 2, y: (bounds.height - sz.height) / 2)
        (text as NSString).draw(at: pt, withAttributes: attrs)
    }

    override func resetCursorRects() { addCursorRect(bounds, cursor: .pointingHand) }
}
