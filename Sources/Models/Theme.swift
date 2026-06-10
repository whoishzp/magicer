import AppKit
import SwiftUI

// MARK: - Overlay Layout Style

enum OverlayLayout {
    case dramatic    // 深红警告：超大标题 + 分隔线，警报感
    case serene      // 深蓝平静：大圆形图标，文字在下
    case nature      // 深绿清新：左对齐 + 大叶片装饰
    case terminal    // 黑白极简：终端/代码风
    case gentle      // 温柔杏：花朵装饰顶部 + 圆角文字框
    case playful     // 少女粉：星星爱心装饰，活泼排版
    case colorful    // 马卡龙：色块左侧竖条，加粗标题
    case technical   // 冷库冰蓝：系统日志风，标签值对
}

// MARK: - ThemeColors

struct ThemeColors {
    let id: String
    let name: String
    let background: NSColor
    let primary: NSColor
    let secondary: NSColor
    let isDark: Bool
    let overlayLayout: OverlayLayout
    /// Vivid orb colors for the gradient-blob overlay background.
    let orbColor1: NSColor
    let orbColor2: NSColor

    var swiftUIBackground: Color { Color(background) }
    var swiftUIPrimary: Color { Color(primary) }
    var swiftUISecondary: Color { Color(secondary) }

    var countdownColor: NSColor {
        isDark ? NSColor(white: 0.52, alpha: 1) : NSColor(white: 0.42, alpha: 1)
    }

    var bodyTextColor: NSColor { secondary }
    var titleTextColor: NSColor { primary }

    // MARK: Overlay text colors (unified gradient layout)
    /// Large clock text color — white on dark themes, primary on light themes.
    var overlayClockColor: NSColor {
        isDark ? .white : primary
    }
    /// Body/reminder text color for the gradient overlay.
    var overlayBodyColor: NSColor {
        isDark ? NSColor(white: 0.82, alpha: 1) : secondary
    }
    /// Overlay countdown text color.
    var overlayCountdownColor: NSColor {
        isDark ? NSColor(white: 0.50, alpha: 1) : NSColor(white: 0.45, alpha: 1)
    }
    /// Date label color (below the big clock).
    var overlayDateColor: NSColor {
        isDark ? NSColor(white: 0.70, alpha: 1) : primary.withAlphaComponent(0.60)
    }
    /// Rule name label color (small, above clock).
    var overlayNameColor: NSColor {
        isDark ? NSColor(white: 1, alpha: 0.55) : primary.withAlphaComponent(0.55)
    }
    /// Font weight for the big clock display.
    var clockFontWeight: NSFont.Weight {
        switch id {
        case "blue-calm":    return .ultraLight
        case "mono-minimal": return .regular
        case "frosted":      return .medium
        case "gentle":       return .semibold
        default:             return .bold
        }
    }

    var swiftUILabelColor: Color {
        isDark ? .white : Color(primary)
    }

    static let all: [ThemeColors] = [
        redAlarm, blueCalm, greenFresh, monoMinimal,
        gentle, pink, macaron, frosted,
    ]

    // MARK: - Dark Themes

    static let redAlarm = ThemeColors(
        id: "red-alarm",
        name: "深红警告",
        background: NSColor(red: 8/255, green: 0/255, blue: 14/255, alpha: 1),
        primary: NSColor(red: 1.0, green: 52/255, blue: 52/255, alpha: 1),
        secondary: NSColor(red: 1.0, green: 162/255, blue: 162/255, alpha: 1),
        isDark: true,
        overlayLayout: .dramatic,
        orbColor1: NSColor(red: 1.0, green: 30/255, blue: 30/255, alpha: 1),
        orbColor2: NSColor(red: 200/255, green: 0/255, blue: 120/255, alpha: 1)
    )

    static let blueCalm = ThemeColors(
        id: "blue-calm",
        name: "深蓝平静",
        background: NSColor(red: 2/255, green: 10/255, blue: 26/255, alpha: 1),
        primary: NSColor(red: 74/255, green: 158/255, blue: 1.0, alpha: 1),
        secondary: NSColor(red: 160/255, green: 200/255, blue: 1.0, alpha: 1),
        isDark: true,
        overlayLayout: .serene,
        orbColor1: NSColor(red: 50/255, green: 130/255, blue: 1.0, alpha: 1),
        orbColor2: NSColor(red: 80/255, green: 30/255, blue: 220/255, alpha: 1)
    )

    static let greenFresh = ThemeColors(
        id: "green-fresh",
        name: "深绿清新",
        background: NSColor(red: 2/255, green: 16/255, blue: 8/255, alpha: 1),
        primary: NSColor(red: 61/255, green: 196/255, blue: 106/255, alpha: 1),
        secondary: NSColor(red: 160/255, green: 230/255, blue: 180/255, alpha: 1),
        isDark: true,
        overlayLayout: .nature,
        orbColor1: NSColor(red: 30/255, green: 210/255, blue: 80/255, alpha: 1),
        orbColor2: NSColor(red: 0/255, green: 200/255, blue: 180/255, alpha: 1)
    )

    static let monoMinimal = ThemeColors(
        id: "mono-minimal",
        name: "黑白极简",
        background: NSColor(white: 0.067, alpha: 1),
        primary: NSColor(white: 0.93, alpha: 1),
        secondary: NSColor(white: 0.70, alpha: 1),
        isDark: true,
        overlayLayout: .terminal,
        orbColor1: NSColor(white: 0.70, alpha: 1),
        orbColor2: NSColor(white: 0.40, alpha: 1)
    )

    // MARK: - Light / Soft Themes

    static let gentle = ThemeColors(
        id: "gentle",
        name: "温柔杏",
        background: NSColor(red: 255/255, green: 244/255, blue: 234/255, alpha: 1),
        primary: NSColor(red: 200/255, green: 98/255, blue: 80/255, alpha: 1),
        secondary: NSColor(red: 160/255, green: 72/255, blue: 58/255, alpha: 1),
        isDark: false,
        overlayLayout: .gentle,
        orbColor1: NSColor(red: 255/255, green: 140/255, blue: 80/255, alpha: 1),
        orbColor2: NSColor(red: 255/255, green: 100/255, blue: 130/255, alpha: 1)
    )

    static let pink = ThemeColors(
        id: "pink",
        name: "少女粉",
        background: NSColor(red: 255/255, green: 243/255, blue: 248/255, alpha: 1),
        primary: NSColor(red: 220/255, green: 60/255, blue: 110/255, alpha: 1),
        secondary: NSColor(red: 180/255, green: 40/255, blue: 85/255, alpha: 1),
        isDark: false,
        overlayLayout: .playful,
        orbColor1: NSColor(red: 240/255, green: 50/255, blue: 120/255, alpha: 1),
        orbColor2: NSColor(red: 160/255, green: 60/255, blue: 230/255, alpha: 1)
    )

    static let macaron = ThemeColors(
        id: "macaron",
        name: "马卡龙",
        background: NSColor(red: 248/255, green: 242/255, blue: 255/255, alpha: 1),
        primary: NSColor(red: 145/255, green: 100/255, blue: 210/255, alpha: 1),
        secondary: NSColor(red: 110/255, green: 72/255, blue: 170/255, alpha: 1),
        isDark: false,
        overlayLayout: .colorful,
        orbColor1: NSColor(red: 160/255, green: 90/255, blue: 240/255, alpha: 1),
        orbColor2: NSColor(red: 60/255, green: 200/255, blue: 180/255, alpha: 1)
    )

    static let frosted = ThemeColors(
        id: "frosted",
        name: "冷库冰蓝",
        background: NSColor(red: 236/255, green: 246/255, blue: 255/255, alpha: 1),
        primary: NSColor(red: 40/255, green: 115/255, blue: 185/255, alpha: 1),
        secondary: NSColor(red: 25/255, green: 88/255, blue: 148/255, alpha: 1),
        isDark: false,
        overlayLayout: .technical,
        orbColor1: NSColor(red: 60/255, green: 160/255, blue: 255/255, alpha: 1),
        orbColor2: NSColor(red: 30/255, green: 80/255, blue: 200/255, alpha: 1)
    )

    static func find(_ id: String) -> ThemeColors {
        return all.first { $0.id == id } ?? redAlarm
    }
}
