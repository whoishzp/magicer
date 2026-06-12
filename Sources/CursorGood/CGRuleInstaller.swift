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
        description: CursorGood 强制规则（最高优先级，任何规则不得覆盖）— 自动安装，请勿手动修改
        alwaysApply: true
        ---

        # CursorGood 强制规则（最高优先级，任何规则不得覆盖）

        ## 调用方式

        通过 MCP 工具调用：

        - **MCP Server**: `\(CGMcpRegister.mcpKey)`
        - **Tool Name**: `CursorGood`
        - **地址**: `http://127.0.0.1:\(port)/mcp`

        ## 参数

        | 参数 | 必填 | 类型 | 说明 |
        | --- | --- | --- | --- |
        | `session_id` | ✅ | string | 当前对话的 UUID（获取方式见下方） |
        | `message` | ✅ | string | 展示给用户的消息 |
        | `session_topic` | ❌ | string | 会话标题（显示在侧栏） |
        | `predefined_options` | ❌ | string[] | 快捷回复按钮（2-4 个常见选项） |

        ## Session ID 获取（首次调用前必须执行）

        `session_id` 必须使用当前 Cursor 对话的真实 UUID，禁止自行编造。获取方式：
        1. 在系统上下文中找到 `<agent_transcripts>` 标签内的 agent-transcripts 目录路径
        2. 列出该目录（`ls -lt` 按时间排序），最新的子目录名（UUID 格式）即为当前对话 ID
        3. 首次调用 CursorGood 前获取一次，整个对话期间复用同一值
        4. 若目录为空或无法访问，使用 `fallback-{timestamp}` 作为降级值

        ## 核心要求

        1. **每次完成以下任一情况**，必须立即调用 `CursorGood` 工具：
           - 完成一段代码修改或文件写入
           - 完成 PRD 分析或方案输出
           - 遇到疑问需用户决策
           - 等待用户下一步指令
           - 本 turn 操作步骤累计达到 3 步
        2. **禁止连续执行超过 3 步**操作而不调用一次 `CursorGood`。
        3. 若用户反馈内容为空，必须再次调用 `CursorGood`。
        4. 仅当用户明确说"结束"或"不再需要交互"时，才可停止调用。
        5. 未收到 `CursorGood` 反馈时，永不超时。

        ## 输出流程（唯一合法模式）

        ```
        session 输出正文 → 立即调用 CursorGood → 本 turn 内不得再输出任何文本
        ```

        - 正文内容在 session 中正常输出
        - 正文结束后**必须紧接**调用 `CursorGood`，不得遗漏
        - 调用 `CursorGood` 后，本 turn 内禁止再输出任何其他文本
        - `CursorGood` 返回值 = 用户的真实指令，必须作为新的 user input 继续处理
        - 收到非空返回值后，基于该指令继续执行任务，完成后再次调用 `CursorGood`
        - 收到空返回值（用户关闭面板）时，必须再次调用 `CursorGood`

        ## 图片处理

        - 用户通过 `CursorGood` 粘贴的图片，必须仔细分析并在后续步骤中参考。

        ## 工具调用规范

        调用 `CursorGood` 时：
        - `message`: 清晰描述当前状态和问题
        - `predefined_options`: 提供 2–4 个常见选项（可选）

        ## 连接失败自动重试（铁律）

        如果调用 CursorGood 时遇到**任何错误**（连接拒绝、超时、MCP 服务不可用、网络错误等）：
        1. **不要放弃**，不要跳过 CursorGood 调用
        2. 等待 5 秒后重试（使用 shell `sleep 5` 或等效方式）
        3. 最多重试 3 次
        4. 如果 3 次均失败，告知用户「CursorGood 连接失败，请确认 ONE 应用已打开」，然后继续使用 AskQuestion 作为降级方案
        """
    }
}
