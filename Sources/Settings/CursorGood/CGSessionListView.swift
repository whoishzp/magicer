import SwiftUI

struct CGSessionListView: View {
    @ObservedObject private var mgr = CGSessionManager.shared
    @State private var archiveExpanded = false

    private static let archiveThreshold: TimeInterval = 24 * 3600

    private var activeSessions: [CGSession] {
        mgr.sessions.filter { !$0.isArchived && Date().timeIntervalSince($0.updatedAt) < Self.archiveThreshold }
    }
    private var archivedSessions: [CGSession] {
        mgr.sessions.filter { $0.isArchived || Date().timeIntervalSince($0.updatedAt) >= Self.archiveThreshold }
    }

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
        .frame(maxWidth: .infinity)
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
                ForEach(activeSessions) { session in
                    sessionRow(session)
                }

                if !archivedSessions.isEmpty {
                    archiveSection
                }
            }
            .padding(.vertical, 6)
        }
    }

    // MARK: - Archive section

    private var archiveSection: some View {
        VStack(spacing: 2) {
            Button {
                withAnimation(.easeInOut(duration: 0.15)) { archiveExpanded.toggle() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: archiveExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(width: 12)
                    Text("归档 (\(archivedSessions.count))")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 6)
            }
            .buttonStyle(.plain)

            if archiveExpanded {
                ForEach(archivedSessions) { session in
                    sessionRow(session)
                }
            }
        }
        .padding(.top, 4)
    }

    @ViewBuilder
    private func sessionRow(_ session: CGSession) -> some View {
        let isSelected = mgr.selectedSessionId == session.id
        let hasPending = mgr.hasPendingCall(for: session.id)

        Button {
            mgr.selectedSessionId = session.id
            mgr.markRead(sessionId: session.id)
        } label: {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(session.displayTitle)
                            .font(.system(size: 13, weight: session.hasUnread ? .bold : .medium))
                            .lineLimit(1)
                            .foregroundColor(isSelected ? .white : .primary)
                        if hasPending {
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 7, height: 7)
                        }
                        if session.hasUnread && !isSelected {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 8, height: 8)
                        }
                    }
                    Text(session.updatedAt, style: .relative)
                        .font(.system(size: 11))
                        .foregroundColor(isSelected ? .white.opacity(0.7) : .secondary)
                }
                Spacer()
                if !session.isArchived {
                    SessionEndButton(sessionId: session.id, isSelected: isSelected)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .buttonStyle(GlassTabButtonStyle(isSelected: isSelected, cornerRadius: 6))
        .padding(.horizontal, 6)
        .contextMenu {
            if !session.isArchived {
                Button {
                    mgr.endSession(id: session.id)
                } label: {
                    Label("结束会话", systemImage: "stop.circle")
                }
            }
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

// MARK: - Session end button (hover to reveal)

private struct SessionEndButton: View {
    let sessionId: String
    let isSelected: Bool
    @State private var isHovering = false

    var body: some View {
        Image(systemName: "stop.circle")
            .font(.system(size: 13))
            .foregroundColor(isSelected ? .white.opacity(isHovering ? 1 : 0.5) : .secondary.opacity(isHovering ? 1 : 0.4))
            .onHover { isHovering = $0 }
            .onTapGesture {
                CGSessionManager.shared.endSession(id: sessionId)
            }
            .help("结束并归档会话")
    }
}
