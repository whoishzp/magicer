import Foundation
import Combine

/// Sync configuration persisted via ONEDataStore.
struct SyncConfig: Codable {
    var repoURL: String = ""
    var autoSyncEnabled: Bool = false
    var syncIntervalSeconds: Int = 60
    var lastSyncTime: Date?
    var lastSyncStatus: String = ""
}

/// Manages GitHub-based sync of all ONE data in `~/.one/data/`.
/// Flow:
///   Upload: export data → git add → commit → push
///   Download: git pull → reload all modules
class GitHubSyncManager: ObservableObject {
    static let shared = GitHubSyncManager()

    @Published var config: SyncConfig {
        didSet { ONEDataStore.shared.save(config, to: Self.configFile) }
    }
    @Published var isSyncing = false
    @Published var lastError: String?
    @Published var sshKeyAvailable: Bool = false

    private static let configFile = "sync-config.json"
    private var syncTimer: Timer?
    private let dataDir = ONEDataStore.shared.dataDir

    private init() {
        config = ONEDataStore.shared.load(SyncConfig.self, from: Self.configFile) ?? SyncConfig()
        checkSSHKey()
    }

    // MARK: - SSH Key check

    func checkSSHKey() {
        let sshDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".ssh")
        let keyFiles = ["id_rsa", "id_ed25519", "id_ecdsa"]
        sshKeyAvailable = keyFiles.contains { name in
            FileManager.default.fileExists(atPath: sshDir.appendingPathComponent(name).path)
        }
    }

    // MARK: - Git initialization

    private var isGitInitialized: Bool {
        FileManager.default.fileExists(
            atPath: dataDir.appendingPathComponent(".git").path
        )
    }

    func initializeRepo(completion: @escaping (Bool, String) -> Void) {
        guard !config.repoURL.isEmpty else {
            completion(false, "仓库地址为空")
            return
        }

        isSyncing = true
        lastError = nil

        DispatchQueue.global(qos: .utility).async { [self] in
            let result: (Bool, String)

            if isGitInitialized {
                result = runGit("remote", "set-url", "origin", config.repoURL)
            } else {
                writeGitIgnore()
                let initResult = runGit("init")
                guard initResult.0 else {
                    finish(ok: false, msg: initResult.1, completion: completion)
                    return
                }
                let addRemote = runGit("remote", "add", "origin", config.repoURL)
                guard addRemote.0 else {
                    finish(ok: false, msg: addRemote.1, completion: completion)
                    return
                }
                result = (true, "仓库初始化完成")
            }

            finish(ok: result.0, msg: result.1, completion: completion)
        }
    }

    // MARK: - Upload (push)

    func syncUpload(completion: @escaping (Bool, String) -> Void) {
        guard isGitInitialized else {
            completion(false, "请先配置仓库地址")
            return
        }
        isSyncing = true
        lastError = nil

        DispatchQueue.global(qos: .utility).async { [self] in
            let add = runGit("add", "-A")
            guard add.0 else { finish(ok: false, msg: add.1, completion: completion); return }

            let status = runGit("status", "--porcelain")
            if status.0 && status.1.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                finish(ok: true, msg: "无变化，跳过", completion: completion)
                return
            }

            let ts = ISO8601DateFormatter().string(from: Date())
            let hostname = ProcessInfo.processInfo.hostName
            let commit = runGit("commit", "-m", "sync: \(hostname) @ \(ts)")
            guard commit.0 else { finish(ok: false, msg: commit.1, completion: completion); return }

            let push = runGit("push", "-u", "origin", "HEAD")
            finish(ok: push.0, msg: push.0 ? "同步上传成功" : push.1, completion: completion)
        }
    }

    // MARK: - Download (pull)

    func syncDownload(completion: @escaping (Bool, String) -> Void) {
        guard !config.repoURL.isEmpty else {
            completion(false, "仓库地址为空")
            return
        }
        isSyncing = true
        lastError = nil

        DispatchQueue.global(qos: .utility).async { [self] in
            if isGitInitialized {
                let fetch = runGit("fetch", "origin")
                guard fetch.0 else { finish(ok: false, msg: fetch.1, completion: completion); return }

                let reset = runGit("reset", "--hard", "origin/HEAD")
                finish(ok: reset.0, msg: reset.0 ? "同步下载成功，请重启应用" : reset.1, completion: completion)
            } else {
                // Clone fresh
                let tmpDir = dataDir.deletingLastPathComponent()
                    .appendingPathComponent("data-clone-tmp", isDirectory: true)
                try? FileManager.default.removeItem(at: tmpDir)

                let clone = runShell("/usr/bin/git", "clone", config.repoURL, tmpDir.path)
                guard clone.0 else { finish(ok: false, msg: clone.1, completion: completion); return }

                // Move contents (except .git) to dataDir, then move .git
                let fm = FileManager.default
                if let items = try? fm.contentsOfDirectory(at: tmpDir, includingPropertiesForKeys: nil) {
                    for item in items {
                        let dest = dataDir.appendingPathComponent(item.lastPathComponent)
                        try? fm.removeItem(at: dest)
                        try? fm.moveItem(at: item, to: dest)
                    }
                }
                try? fm.removeItem(at: tmpDir)

                finish(ok: true, msg: "同步下载成功，请重启应用", completion: completion)
            }
        }
    }

    // MARK: - Auto sync timer

    func startAutoSync() {
        stopAutoSync()
        guard config.autoSyncEnabled, isGitInitialized else { return }
        let interval = TimeInterval(max(30, config.syncIntervalSeconds))
        syncTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.syncUpload { _, _ in }
        }
        if let t = syncTimer { RunLoop.main.add(t, forMode: .common) }
    }

    func stopAutoSync() {
        syncTimer?.invalidate()
        syncTimer = nil
    }

    // MARK: - Git helpers

    private func writeGitIgnore() {
        let content = "sync-config.json\n.DS_Store\n"
        let url = dataDir.appendingPathComponent(".gitignore")
        try? content.write(to: url, atomically: true, encoding: .utf8)
    }

    private func runGit(_ args: String...) -> (Bool, String) {
        runShell("/usr/bin/git", args, cwd: dataDir)
    }

    private func runShell(_ executable: String, _ args: String...) -> (Bool, String) {
        runShell(executable, args, cwd: nil)
    }

    private func runShell(_ executable: String, _ args: [String], cwd: URL? = nil) -> (Bool, String) {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: executable)
        task.arguments = args
        if let cwd = cwd { task.currentDirectoryURL = cwd }

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe

        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            return (task.terminationStatus == 0, output)
        } catch {
            return (false, error.localizedDescription)
        }
    }

    private func finish(ok: Bool, msg: String,
                        completion: @escaping (Bool, String) -> Void) {
        DispatchQueue.main.async { [self] in
            isSyncing = false
            if ok {
                config.lastSyncTime = Date()
                config.lastSyncStatus = msg
                lastError = nil
            } else {
                config.lastSyncStatus = "失败"
                lastError = msg
            }
            completion(ok, msg)
        }
    }
}
