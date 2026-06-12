import SwiftUI

struct SettingsView: View {
    @State private var selectedTab: Tab = .reminder
    @ObservedObject private var offWork = OffWorkState.shared

    @ObservedObject private var uiState = UIStateStore.shared
    @State private var tabOrder: [Tab] = SettingsView.loadTabOrder()
    @State private var draggingTab: Tab? = nil

    private let feHelperPublisher = NotificationCenter.default
        .publisher(for: .openFeHelperPanel)
    private let cursorGoodPublisher = NotificationCenter.default
        .publisher(for: .openCursorGoodPanel)

    enum Tab: String, CaseIterable, Equatable {
        case reminder     = "定时提醒"
        case cursorGood   = "CursorGood"
        case feHelper     = "Fe助手"
        case appSettings  = "系统设置"

        var icon: String {
            switch self {
            case .reminder:    return "bell.badge.fill"
            case .cursorGood:  return "bubble.left.and.bubble.right.fill"
            case .feHelper:    return "wrench.and.screwdriver.fill"
            case .appSettings: return "gearshape.2.fill"
            }
        }

        /// Tabs that can be reordered (System Settings is always pinned to bottom)
        static var orderable: [Tab] { [.reminder, .cursorGood, .feHelper] }
    }

    // MARK: - Tab order persistence

    private static func loadTabOrder() -> [Tab] {
        let raw = UIStateStore.shared.moduleOrder
        guard !raw.isEmpty else { return Tab.orderable }
        let loaded = raw.compactMap { Tab(rawValue: $0) }.filter { $0 != .appSettings }
        let missing = Tab.orderable.filter { !loaded.contains($0) }
        return loaded + missing
    }

    private func saveTabOrder() {
        uiState.moduleOrder = tabOrder.map(\.rawValue)
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Divider()
            content
        }
        .frame(minWidth: 780, minHeight: 500)
        .background(Color(NSColor.windowBackgroundColor))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                offWorkButton
            }
        }
        .onReceive(feHelperPublisher) { _ in
            withAnimation(.easeInOut(duration: 0.15)) { selectedTab = .feHelper }
        }
        .onReceive(cursorGoodPublisher) { _ in
            withAnimation(.easeInOut(duration: 0.15)) { selectedTab = .cursorGood }
        }
    }

    // MARK: - Left Sidebar

    private var sidebarCollapsed: Bool { uiState.sidebarCollapsed }
    private var sidebarWidth: CGFloat { sidebarCollapsed ? 52 : 168 }

    private var sidebar: some View {
        VStack(alignment: sidebarCollapsed ? .center : .leading, spacing: 6) {
            ForEach(tabOrder, id: \.self) { tab in
                sidebarTabButton(tab)
                    .onDrag {
                        draggingTab = tab
                        return NSItemProvider(object: tab.rawValue as NSString)
                    }
                    .onDrop(
                        of: ["public.plain-text"],
                        delegate: TabDropDelegate(
                            target: tab,
                            tabs: $tabOrder,
                            dragging: $draggingTab,
                            onReorder: saveTabOrder
                        )
                    )
            }

            Spacer()

            sidebarTabButton(.appSettings)

            sidebarCollapseButton

            if !sidebarCollapsed {
                versionLabel
            }
        }
        .padding(.horizontal, sidebarCollapsed ? 6 : 12)
        .padding(.vertical, 18)
        .frame(width: sidebarWidth)
        .background(Color(NSColor.controlBackgroundColor))
        .animation(.easeInOut(duration: 0.2), value: sidebarCollapsed)
    }

    private var sidebarCollapseButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) { uiState.sidebarCollapsed.toggle() }
        } label: {
            Image(systemName: sidebarCollapsed ? "sidebar.left" : "sidebar.left")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary.opacity(0.6))
                .frame(width: sidebarCollapsed ? 36 : nil)
                .frame(maxWidth: sidebarCollapsed ? .infinity : nil)
                .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .help(sidebarCollapsed ? "展开侧栏" : "折叠侧栏")
    }

    private var versionLabel: some View {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        return Text("v\(version)")
            .font(.system(size: 11))
            .foregroundColor(Color.secondary.opacity(0.6))
            .padding(.horizontal, 12)
            .padding(.bottom, 4)
    }

    private func sidebarTabButton(_ tab: Tab) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) { selectedTab = tab }
        } label: {
            if sidebarCollapsed {
                Image(systemName: tab.icon)
                    .font(.system(size: 15, weight: .medium))
                    .frame(width: 36, height: 32)
                    .foregroundColor(selectedTab == tab ? .white : .secondary)
            } else {
                HStack(spacing: 8) {
                    Image(systemName: tab.icon)
                        .font(.system(size: 13, weight: .medium))
                        .frame(width: 18)
                    Text(tab.rawValue)
                        .font(.system(size: 13, weight: .medium))
                        .lineLimit(1)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .foregroundColor(selectedTab == tab ? .white : .secondary)
            }
        }
        .buttonStyle(GlassTabButtonStyle(isSelected: selectedTab == tab, cornerRadius: sidebarCollapsed ? 10 : 8))
        .help(sidebarCollapsed ? tab.rawValue : "")
    }

    // MARK: - Off-Work Button

    private var offWorkButton: some View {
        Button {
            if offWork.isActive {
                OffWorkManager.shared.exit(restore: true)
            } else {
                OffWorkManager.shared.enter()
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: offWork.isActive ? "moon.zzz.fill" : "moon.zzz")
                    .font(.system(size: 12, weight: .medium))
                Text(offWork.isActive ? "取消下班" : "下班")
                    .font(.system(size: 13, weight: .semibold))
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 6)
            .background(offWork.isActive ? Color.orange : Color(NSColor.systemRed))
            .foregroundColor(.white)
            .cornerRadius(7)
        }
        .buttonStyle(.plain)
        .help(offWork.isActive ? "退出下班模式，恢复提醒计时" : "进入下班模式：黑幕遮屏，暂停所有提醒")
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch selectedTab {
        case .appSettings: AppSettingsView(embedded: true)
        case .reminder:    ReminderView()
        case .cursorGood:  CGMainView()
        case .feHelper:    FeHelperView()
        }
    }
}

// MARK: - Drag & Drop Delegate

private struct TabDropDelegate: DropDelegate {
    let target: SettingsView.Tab
    @Binding var tabs: [SettingsView.Tab]
    @Binding var dragging: SettingsView.Tab?
    let onReorder: () -> Void

    func dropEntered(info: DropInfo) {
        guard let dragging = dragging,
              dragging != target,
              let from = tabs.firstIndex(of: dragging),
              let to   = tabs.firstIndex(of: target) else { return }
        withAnimation {
            tabs.move(fromOffsets: IndexSet(integer: from),
                      toOffset: to > from ? to + 1 : to)
        }
    }

    func performDrop(info: DropInfo) -> Bool {
        dragging = nil
        onReorder()
        return true
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
}
