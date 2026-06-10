import SwiftUI

struct ThemePreviewView: View {
    let theme: ThemeColors
    let ruleName: String
    let reminderText: String
    @Environment(\.dismiss) private var dismiss

    @State private var clockString: String = ""
    private let clockTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var sampleText: String {
        reminderText.isEmpty ? "该休息了，离开屏幕活动一下。" : reminderText
    }
    private var displayName: String {
        ruleName.isEmpty ? "工作中断提醒" : ruleName
    }
    private static func timeString() -> String {
        let f = DateFormatter(); f.dateFormat = "HH:mm:ss"; return f.string(from: Date())
    }
    private static func dateString() -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f.string(from: Date())
    }

    var body: some View {
        ZStack {
            // ── Gradient + orb background ──────────────────────────────
            overlayBackground

            // ── Content (unified layout) ───────────────────────────────
            VStack(spacing: 0) {
                Spacer()

                // Rule name
                Text(displayName)
                    .font(.system(size: 13, weight: .light))
                    .foregroundColor(Color(theme.overlayNameColor))

                // Big clock
                Text(clockString)
                    .font(.system(size: 62, weight: swiftUIClockWeight, design: .monospaced))
                    .foregroundColor(Color(theme.overlayClockColor))
                    .padding(.top, 10)

                // Date
                Text(Self.dateString())
                    .font(.system(size: 14, weight: .light, design: .monospaced))
                    .foregroundColor(Color(theme.overlayDateColor))
                    .padding(.top, 8)

                // Divider
                Rectangle()
                    .fill(Color(theme.overlayClockColor).opacity(0.15))
                    .frame(maxWidth: 360, maxHeight: 1)
                    .padding(.top, 20)

                // Reminder text
                Text(sampleText)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(Color(theme.overlayBodyColor))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 60)
                    .padding(.top, 18)

                // Countdown placeholder
                Text("10 秒后可关闭")
                    .font(.system(size: 11))
                    .foregroundColor(Color(theme.overlayCountdownColor))
                    .padding(.top, 20)

                Spacer()
            }

            // ── Overlay controls ───────────────────────────────────────
            VStack {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color(theme.overlayBodyColor).opacity(0.45))
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.escape, modifiers: [])
                    .padding(14)
                }
                Spacer()
                HStack {
                    HStack(spacing: 6) {
                        Circle().fill(Color(theme.primary)).frame(width: 8, height: 8)
                        Text(theme.name + " · 预览模式")
                            .font(.system(size: 10))
                            .foregroundColor(Color(theme.overlayBodyColor).opacity(0.40))
                    }
                    .padding(14)
                    Spacer()
                    // Ghost close button preview (bottom-right)
                    Text("OK")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(theme.overlayClockColor).opacity(0.65))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 7)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(theme.overlayClockColor).opacity(0.09))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(theme.overlayClockColor).opacity(0.28), lineWidth: 1)
                                )
                        )
                        .padding(.trailing, 16)
                        .padding(.bottom, 12)
                }
            }
        }
        .frame(width: 720, height: 480)
        .onAppear { clockString = Self.timeString() }
        .onReceive(clockTimer) { _ in clockString = Self.timeString() }
    }

    // MARK: - Gradient + orb background

    private var overlayBackground: some View {
        GeometryReader { geo in
            let W = geo.size.width, H = geo.size.height
            ZStack {
                // Base diagonal gradient
                LinearGradient(
                    colors: [Color(theme.background), gradEndColor],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Orb 1 — large, top-left
                Circle()
                    .fill(Color(theme.orbColor1).opacity(0.30))
                    .frame(width: H * 0.80, height: H * 0.80)
                    .offset(x: W * 0.22 - W/2, y: H * 0.28 - H/2)
                    .blur(radius: 18)

                // Orb 2 — medium, bottom-right
                Circle()
                    .fill(Color(theme.orbColor2).opacity(0.22))
                    .frame(width: H * 0.68, height: H * 0.68)
                    .offset(x: W * 0.78 - W/2, y: H * 0.72 - H/2)
                    .blur(radius: 16)

                // Accent orb — small, top-right
                Circle()
                    .fill(Color(theme.orbColor2).opacity(0.14))
                    .frame(width: H * 0.32, height: H * 0.32)
                    .offset(x: W * 0.85 - W/2, y: H * 0.15 - H/2)
                    .blur(radius: 10)
            }
        }
    }

    private var gradEndColor: Color {
        let bg = theme.background
        let orb = theme.orbColor1
        let blended = bg.blended(withFraction: 0.22, of: orb) ?? bg
        return Color(blended)
    }

    private var swiftUIClockWeight: Font.Weight {
        switch theme.clockFontWeight {
        case .ultraLight: return .ultraLight
        case .light:      return .light
        case .regular:    return .regular
        case .medium:     return .medium
        case .semibold:   return .semibold
        case .bold:       return .bold
        case .heavy:      return .heavy
        case .black:      return .black
        default:          return .bold
        }
    }
}
