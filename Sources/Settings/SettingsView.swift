import SwiftUI

struct SettingsView: View {
    @State private var selectedTab: Tab = .reminder
    @ObservedObject private var offWork = OffWorkState.shared

    // Orderable tabs (excludes appSettings which is always at bottom)
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

    private static let orderKey = "one_module_order_v1"

    private static func loadTabOrder() -> [Tab] {
        guard let raw = UserDefaults.standard.array(forKey: orderKey) as? [String] else {
            return Tab.orderable
        }
        let loaded = raw.compactMap { Tab(rawValue: $0) }.filter { $0 != .appSettings }
        // Ensure all orderable tabs present (in case new tabs are added in future versions)
        let missing = Tab.orderable.filter { !loaded.contains($0) }
        return loaded + missing
    }

    private func saveTabOrder() {
        UserDefaults.standard.set(tabOrder.map(\.rawValue), forKey: SettingsView.orderKey)
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

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Orderable tabs
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

            // System Settings — always pinned at bottom
            sidebarTabButton(.appSettings)

            versionLabel
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 18)
        .frame(width: 156)
        .background(Color(NSColor.controlBackgroundColor))
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
            HStack(spacing: 8) {
                Image(systemName: tab.icon)
                    .font(.system(size: 13, weight: .medium))
                    .frame(width: 18)
                Text(tab.rawValue)
                    .font(.system(size: 13, weight: .medium))
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .foregroundColor(selectedTab == tab ? .white : .secondary)
        }
        .buttonStyle(GlassTabButtonStyle(isSelected: selectedTab == tab, cornerRadius: 8))
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
