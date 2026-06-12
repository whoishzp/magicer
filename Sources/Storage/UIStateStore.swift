import Foundation
import Combine

/// Persists UI preferences (tab order, sidebar state, input height, etc.) via ONEDataStore.
class UIStateStore: ObservableObject {
    static let shared = UIStateStore()
    private static let filename = "ui-state.json"

    @Published var moduleOrder: [String] {
        didSet { persist() }
    }
    @Published var sidebarCollapsed: Bool {
        didSet { persist() }
    }
    @Published var cgInputHeight: Double {
        didSet { persist() }
    }

    private struct UIStateData: Codable {
        var moduleOrder: [String] = []
        var sidebarCollapsed: Bool = false
        var cgInputHeight: Double = 120
    }

    private func persist() {
        let data = UIStateData(
            moduleOrder: moduleOrder,
            sidebarCollapsed: sidebarCollapsed,
            cgInputHeight: cgInputHeight
        )
        ONEDataStore.shared.save(data, to: Self.filename)
    }

    private init() {
        if let saved = ONEDataStore.shared.load(UIStateData.self, from: Self.filename) {
            moduleOrder = saved.moduleOrder
            sidebarCollapsed = saved.sidebarCollapsed
            cgInputHeight = saved.cgInputHeight
        } else {
            // Migrate from UserDefaults
            if let raw = UserDefaults.standard.array(forKey: "one_module_order_v1") as? [String] {
                moduleOrder = raw
            } else { moduleOrder = [] }
            sidebarCollapsed = UserDefaults.standard.bool(forKey: "one_sidebar_collapsed")
            let h = UserDefaults.standard.double(forKey: "cgInputHeight")
            cgInputHeight = h > 0 ? h : 120
            persist()
        }
    }
}
