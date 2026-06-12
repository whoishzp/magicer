import Foundation
import Combine

class RulesStore: ObservableObject {
    static let shared = RulesStore()

    @Published var rules: [ReminderRule] {
        didSet {
            save()
            RuleTimerManager.shared.reload(rules: rules)
        }
    }

    private static let filename = "rules.json"

    private init() {
        if let loaded = ONEDataStore.shared.load([ReminderRule].self, from: Self.filename) {
            rules = loaded
        } else if let data = UserDefaults.standard.data(forKey: "one_rules_v1"),
                  let decoded = try? JSONDecoder().decode([ReminderRule].self, from: data) {
            rules = decoded
            ONEDataStore.shared.save(decoded, to: Self.filename)
        } else {
            rules = [ReminderRule(name: "专注提醒")]
        }
    }

    private func save() {
        ONEDataStore.shared.save(rules, to: Self.filename)
        ReminderSkillExporter.export(rules: rules)
    }

    func addRule() {
        rules.append(ReminderRule(name: "提醒 \(rules.count + 1)"))
    }

    func updateRule(_ rule: ReminderRule) {
        if let idx = rules.firstIndex(where: { $0.id == rule.id }) {
            rules[idx] = rule
        }
    }

    func deleteRules(at offsets: IndexSet) {
        rules.remove(atOffsets: offsets)
    }
}
