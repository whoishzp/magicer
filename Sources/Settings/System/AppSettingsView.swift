import SwiftUI

struct AppSettingsView: View {
    var embedded: Bool = false

    @ObservedObject private var settings = AppSettings.shared
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var currentPassword: String = ""
    @State private var showError: String? = nil
    @State private var showSuccess = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !embedded {
                // Header (only shown when presented as sheet)
                HStack {
                    Image(systemName: "gearshape.2.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("系统设置").font(.headline)
                        Text("Magicer 应用配置").font(.caption).foregroundColor(.secondary)
                    }
                    Spacer()
                    Button("完成") { dismiss() }
                        .buttonStyle(.bordered).controlSize(.small)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                Divider()
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Startup commands section
                    startupCommandsSection

                    // Off-work password section
                    GroupBox {
                        VStack(alignment: .leading, spacing: 14) {
                            Label("下班模式密码", systemImage: "lock.fill")
                                .font(.subheadline.bold())
                                .foregroundColor(.primary)

                            Text("设置后，按 Esc 退出下班黑幕时需输入此密码。留空则无需密码。")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Divider()

                            if settings.hasPassword {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("当前密码状态：")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Label("已设置", systemImage: "lock.fill")
                                            .font(.caption.bold())
                                            .foregroundColor(.green)
                                    }

                                    HStack(spacing: 8) {
                                        SecureField("输入现有密码以修改或清除", text: $currentPassword)
                                            .textFieldStyle(.roundedBorder)
                                        Button("清除密码") { clearPassword() }
                                            .buttonStyle(.bordered)
                                            .controlSize(.small)
                                            .foregroundColor(.red)
                                    }
                                }
                            }

                            HStack(alignment: .top, spacing: 12) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(settings.hasPassword ? "新密码" : "设置密码")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    SecureField("输入新密码", text: $newPassword)
                                        .textFieldStyle(.roundedBorder)
                                }
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("确认密码")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    SecureField("再次输入", text: $confirmPassword)
                                        .textFieldStyle(.roundedBorder)
                                }
                                Button("保存") { savePassword() }
                                    .buttonStyle(.borderedProminent)
                                    .controlSize(.regular)
                                    .padding(.top, 16)
                            }

                            if let err = showError {
                                Label(err, systemImage: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                            if showSuccess {
                                Label("密码已保存", systemImage: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                        .padding(4)
                    }
                }
                .padding(20)
            }
        }
        .frame(minWidth: embedded ? 0 : 440, minHeight: embedded ? 0 : 360)
        .frame(maxWidth: embedded ? .infinity : 440, maxHeight: embedded ? .infinity : 360)
    }

    // MARK: - Startup Commands Section

    @State private var newCmdLabel: String = ""
    @State private var newCmdText: String = ""

    private var startupCommandsSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 14) {
                Label("启动执行命令", systemImage: "terminal.fill")
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)

                Text("软件启动时自动执行以下 shell 命令。按顺序执行，后台运行不阻塞启动。")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Divider()

                // Command list
                if settings.startupCommands.isEmpty {
                    Text("暂无命令")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                } else {
                    VStack(spacing: 6) {
                        ForEach($settings.startupCommands) { $cmd in
                            HStack(spacing: 8) {
                                Toggle("", isOn: $cmd.isEnabled)
                                    .labelsHidden()
                                    .controlSize(.small)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(cmd.label.isEmpty ? "(无标签)" : cmd.label)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(cmd.isEnabled ? .primary : .secondary)
                                    Text(cmd.command)
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                                Button {
                                    settings.startupCommands.removeAll { $0.id == cmd.id }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(Color(NSColor.controlBackgroundColor).opacity(0.6))
                            .cornerRadius(6)
                        }
                    }
                }

                Divider()

                // Add command row
                VStack(alignment: .leading, spacing: 8) {
                    Text("添加命令").font(.caption).foregroundColor(.secondary)
                    HStack(spacing: 8) {
                        TextField("标签（如：打开代理）", text: $newCmdLabel)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 150)
                        TextField("shell 命令（如：open -a Proxyman）", text: $newCmdText)
                            .textFieldStyle(.roundedBorder)
                        Button {
                            guard !newCmdText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                            settings.startupCommands.append(StartupCommand(
                                label: newCmdLabel.isEmpty ? newCmdText : newCmdLabel,
                                command: newCmdText
                            ))
                            newCmdLabel = ""; newCmdText = ""
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.accentColor)
                        }
                        .buttonStyle(.plain)
                        .disabled(newCmdText.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
            .padding(4)
        }
    }

    // MARK: - Actions

    private func savePassword() {
        showError = nil
        showSuccess = false

        guard !newPassword.isEmpty else {
            showError = "密码不能为空字符串（支持空格、任意字符）"
            return
        }
        guard newPassword == confirmPassword else {
            showError = "两次输入的密码不一致"
            return
        }
        if settings.hasPassword {
            guard currentPassword == settings.offWorkPassword else {
                showError = "现有密码不正确"
                return
            }
        }

        settings.offWorkPassword = newPassword
        newPassword = ""
        confirmPassword = ""
        currentPassword = ""
        showSuccess = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { showSuccess = false }
    }

    private func clearPassword() {
        showError = nil
        guard settings.hasPassword else { return }
        guard currentPassword == settings.offWorkPassword else {
            showError = "现有密码不正确，无法清除"
            return
        }
        settings.offWorkPassword = ""
        currentPassword = ""
        showSuccess = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { showSuccess = false }
    }
}
