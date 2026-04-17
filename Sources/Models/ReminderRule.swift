import Foundation

// MARK: - Action Kind (desktop overlay vs shell script)

/// What happens when the rule fires: full-screen reminder or `/bin/sh -c` script.
enum RuleActionKind: String, Codable {
    case desktop = "desktop"
    case script = "script"
}

// MARK: - Trigger Mode

enum TriggerMode: String, Codable {
    case interval  = "interval"   // 循环：每 X 分钟
    case scheduled = "scheduled"  // 定点：每天指定时刻
    case once      = "once"       // 一次：指定时刻触发一次后自动停用
}

// MARK: - Scheduled Time

struct ScheduledTime: Codable, Identifiable, Equatable {
    var id: UUID
    var hour: Int
    var minute: Int

    init(id: UUID = UUID(), hour: Int, minute: Int) {
        self.id = id
        self.hour = hour
        self.minute = minute
    }

    var displayText: String {
        String(format: "%02d:%02d", hour, minute)
    }
}

// MARK: - ReminderRule

struct ReminderRule: Codable, Identifiable, Equatable {
    var id: UUID
    var name: String
    /// Desktop = overlay; script = run `shellCommand` on the same schedule.
    var actionKind: RuleActionKind
    var triggerMode: TriggerMode
    var intervalMinutes: Int
    var scheduledTimes: [ScheduledTime]
    /// Target datetime for `.once` mode — triggers once then auto-disables.
    var onceDate: Date
    /// After the overlay is dismissed, trigger again after this many minutes (0 = no followup).
    var followupMinutes: Int
    var durationSeconds: Int
    var canCloseImmediately: Bool
    var reminderText: String
    var themeId: String
    var isEnabled: Bool
    /// Shell command for `.script` action (`/bin/sh -c`). Ignored for desktop.
    var shellCommand: String
    /// Directory for per-rule log files (`magicer-{uuid}.log`). Empty = no file logging.
    var logDirectoryPath: String

    // Custom CodingKeys and decoder to maintain backward compatibility.
    // New fields fall back to defaults when absent in stored data.
    private enum CodingKeys: String, CodingKey {
        case id, name, actionKind, triggerMode, intervalMinutes, scheduledTimes
        case onceDate, followupMinutes
        case durationSeconds, canCloseImmediately, reminderText, themeId, isEnabled
        case shellCommand, logDirectoryPath
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id               = try c.decode(UUID.self,            forKey: .id)
        name             = try c.decode(String.self,          forKey: .name)
        actionKind       = (try? c.decode(RuleActionKind.self, forKey: .actionKind)) ?? .desktop
        triggerMode      = (try? c.decode(TriggerMode.self,   forKey: .triggerMode)) ?? .interval
        intervalMinutes  = try c.decode(Int.self,             forKey: .intervalMinutes)
        scheduledTimes   = try c.decode([ScheduledTime].self, forKey: .scheduledTimes)
        onceDate         = (try? c.decode(Date.self,          forKey: .onceDate)) ?? Date().addingTimeInterval(3600)
        followupMinutes  = (try? c.decode(Int.self,           forKey: .followupMinutes)) ?? 0
        durationSeconds  = try c.decode(Int.self,             forKey: .durationSeconds)
        canCloseImmediately = try c.decode(Bool.self,         forKey: .canCloseImmediately)
        reminderText     = try c.decode(String.self,          forKey: .reminderText)
        themeId          = try c.decode(String.self,          forKey: .themeId)
        isEnabled        = try c.decode(Bool.self,            forKey: .isEnabled)
        shellCommand     = (try? c.decode(String.self,        forKey: .shellCommand)) ?? ""
        logDirectoryPath = (try? c.decode(String.self,        forKey: .logDirectoryPath)) ?? ""
    }

    init(
        id: UUID = UUID(),
        name: String = "提醒",
        actionKind: RuleActionKind = .desktop,
        triggerMode: TriggerMode = .interval,
        intervalMinutes: Int = 60,
        scheduledTimes: [ScheduledTime] = [],
        onceDate: Date = Date().addingTimeInterval(3600),
        followupMinutes: Int = 0,
        durationSeconds: Int = 10,
        canCloseImmediately: Bool = false,
        reminderText: String = "该休息了，离开屏幕活动一下。",
        themeId: String = "red-alarm",
        isEnabled: Bool = true,
        shellCommand: String = "",
        logDirectoryPath: String = ""
    ) {
        self.id = id
        self.name = name
        self.actionKind = actionKind
        self.triggerMode = triggerMode
        self.intervalMinutes = intervalMinutes
        self.scheduledTimes = scheduledTimes
        self.onceDate = onceDate
        self.followupMinutes = followupMinutes
        self.durationSeconds = durationSeconds
        self.canCloseImmediately = canCloseImmediately
        self.reminderText = reminderText
        self.themeId = themeId
        self.isEnabled = isEnabled
        self.shellCommand = shellCommand
        self.logDirectoryPath = logDirectoryPath
    }
}

// MARK: - Schedule conflict helpers (used by rule editor + status)

extension ReminderRule {
    /// Names of other enabled rules that may fire at the same wall-clock time (best-effort).
    func timeConflictNames(with allRules: [ReminderRule]) -> [String] {
        let others = allRules.filter { $0.id != id && $0.isEnabled }
        var names: [String] = []

        switch triggerMode {
        case .interval:
            break

        case .scheduled:
            guard !scheduledTimes.isEmpty else { break }
            for other in others {
                let otherTimes: [(Int, Int)]
                switch other.triggerMode {
                case .scheduled:
                    otherTimes = other.scheduledTimes.map { ($0.hour, $0.minute) }
                case .once:
                    let cal = Calendar.current
                    let h = cal.component(.hour, from: other.onceDate)
                    let m = cal.component(.minute, from: other.onceDate)
                    otherTimes = [(h, m)]
                case .interval:
                    otherTimes = []
                }
                let conflict = scheduledTimes.contains { t in
                    otherTimes.contains { $0.0 == t.hour && $0.1 == t.minute }
                }
                if conflict { names.append(other.name) }
            }

        case .once:
            for other in others {
                switch other.triggerMode {
                case .once:
                    if abs(other.onceDate.timeIntervalSince(onceDate)) < 60 {
                        names.append(other.name)
                    }
                case .scheduled:
                    let cal = Calendar.current
                    let rh = cal.component(.hour, from: onceDate)
                    let rm = cal.component(.minute, from: onceDate)
                    if other.scheduledTimes.contains(where: { $0.hour == rh && $0.minute == rm }) {
                        names.append(other.name)
                    }
                case .interval:
                    break
                }
            }
        }

        return Array(Set(names)).sorted()
    }
}
