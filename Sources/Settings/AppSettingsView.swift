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
                        Text("WorkStop 应用配置").font(.caption).foregroundColor(.secondary)
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

    // MARK: - Actions

    private func savePassword() {
        showError = nil
        showSuccess = false

        guard !newPassword.isEmpty else {
            showError = "新密码不能为空"
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
