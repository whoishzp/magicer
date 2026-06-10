import SwiftUI

struct ThemePreviewView: View {
    let theme: ThemeColors
    let ruleName: String
    let reminderText: String
    @Environment(\.dismiss) private var dismiss

    @State private var clockString: String = ""
    private let clockTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var sampleText: String {
        reminderText.isEmpty ? "（这里是你的提醒内容）" : reminderText
    }

    private var displayName: String {
        ruleName.isEmpty ? "工作中断提醒" : ruleName
    }

    var body: some View {
        ZStack {
            Color(theme.background).ignoresSafeArea()

            layoutContent

            // Top-right dismiss button
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
                // Theme badge + close button preview (bottom-right)
                HStack {
                    HStack(spacing: 6) {
                        Circle().fill(Color(theme.primary)).frame(width: 9, height: 9)
                        Text(theme.name + " · 预览模式")
                            .font(.system(size: 11))
                            .foregroundColor(Color(theme.bodyTextColor).opacity(0.4))
                    }
                    .padding(14)
                    Spacer()
                    closeButtonPreview
                        .padding(.trailing, 20)
                        .padding(.bottom, 14)
                }
            }
        }
        .frame(width: 720, height: 480)
        .onAppear {
            clockString = Self.currentTimeString()
        }
        .onReceive(clockTimer) { _ in
            clockString = Self.currentTimeString()
        }
    }

    private static func currentTimeString() -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return fmt.string(from: Date())
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
            Spacer().frame(height: 70)

            Text("⚠  \(displayName)")
                .font(.system(size: 28, weight: .black))
                .foregroundColor(Color(theme.titleTextColor))
                .multilineTextAlignment(.center)

            Rectangle()
                .fill(Color(theme.primary).opacity(0.6))
                .frame(height: 1)
                .frame(maxWidth: 480)
                .padding(.top, 14)

            Text(clockString)
                .font(.system(size: 40, weight: .bold, design: .monospaced))
                .foregroundColor(Color(theme.primary))
                .padding(.top, 22)

            Text(sampleText)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(theme.bodyTextColor))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.top, 22)

            countdownLabel.padding(.top, 28)
            Spacer()
        }
    }

    // MARK: - 2. Serene (深蓝平静)

    private var sereneLayout: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 70)

            Text(displayName)
                .font(.system(size: 14, weight: .light))
                .foregroundColor(Color(theme.primary).opacity(0.65))

            Text(clockString)
                .font(.system(size: 44, weight: .ultraLight, design: .monospaced))
                .foregroundColor(Color(theme.primary))
                .padding(.top, 12)

            Text(sampleText)
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(Color(theme.bodyTextColor))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 60)
                .padding(.top, 28)

            countdownLabel.padding(.top, 28)
            Spacer()
        }
    }

    // MARK: - 3. Nature (深绿清新)

    private var natureLayout: some View {
        HStack(alignment: .top, spacing: 0) {
            Spacer().frame(width: 60)

            RoundedRectangle(cornerRadius: 3)
                .fill(Color(theme.primary).opacity(0.6))
                .frame(width: 5, height: 220)
                .padding(.top, 70)

            VStack(alignment: .leading, spacing: 0) {
                Spacer().frame(height: 70)

                Text("🌿")
                    .font(.system(size: 44))

                Text(displayName)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color(theme.titleTextColor))
                    .padding(.top, 6)

                Text(clockString)
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(theme.primary))
                    .padding(.top, 8)

                Text(sampleText)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(Color(theme.bodyTextColor))
                    .padding(.top, 14)
                    .frame(maxWidth: 400, alignment: .leading)

                countdownLabel
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 18)

                Spacer()
            }
            .padding(.leading, 20)

            Spacer()
        }
    }

    // MARK: - 4. Terminal (黑白极简)

    private var terminalLayout: some View {
        HStack(alignment: .top, spacing: 0) {
            Spacer().frame(width: 90)

            VStack(alignment: .leading, spacing: 0) {
                Spacer().frame(height: 80)

                Text("> ALERT ─────────────────────────────────")
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundColor(Color(theme.primary).opacity(0.50))

                Text("  RULE   : \(displayName)")
                    .font(.system(size: 13, weight: .regular, design: .monospaced))
                    .foregroundColor(Color(theme.bodyTextColor))
                    .padding(.top, 10)

                HStack(spacing: 0) {
                    Text("  TIME   : ")
                        .font(.system(size: 20, weight: .medium, design: .monospaced))
                        .foregroundColor(Color(theme.bodyTextColor).opacity(0.55))
                    Text(clockString)
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(theme.primary))
                }
                .padding(.top, 8)

                Text("  NOTICE : \(sampleText)")
                    .font(.system(size: 13, weight: .regular, design: .monospaced))
                    .foregroundColor(Color(theme.bodyTextColor))
                    .frame(maxWidth: 460, alignment: .leading)
                    .padding(.top, 8)

                Text("─────────────────────────────────────────")
                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                    .foregroundColor(Color(theme.primary).opacity(0.25))
                    .padding(.top, 14)

                countdownLabel
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 12)

                Spacer()
            }

            Spacer()
        }
    }

    // MARK: - 5. Gentle (温柔杏)

    private var gentleLayout: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 44)

            Text("🌸  🌸  🌸  🌸  🌸")
                .font(.system(size: 24))

            Text(displayName)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(Color(theme.titleTextColor))
                .padding(.top, 12)

            // Clock card
            Text(clockString)
                .font(.system(size: 32, weight: .medium, design: .monospaced))
                .foregroundColor(Color(theme.titleTextColor))
                .padding(.horizontal, 28)
                .padding(.vertical, 16)
                .frame(maxWidth: 500)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(theme.primary).opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color(theme.primary).opacity(0.22), lineWidth: 1.5)
                        )
                )
                .padding(.top, 16)

            Text(sampleText)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color(theme.bodyTextColor))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.top, 16)

            countdownLabel.padding(.top, 16)
            Spacer()
        }
        .padding(.horizontal, 40)
    }

    // MARK: - 6. Playful (少女粉)

    private var playfulLayout: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 44)

            Text("✨  💕  ✨")
                .font(.system(size: 28))

            Text("✨ \(displayName) ✨")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Color(theme.titleTextColor))
                .padding(.top, 6)

            Text(clockString)
                .font(.system(size: 38, weight: .bold, design: .monospaced))
                .foregroundColor(Color(theme.primary))
                .padding(.top, 18)

            Text(sampleText)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color(theme.bodyTextColor))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.top, 18)

            Text("♡  ♡  ♡  ♡  ♡  ♡")
                .font(.system(size: 16))
                .foregroundColor(Color(theme.primary).opacity(0.38))
                .padding(.top, 14)

            countdownLabel.padding(.top, 12)
            Spacer()
        }
    }

    // MARK: - 7. Colorful (马卡龙)

    private var colorfulLayout: some View {
        HStack(alignment: .top, spacing: 0) {
            Spacer().frame(width: 50)

            VStack(alignment: .leading, spacing: 0) {
                Spacer().frame(height: 56)

                // Clock block
                VStack(alignment: .leading, spacing: 4) {
                    Text(clockString)
                        .font(.system(size: 32, weight: .heavy, design: .monospaced))
                        .foregroundColor(Color(theme.titleTextColor))
                    Text(displayName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(theme.primary).opacity(0.70))
                    Text("— BREAK TIME —")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color(theme.primary).opacity(0.50))
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(theme.primary).opacity(0.12))
                )
                .frame(maxWidth: 420, alignment: .leading)

                Text(sampleText)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(theme.bodyTextColor))
                    .frame(maxWidth: 440, alignment: .leading)
                    .padding(.top, 22)

                countdownLabel
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 18)

                Spacer()
            }

            Spacer()
        }
    }

    // MARK: - 8. Technical (冷库冰蓝)

    private var technicalLayout: some View {
        HStack(alignment: .top, spacing: 0) {
            Spacer().frame(width: 70)

            VStack(alignment: .leading, spacing: 0) {
                Spacer().frame(height: 80)

                Text("SYSTEM  ══════════════════════════════")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(theme.primary).opacity(0.65))

                Text("RULE     : \(displayName)")
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundColor(Color(theme.bodyTextColor))
                    .padding(.top, 12)

                HStack(spacing: 0) {
                    Text("TIME     : ")
                        .font(.system(size: 20, weight: .medium, design: .monospaced))
                        .foregroundColor(Color(theme.bodyTextColor).opacity(0.55))
                    Text(clockString)
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(theme.primary))
                }
                .padding(.top, 8)

                Text("REMINDER : \(sampleText)")
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundColor(Color(theme.bodyTextColor))
                    .frame(maxWidth: 500, alignment: .leading)
                    .padding(.top, 8)

                Text("──────────────────────────────────────")
                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                    .foregroundColor(Color(theme.primary).opacity(0.28))
                    .padding(.top, 12)

                countdownLabel
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 12)

                Spacer()
            }
            .frame(maxWidth: 560, alignment: .leading)

            Spacer()
        }
    }

    // MARK: - Shared Sub-views

    private var countdownLabel: some View {
        Text("10 秒后可关闭")
            .font(.system(size: 12, weight: .regular))
            .foregroundColor(Color(theme.countdownColor))
    }

    private var closeButtonPreview: some View {
        Text("OK")
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(Color(theme.primary).opacity(0.70))
            .padding(.horizontal, 18)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 9)
                    .fill(Color(theme.primary).opacity(0.10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 9)
                            .stroke(Color(theme.primary).opacity(0.30), lineWidth: 1)
                    )
            )
    }
}
