import Foundation
import AppKit

/// Handles Skill export and install actions for AI-supported modules.
enum SkillInstaller {

    // MARK: - Module definitions

    struct Module {
        let id: String
        let name: String
        let description: String
        let skillFilename: String   // relative to Resources/Skills/
        let installAction: InstallAction
    }

    enum InstallAction {
        /// Copy skill to ~/.cursor/skills/{targetDir}/SKILL.md
        case copyToSkillsDir(targetDir: String)
        /// Write MCP entry to ~/.cursor/mcp.json AND copy skill
        case cursorGoodMCP(port: UInt16)
    }

    static var supportedModules: [Module] {
        let cgPort = UserDefaults.standard.integer(forKey: "cursorGoodPort")
        let resolvedPort: UInt16 = cgPort > 0 ? UInt16(cgPort) : 18880
        return [
            Module(
                id: "reminders",
                name: "定时提醒",
                description: "AI 可通过 HTTP API（18879 端口）创建和管理全屏蒙层提醒规则",
                skillFilename: "reminders/SKILL.md",
                installAction: .copyToSkillsDir(targetDir: "one-reminders")
            ),
            Module(
                id: "cursorgood",
                name: "CursorGood",
                description: "AI 通过 MCP 协议与用户实时对话，ONE 原生面板展示消息",
                skillFilename: "cursorgood/SKILL.md",
                installAction: .cursorGoodMCP(port: resolvedPort)
            )
        ]
    }

    // MARK: - Install status

    struct InstallStatus {
        var isInstalled: Bool
        var detail: String    // e.g. installed path or MCP status
    }

    static func installStatus(for module: Module) -> InstallStatus {
        switch module.installAction {
        case .copyToSkillsDir(let dir):
            let dest = skillsDir.appendingPathComponent("\(dir)/SKILL.md")
            if FileManager.default.fileExists(atPath: dest.path) {
                return InstallStatus(isInstalled: true, detail: dest.path)
            }
            return InstallStatus(isInstalled: false, detail: "未安装")

        case .cursorGoodMCP:
            let mcpPath = cursorConfigDir.appendingPathComponent("mcp.json")
            guard let data = try? Data(contentsOf: mcpPath),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let servers = json["mcpServers"] as? [String: Any],
                  let entry = servers[CGMcpRegister.mcpKey] as? [String: Any],
                  let url = entry["url"] as? String else {
                return InstallStatus(isInstalled: false, detail: "未注册 MCP")
            }
            return InstallStatus(isInstalled: true, detail: "MCP: \(url)")
        }
    }

    // MARK: - Install

    @discardableResult
    static func install(module: Module) -> Result<String, Error> {
        guard let content = skillContent(for: module) else {
            return .failure(NSError(domain: "SkillInstaller", code: 1,
                userInfo: [NSLocalizedDescriptionKey: "找不到 Skill 内容"]))
        }

        switch module.installAction {
        case .copyToSkillsDir(let dir):
            let destDir = skillsDir.appendingPathComponent(dir, isDirectory: true)
            let dest = destDir.appendingPathComponent("SKILL.md")
            do {
                try FileManager.default.createDirectory(at: destDir, withIntermediateDirectories: true)
                try content.write(to: dest, atomically: true, encoding: .utf8)
                return .success("已安装到\n\(dest.path)")
            } catch {
                return .failure(error)
            }

        case .cursorGoodMCP(let port):
            CGMcpRegister.register(port: port)
            let destDir = skillsDir.appendingPathComponent("cursorgood", isDirectory: true)
            let dest = destDir.appendingPathComponent("SKILL.md")
            do {
                try FileManager.default.createDirectory(at: destDir, withIntermediateDirectories: true)
                try content.write(to: dest, atomically: true, encoding: .utf8)
            } catch {
                NSLog("[SkillInstaller] Warning: skill write failed: \(error)")
            }
            return .success("MCP 已注册到\n~/.cursor/mcp.json\n端口 \(port)")
        }
    }

    // MARK: - Export

    static func export(module: Module) {
        guard let content = skillContent(for: module) else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = "SKILL.md"
        panel.message = "选择 \(module.name) Skill 文档的导出位置"
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            try? content.write(to: url, atomically: true, encoding: .utf8)
        }
    }

    // MARK: - Helpers

    private static var cursorConfigDir: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".cursor", isDirectory: true)
    }

    private static var skillsDir: URL {
        cursorConfigDir.appendingPathComponent("skills", isDirectory: true)
    }

    /// Returns the Skill markdown content for a module, embedded in code.
    static func skillContent(for module: Module) -> String? {
        switch module.id {
        case "reminders":  return SkillContent.reminders
        case "cursorgood": return SkillContent.cursorGood
        default: return nil
        }
    }
}
