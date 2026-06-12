import SwiftUI

struct GitHubSyncView: View {
    @ObservedObject private var sync = GitHubSyncManager.shared
    @State private var showDownloadConfirm = false
    @State private var statusMessage: String?

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 14) {
                Label("GitHub 同步", systemImage: "arrow.triangle.2.circlepath.circle")
                    .font(.headline)

                Text("所有配置数据存储在 ~/.one/data/，可同步到 GitHub 仓库实现多设备共享。")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)

                // SSH key status
                HStack(spacing: 6) {
                    Image(systemName: sync.sshKeyAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(sync.sshKeyAvailable ? .green : .red)
                        .font(.system(size: 12))
                    Text(sync.sshKeyAvailable ? "SSH Key 已检测到" : "未检测到 SSH Key，请先配置 ~/.ssh/")
                        .font(.system(size: 12))
                        .foregroundColor(sync.sshKeyAvailable ? .secondary : .red)
                    Spacer()
                    Button("重新检测") { sync.checkSSHKey() }
                        .controlSize(.small)
                        .buttonStyle(.bordered)
                }

                Divider()

                // Repo URL
                HStack {
                    Text("仓库地址")
                        .frame(width: 65, alignment: .leading)
                        .font(.system(size: 13))
                    TextField("git@github.com:user/one-data.git", text: $sync.config.repoURL)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12, design: .monospaced))
                    Button("初始化") {
                        sync.initializeRepo { ok, msg in statusMessage = msg }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(sync.config.repoURL.isEmpty || sync.isSyncing)
                }

                // Auto sync
                HStack(spacing: 12) {
                    Toggle("自动同步", isOn: $sync.config.autoSyncEnabled)
                        .toggleStyle(.switch)
                        .controlSize(.small)
                        .onChange(of: sync.config.autoSyncEnabled) { enabled in
                            if enabled { sync.startAutoSync() } else { sync.stopAutoSync() }
                        }

                    Text("间隔")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    TextField("", value: $sync.config.syncIntervalSeconds, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 50)
                        .font(.system(size: 12))
                    Text("秒")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Spacer()
                }

                Divider()

                // Action buttons
                HStack(spacing: 12) {
                    Button {
                        sync.syncUpload { _, msg in statusMessage = msg }
                    } label: {
                        Label("立即同步上传", systemImage: "arrow.up.circle")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .disabled(sync.isSyncing)

                    Button {
                        showDownloadConfirm = true
                    } label: {
                        Label("从 GitHub 恢复", systemImage: "arrow.down.circle")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(sync.isSyncing)

                    if sync.isSyncing {
                        ProgressView()
                            .controlSize(.small)
                    }

                    Spacer()
                }

                // Status
                if let lastSync = sync.config.lastSyncTime {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        Text("上次同步: \(lastSync, style: .relative)前")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Text("· \(sync.config.lastSyncStatus)")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }

                if let err = sync.lastError {
                    Label(err, systemImage: "exclamationmark.triangle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.red)
                        .lineLimit(3)
                }

                if let msg = statusMessage, sync.lastError == nil {
                    Text(msg)
                        .font(.system(size: 11))
                        .foregroundColor(.green)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { statusMessage = nil }
                        }
                }
            }
            .padding(4)
        }
        .alert("确认从 GitHub 恢复？", isPresented: $showDownloadConfirm) {
            Button("恢复", role: .destructive) {
                sync.syncDownload { _, msg in statusMessage = msg }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("此操作将用 GitHub 仓库中的数据覆盖本地所有配置，建议先备份。恢复后需重启应用。")
        }
    }
}
