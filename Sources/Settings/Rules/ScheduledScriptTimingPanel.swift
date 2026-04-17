import AppKit
import SwiftUI

/// Inline editor for scheduled shell commands: same three trigger modes + command + log directory.
struct ScheduledScriptTimingPanel: View {
    @Binding var rule: ReminderRule
    @State private var newHour = 9
    @State private var newMinute = 0
    @State private var copyFeedback = false

    private var timeConflicts: [String] {
        rule.timeConflictNames(with: RulesStore.shared.rules)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("按下方触发方式执行 Shell 命令（`/bin/sh -c`）。日志按规则写入目录中的 `magicer-{规则ID}.log`。")
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Text("触发方式")
                    .frame(width: 80, alignment: .leading)
                Picker("", selection: $rule.triggerMode) {
                    Text("循环执行").tag(TriggerMode.interval)
                    Text("定点执行").tag(TriggerMode.scheduled)
                    Text("一次执行").tag(TriggerMode.once)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 340)
                Spacer()
            }

            if rule.triggerMode == .interval {
                intervalConfig
            } else if rule.triggerMode == .scheduled {
                scheduledConfig
            } else {
                onceConfig
            }

            let conflicts = timeConflicts
            if !conflicts.isEmpty {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                        .padding(.top, 1)
                    Text("触发时刻与以下规则冲突：\(conflicts.joined(separator: "、"))。")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .padding(.vertical, 4)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Shell 命令")
                        .frame(width: 80, alignment: .leading)
                    Spacer()
                    Button {
                        copyCommand()
                    } label: {
                        Label(copyFeedback ? "已复制" : "复制命令", systemImage: copyFeedback ? "checkmark.circle.fill" : "doc.on.doc")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(rule.shellCommand.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                TextEditor(text: $rule.shellCommand)
                    .font(.system(size: 13, design: .monospaced))
                    .frame(minHeight: 88, maxHeight: 140)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("日志目录")
                        .frame(width: 80, alignment: .leading)
                    TextField("例如 ~/Library/Logs/MagicerScripts", text: $rule.logDirectoryPath)
                        .textFieldStyle(.roundedBorder)
                    Button("选择…") { pickLogDirectory() }
                        .buttonStyle(.bordered)
                }
                Text("每次执行会在该目录追加写入 `magicer-<规则UUID>.log`。留空则不写文件日志。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func copyCommand() {
        let s = rule.shellCommand.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(s, forType: .string)
        copyFeedback = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            copyFeedback = false
        }
    }

    private func pickLogDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.prompt = "选择"
        if panel.runModal() == .OK, let url = panel.url {
            rule.logDirectoryPath = url.path
        }
    }

    private var intervalConfig: some View {
        HStack(alignment: .center) {
            Text("执行间隔")
                .frame(width: 80, alignment: .leading)
            TextField("", value: $rule.intervalMinutes, format: .number)
                .frame(width: 64)
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.trailing)
                .onChange(of: rule.intervalMinutes) { v in
                    rule.intervalMinutes = max(1, min(480, v))
                }
            Stepper("", value: $rule.intervalMinutes, in: 1...480)
                .labelsHidden()
            Text("分钟")
                .foregroundColor(.secondary)
            Spacer()
            Text("每隔此时间执行一次命令")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var scheduledConfig: some View {
        VStack(alignment: .leading, spacing: 10) {
            if rule.scheduledTimes.isEmpty {
                Text("还没有添加定点时刻")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 6) {
                    ForEach(rule.scheduledTimes) { t in
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.accentColor)
                                .font(.subheadline)
                            Text(t.displayText)
                                .font(.system(size: 15, weight: .medium, design: .monospaced))
                            Spacer()
                            Button {
                                rule.scheduledTimes.removeAll { $0.id == t.id }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.accentColor.opacity(0.06))
                        .cornerRadius(8)
                    }
                }
            }

            HStack(spacing: 10) {
                Text("添加时刻")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(width: 60)

                Picker("时", selection: $newHour) {
                    ForEach(0..<24, id: \.self) { h in
                        Text(String(format: "%02d 时", h)).tag(h)
                    }
                }
                .frame(width: 80)

                Picker("分", selection: $newMinute) {
                    ForEach([0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55], id: \.self) { m in
                        Text(String(format: "%02d 分", m)).tag(m)
                    }
                }
                .frame(width: 80)

                Button {
                    let newTime = ScheduledTime(hour: newHour, minute: newMinute)
                    if !rule.scheduledTimes.contains(where: { $0.hour == newHour && $0.minute == newMinute }) {
                        rule.scheduledTimes.append(newTime)
                        rule.scheduledTimes.sort { $0.hour * 60 + $0.minute < $1.hour * 60 + $1.minute }
                    }
                } label: {
                    Label("添加", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.bordered)

                Spacer()
            }

            Text("每天到点执行一次命令，可添加多个时刻")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var onceConfig: some View {
        HStack(alignment: .center) {
            Text("执行时刻")
                .frame(width: 80, alignment: .leading)
            DatePicker("", selection: $rule.onceDate)
                .datePickerStyle(.compact)
                .labelsHidden()
            Spacer()
            Text("到点执行一次后自动停用规则")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
