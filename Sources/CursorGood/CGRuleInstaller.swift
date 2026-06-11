import Foundation

/// Installs/updates the ONE CursorGood rule file into ~/.cursor/rules/ on launch.
enum CGRuleInstaller {

    private static let ruleFileName = "one-cursorgood.mdc"

    private static var ruleFileURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".cursor/rules/\(ruleFileName)")
    }

    static func installIfNeeded(port: UInt16) {
        let content = ruleContent(port: port)
        let dest = ruleFileURL

        let rulesDir = dest.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: rulesDir, withIntermediateDirectories: true)

        if let existing = try? String(contentsOf: dest, encoding: .utf8), existing == content {
            return
        }

        try? content.write(to: dest, atomically: true, encoding: .utf8)
        NSLog("[CGRuleInstaller] Installed/updated rule at \(dest.path)")
    }

    private static func ruleContent(port: UInt16) -> String {
        """
        ---
        description: ONE CursorGood — Agent 实时交互反馈面板（自动安装，请勿手动修改）
        alwaysApply: true
        ---

        # ONE CursorGood — Agent 调用规范

        当 Agent 需要与用户实时交互（汇报进度、等待指令、提问确认）时，**必须**调用 CursorGood 工具。

        ## 调用方式

        通过 MCP 工具调用：

        - **MCP Server**: `\(CGMcpRegister.mcpKey)`
        - **Tool Name**: `CursorGood`

        ## 参数

        | 参数 | 必填 | 类型 | 说明 |
        | --- | --- | --- | --- |
        | `session_id` | ✅ | string | 会话 ID（同一轮对话保持一致） |
        | `message` | ✅ | string | 展示给用户的消息 |
        | `session_topic` | ❌ | string | 会话标题（显示在侧栏） |
        | `predefined_options` | ❌ | string[] | 快捷回复按钮（2-4 个常见选项） |

        ## 调用时机

        - 完成一段代码修改或文件写入后
        - 完成分析或方案输出后
        - 遇到需要用户决策的疑问时
        - 等待用户下一步指令时
        - 本 turn 操作步骤累计达到 3 步时

        ## 返回值

        返回用户的回复文本。若用户粘贴了图片，图片以 base64 PNG 格式附在返回结果中。

        ## 注意事项

        - 调用 CursorGood 后，本 turn 内不得再输出任何文本
        - 收到空返回值时，必须再次调用 CursorGood
        - ONE 运行在本地 `http://127.0.0.1:\(port)/mcp`
        """
    }
}
