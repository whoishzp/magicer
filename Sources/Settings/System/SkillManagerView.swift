import SwiftUI

struct SkillManagerView: View {
    @State private var statusMap: [String: SkillInstaller.InstallStatus] = [:]
    @State private var feedbackMap: [String: FeedbackItem] = [:]

    private struct FeedbackItem: Equatable {
        var success: Bool
        var message: String
    }

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 14) {
                Label("AI Skill 管理", systemImage: "brain.head.profile")
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)

                Text("为 AI 工具手动安装对应模块的 Skill 文档。安装后 AI 可感知 ONE 的能力并调用。")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Divider()

                VStack(spacing: 10) {
                    ForEach(SkillInstaller.supportedModules, id: \.id) { module in
                        moduleRow(module)
                    }
                }
            }
            .padding(4)
        }
        .onAppear { refreshStatus() }
    }

    // MARK: - Module row

    private func moduleRow(_ module: SkillInstaller.Module) -> some View {
        let status = statusMap[module.id]
        let feedback = feedbackMap[module.id]

        return VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 10) {
                // Module info
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(module.name)
                            .font(.system(size: 13, weight: .medium))
                        if status?.isInstalled == true {
                            Label("已安装", systemImage: "checkmark.circle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.green)
                        }
                    }
                    Text(module.description)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    if let detail = status?.detail, status?.isInstalled == true {
                        Text(detail)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.secondary.opacity(0.7))
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Buttons
                HStack(spacing: 6) {
                    Button("导出 Skill") {
                        SkillInstaller.export(module: module)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Button(status?.isInstalled == true ? "重新安装" : "安装 Skill") {
                        installModule(module)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }

            // Feedback toast
            if let fb = feedback {
                HStack(spacing: 6) {
                    Image(systemName: fb.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(fb.success ? .green : .red)
                    Text(fb.message)
                        .font(.caption)
                        .foregroundColor(fb.success ? .green : .red)
                }
            }

            Divider().opacity(0.5)
        }
    }

    // MARK: - Actions

    private func installModule(_ module: SkillInstaller.Module) {
        let result = SkillInstaller.install(module: module)
        switch result {
        case .success(let msg):
            feedbackMap[module.id] = FeedbackItem(success: true, message: msg)
        case .failure(let err):
            feedbackMap[module.id] = FeedbackItem(success: false, message: err.localizedDescription)
        }
        refreshStatus()
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            feedbackMap[module.id] = nil
        }
    }

    private func refreshStatus() {
        for m in SkillInstaller.supportedModules {
            statusMap[m.id] = SkillInstaller.installStatus(for: m)
        }
    }
}
