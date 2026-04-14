import SwiftUI

/// Full-size preview window simulating the actual overlay appearance.
struct ThemePreviewView: View {
    let theme: ThemeColors
    let reminderText: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color(theme.background).ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 0)

                // Title
                Text("⏸  工作中断提醒")
                    .font(.system(size: 44, weight: .black))
                    .foregroundColor(Color(theme.titleTextColor))
                    .multilineTextAlignment(.center)

                // Separator
                Rectangle()
                    .fill(Color(theme.bodyTextColor).opacity(0.25))
                    .frame(height: 1)
                    .frame(maxWidth: 420)
                    .padding(.top, 20)
                    .padding(.bottom, 30)

                // Reminder text
                Text(reminderText.isEmpty ? "（这里是你的提醒内容）" : reminderText)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(Color(theme.bodyTextColor))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                // Countdown placeholder
                Text("10 秒后可关闭…")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(Color(theme.countdownColor))
                    .padding(.top, 40)

                // Close button preview
                HStack {
                    Text("✓   我知道了，开始休息")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 14)
                        .background(Color(theme.primary).opacity(0.7))
                        .cornerRadius(12)
                }
                .padding(.top, 12)
                .opacity(0.6)

                Text("（按 Enter 4 次或等倒计时结束后可关闭）")
                    .font(.system(size: 11))
                    .foregroundColor(Color(theme.bodyTextColor).opacity(0.4))
                    .padding(.top, 10)

                Spacer(minLength: 0)
            }
        }
        .overlay(alignment: .topTrailing) {
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(Color(theme.bodyTextColor).opacity(0.6))
            }
            .buttonStyle(.plain)
            .padding(18)
            .keyboardShortcut(.escape, modifiers: [])
        }
        .overlay(alignment: .bottomLeading) {
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(theme.primary))
                    .frame(width: 10, height: 10)
                Text(theme.name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(theme.bodyTextColor).opacity(0.5))
                Text("· 预览模式")
                    .font(.system(size: 12))
                    .foregroundColor(Color(theme.bodyTextColor).opacity(0.35))
            }
            .padding(16)
        }
    }
}
