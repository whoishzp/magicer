import SwiftUI

struct CGMainView: View {
    @ObservedObject private var mgr = CGSessionManager.shared

    var body: some View {
        Group {
            if mgr.sessions.isEmpty {
                emptyState
            } else {
                HSplitView {
                    CGSessionListView()
                        .frame(minWidth: 180, maxWidth: 260)
                    CGChatView()
                        .frame(minWidth: 400)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.4))
            Text("暂无会话")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
            Text("AI 调用 CursorGood 后，会话将在此处显示")
                .font(.system(size: 13))
                .foregroundColor(.secondary.opacity(0.7))
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
