import SwiftUI

struct CGSessionListView: View {
    @ObservedObject private var mgr = CGSessionManager.shared

    var body: some View {
        VStack(spacing: 0) {
            listHeader
            Divider()
            if mgr.sessions.isEmpty {
                emptyState
            } else {
                sessionList
            }
        }
        .frame(width: 220)
        .background(Color(NSColor.controlBackgroundColor))
    }

    // MARK: - Header

    private var listHeader: some View {
        HStack {
            Text("会话")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    // MARK: - List

    private var sessionList: some View {
        ScrollView(.vertical, showsIndicators: true) {
            LazyVStack(spacing: 2) {
                ForEach(mgr.sessions) { session in
                    sessionRow(session)
                }
            }
            .padding(.vertical, 6)
        }
    }

    @ViewBuilder
    private func sessionRow(_ session: CGSession) -> some View {
        let isSelected = mgr.selectedSessionId == session.id
        let hasPending = mgr.hasPendingCall(for: session.id)

        Button {
            mgr.selectedSessionId = session.id
        } label: {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(session.displayTitle)
                            .font(.system(size: 13, weight: .medium))
                            .lineLimit(1)
                            .foregroundColor(isSelected ? .white : .primary)
                        if hasPending {
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 7, height: 7)
                        }
                    }
                    Text(session.updatedAt, style: .relative)
                        .font(.system(size: 11))
                        .foregroundColor(isSelected ? .white.opacity(0.7) : .secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .buttonStyle(GlassTabButtonStyle(isSelected: isSelected, cornerRadius: 6))
        .padding(.horizontal, 6)
        .contextMenu {
            Button("删除会话", role: .destructive) {
                mgr.deleteSession(id: session.id)
            }
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 32))
                .foregroundColor(.secondary.opacity(0.5))
            Text("暂无会话")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
            Text("AI 调用 CursorGood 后\n会话将在此处显示")
                .font(.system(size: 11))
                .foregroundColor(.secondary.opacity(0.7))
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding()
    }
}
