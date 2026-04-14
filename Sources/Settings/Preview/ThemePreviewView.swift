import SwiftUI

/// Preview window: matches the actual overlay layout for each theme.
struct ThemePreviewView: View {
    let theme: ThemeColors
    let ruleName: String
    let reminderText: String
    @Environment(\.dismiss) private var dismiss

    private var sampleText: String {
        reminderText.isEmpty ? "（这里是你的提醒内容）" : reminderText
    }

    private var displayName: String {
        ruleName.isEmpty ? "工作中断提醒" : ruleName
    }

    var body: some View {
        ZStack {
            Color(theme.background).ignoresSafeArea()

            // Layout varies per theme
            layoutContent

            // Close overlay
            VStack {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color(theme.bodyTextColor).opacity(0.5))
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.escape, modifiers: [])
                    .padding(14)
                }
                Spacer()
                HStack {
                    HStack(spacing: 6) {
                        Circle().fill(Color(theme.primary)).frame(width: 9, height: 9)
                        Text(theme.name + " · 预览模式")
                            .font(.system(size: 11))
                            .foregroundColor(Color(theme.bodyTextColor).opacity(0.4))
                    }
                    .padding(14)
                    Spacer()
                }
            }
        }
        .frame(width: 720, height: 480)
    }

    // MARK: - Layout Dispatch

    @ViewBuilder
    private var layoutContent: some View {
        switch theme.overlayLayout {
        case .dramatic:  dramaticLayout
        case .serene:    sereneLayout
        case .nature:    natureLayout
        case .terminal:  terminalLayout
        case .gentle:    gentleLayout
        case .playful:   playfulLayout
        case .colorful:  colorfulLayout
        case .technical: technicalLayout
        }
    }

    // MARK: - 1. Dramatic (深红警告)

    private var dramaticLayout: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 90)

            Text("⚠  \(displayName)")
                .font(.system(size: 38, weight: .black))
                .foregroundColor(Color(theme.titleTextColor))
                .multilineTextAlignment(.center)

            Rectangle()
                .fill(Color(theme.primary).opacity(0.6))
                .frame(height: 1)
                .frame(maxWidth: 480)
                .padding(.top, 18)

            Text(sampleText)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(Color(theme.bodyTextColor))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.top, 28)

            countdownLabel.padding(.top, 36)
            closeButtonPreview.padding(.top, 10)

            Spacer()
        }
    }

    // MARK: - 2. Serene (深蓝平静)

    private var sereneLayout: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 80)

            Text("◉")
                .font(.system(size: 80, weight: .ultraLight))
                .foregroundColor(Color(theme.primary).opacity(0.8))

            Text(displayName)
                .font(.system(size: 16, weight: .light))
                .foregroundColor(Color(theme.primary).opacity(0.9))
                .padding(.top, 4)

            Text(sampleText)
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(Color(theme.bodyTextColor))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 60)
                .padding(.top, 24)

            countdownLabel.padding(.top, 32)
            closeButtonPreview.padding(.top, 10)

            Spacer()
        }
    }

    // MARK: - 3. Nature (深绿清新)

    private var natureLayout: some View {
        HStack(alignment: .top, spacing: 0) {
            Spacer().frame(width: 60)

            // Vertical accent bar
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(theme.primary).opacity(0.7))
                .frame(width: 5, height: 200)
                .padding(.top, 80)

            VStack(alignment: .leading, spacing: 10) {
                Spacer().frame(height: 80)

                Text("🌿")
                    .font(.system(size: 56))

                Text(displayName)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(Color(theme.titleTextColor))

                Text(sampleText)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(Color(theme.bodyTextColor))
                    .padding(.top, 8)
                    .frame(maxWidth: 460, alignment: .leading)

                countdownLabel
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 20)
                closeButtonPreview.padding(.top, 8)

                Spacer()
            }
            .padding(.leading, 20)

            Spacer()
        }
    }

    // MARK: - 4. Terminal (黑白极简)

    private var terminalLayout: some View {
        HStack(alignment: .top, spacing: 0) {
            Spacer().frame(width: 110)

            VStack(alignment: .leading, spacing: 0) {
                Spacer().frame(height: 100)

                Text("> \(displayName) —")
                    .font(.system(size: 13, weight: .regular, design: .monospaced))
                    .foregroundColor(Color(theme.primary).opacity(0.55))

                Text("─────────────────────────────────────────")
                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                    .foregroundColor(Color(theme.primary).opacity(0.25))
                    .padding(.top, 8)

                Text("  \(sampleText)")
                    .font(.system(size: 18, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(theme.bodyTextColor))
                    .padding(.top, 14)
                    .frame(maxWidth: 480, alignment: .leading)

                countdownLabel
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 24)
                closeButtonPreview.padding(.top, 8)

                Spacer()
            }

            Spacer()
        }
    }

    // MARK: - 5. Gentle (温柔杏)

    private var gentleLayout: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 60)

            Text("🌸  🌸  🌸  🌸  🌸")
                .font(.system(size: 28))

            Text(displayName)
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(Color(theme.titleTextColor))
                .padding(.top, 14)

            // Rounded container
            Text(sampleText)
                .font(.system(size: 19, weight: .medium))
                .foregroundColor(Color(theme.bodyTextColor))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
                .padding(.vertical, 20)
                .frame(maxWidth: 500)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(theme.primary).opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(theme.primary).opacity(0.2), lineWidth: 1.5)
                        )
                )
                .padding(.top, 20)

            countdownLabel.padding(.top, 20)
            closeButtonPreview.padding(.top, 8)
            Spacer()
        }
        .padding(.horizontal, 40)
    }

    // MARK: - 6. Playful (少女粉)

    private var playfulLayout: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 60)

            Text("✨  💕  ✨")
                .font(.system(size: 32))

            Text("✨ \(displayName) ✨")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(Color(theme.titleTextColor))
                .padding(.top, 6)

            Text(sampleText)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(Color(theme.bodyTextColor))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.top, 24)

            Text("♡  ♡  ♡  ♡  ♡  ♡")
                .font(.system(size: 18))
                .foregroundColor(Color(theme.primary).opacity(0.4))
                .padding(.top, 18)

            countdownLabel.padding(.top, 16)
            closeButtonPreview.padding(.top, 8)
            Spacer()
        }
    }

    // MARK: - 7. Colorful (马卡龙)

    private var colorfulLayout: some View {
        HStack(alignment: .top, spacing: 0) {
            Spacer().frame(width: 60)

            VStack(alignment: .leading, spacing: 0) {
                Spacer().frame(height: 70)

                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(theme.primary).opacity(0.12))
                        .frame(width: 380, height: 145)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("🍭")
                            .font(.system(size: 46))
                        Text(displayName)
                            .font(.system(size: 36, weight: .heavy))
                            .foregroundColor(Color(theme.titleTextColor))
                        Text("— BREAK TIME —")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(theme.primary).opacity(0.6))
                    }
                    .padding(14)
                }

                Text(sampleText)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color(theme.bodyTextColor))
                    .frame(maxWidth: 480, alignment: .leading)
                    .padding(.top, 28)

                countdownLabel
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 24)
                closeButtonPreview.padding(.top, 8)

                Spacer()
            }

            Spacer()
        }
    }

    // MARK: - 8. Technical (冷库冰蓝)

    private var technicalLayout: some View {
        HStack(alignment: .top, spacing: 0) {
            Spacer().frame(width: 90)

            VStack(alignment: .leading, spacing: 0) {
                Spacer().frame(height: 100)

                Text("SYSTEM  ══════════════════════════════")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(theme.primary).opacity(0.7))

                Group {
                    Text("RULE     : \(displayName)")
                    Text("REMINDER : \(sampleText)")
                }
                .font(.system(size: 13, weight: .regular, design: .monospaced))
                .foregroundColor(Color(theme.bodyTextColor))
                .padding(.top, 10)

                Text("──────────────────────────────────────")
                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                    .foregroundColor(Color(theme.primary).opacity(0.3))
                    .padding(.top, 14)

                countdownLabel
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 14)
                closeButtonPreview.padding(.top, 8)

                Spacer()
            }
            .frame(maxWidth: 580, alignment: .leading)

            Spacer()
        }
    }

    // MARK: - Shared Sub-views

    private var countdownLabel: some View {
        Text("10 秒后可关闭…")
            .font(.system(size: 14, weight: .regular))
            .foregroundColor(Color(theme.countdownColor))
    }

    private var closeButtonPreview: some View {
        Text("✓   我知道了，开始休息")
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 22)
            .padding(.vertical, 11)
            .background(Color(theme.primary).opacity(0.65))
            .cornerRadius(10)
            .opacity(0.65)
    }
}
