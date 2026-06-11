import Foundation

/// Embedded Skill markdown content for export/install.
/// Updated whenever Skill features change.
enum SkillContent {

    static let reminders = """
    # ONE — 定时提醒 Skill

    > **AI 支持**: ✅
    > **适用 AI**: 任意支持 HTTP API 的 AI Agent（不限 Cursor）

    ---

    ## 模块简介

    ONE 的「定时提醒」模块提供全屏蒙层提醒能力。当提醒触发时，ONE 覆盖所有屏幕显示提醒内容，用户需主动关闭。

    AI 可通过 ONE 内嵌的 HTTP API（`http://127.0.0.1:18879`）创建、查询、修改、删除提醒规则。

    ---

    ## API 速查

    ### 查询所有规则
    ```bash
    curl http://127.0.0.1:18879/reminders
    ```

    ### 创建规则
    ```bash
    curl -X POST http://127.0.0.1:18879/reminders \\
      -H 'Content-Type: application/json' \\
      -d '{
        "id": "<UUID>",
        "name": "喝水提醒",
        "actionKind": "desktop",
        "triggerMode": "interval",
        "intervalMinutes": 60,
        "scheduledTimes": [],
        "onceDate": "2026-06-11T09:00:00Z",
        "followupMinutes": 0,
        "durationSeconds": 10,
        "canCloseImmediately": false,
        "enterPressThreshold": 4,
        "reminderText": "该喝水了！",
        "themeId": "blue-calm",
        "isEnabled": true,
        "shellCommand": "",
        "logDirectoryPath": "",
        "closeButtonText": ""
      }'
    ```

    ### 启用/禁用规则
    ```bash
    curl -X PUT http://127.0.0.1:18879/reminders/{id}/toggle
    ```

    ### 删除规则
    ```bash
    curl -X DELETE http://127.0.0.1:18879/reminders/{id}
    ```

    ---

    ## 字段说明

    | 字段 | 类型 | 默认值 | 说明 |
    | --- | --- | --- | --- |
    | `id` | `string` | 必填 | UUID |
    | `name` | `string` | 必填 | 规则名称 |
    | `actionKind` | `string` | `"desktop"` | `desktop`（全屏蒙层）/ `script`（执行 shell） |
    | `triggerMode` | `string` | 必填 | `interval` / `scheduled` / `once` |
    | `intervalMinutes` | `int` | `60` | 循环间隔（`triggerMode=interval` 时有效） |
    | `scheduledTimes` | `array` | `[]` | 定点时刻列表（`triggerMode=scheduled` 时有效） |
    | `onceDate` | `string` | — | ISO 8601 UTC 时间（`triggerMode=once` 时有效） |
    | `followupMinutes` | `int` | `0` | 关闭蒙层后 N 分钟再触发一次（0=不跟进） |
    | `durationSeconds` | `int` | `10` | 蒙层最短停留秒数（0=随时可关） |
    | `canCloseImmediately` | `bool` | `false` | `true` = 忽略 durationSeconds，立即可关 |
    | `enterPressThreshold` | `int` | `4` | 3秒内连按 Enter N 次强制显示关闭按钮（1~100） |
    | `reminderText` | `string` | 必填 | 蒙层展示的提醒文字 |
    | `themeId` | `string` | `"red-alarm"` | 见下方主题列表 |
    | `isEnabled` | `bool` | `true` | 是否启用 |
    | `shellCommand` | `string` | `""` | `actionKind=script` 时执行的命令 |
    | `logDirectoryPath` | `string` | `""` | 脚本日志目录（空=不记录文件日志） |
    | `closeButtonText` | `string` | `""` | 关闭按钮文案（空=显示 OK） |

    ## 主题 ID

    | themeId | 风格 |
    | --- | --- |
    | `red-alarm` | 深红警告 |
    | `blue-calm` | 深蓝平静 |
    | `green-fresh` | 深绿清新 |
    | `mono-minimal` | 黑白极简 |
    | `gentle` | 温柔晚霞 |
    | `pink` | 粉嫩可爱 |
    | `macaron` | 马卡龙 |
    | `frosted` | 冰霜冷调 |

    ## triggerMode 说明

    | 值 | 含义 |
    | --- | --- |
    | `interval` | 每隔 `intervalMinutes` 分钟循环触发 |
    | `scheduled` | 每天在 `scheduledTimes` 指定时刻触发 |
    | `once` | 在 `onceDate`（UTC）触发一次后自动禁用 |

    ---

    > 随 ONE App 发布同步更新
    """

    static let cursorGood = """
    # ONE — CursorGood Skill

    > **AI 支持**: ✅
    > **适用 AI**: 任意支持 MCP Streamable HTTP 的 AI Agent（不限 Cursor）

    ---

    ## 模块简介

    ONE 的「CursorGood」模块是一个原生 macOS AI 反馈面板。

    AI Agent 通过 MCP 协议调用 `CursorGood` 工具，向用户发送消息（含可选快捷回复按钮）；用户在 ONE 的对话框中回复后，回复内容作为工具返回值传回给 AI，驱动下一轮 Agent 行为。

    ---

    ## 如何注册（MCP 配置）

    ### Cursor 用户

    ONE 启动时会自动写入 `~/.cursor/mcp.json`。若需手动配置，将以下内容合并到该文件：

    ```json
    {
      "mcpServers": {
        "\(CGMcpRegister.mcpKey)": {
          "url": "http://127.0.0.1:18880/mcp"
        }
      }
    }
    ```

    写入后重启 Cursor，MCP 工具即可生效。

    ### 其他 AI 工具

    任何支持 MCP Streamable HTTP（2025-03-26）或 Legacy SSE（2024-11-05）的 AI Agent 均可连接：
    - Streamable HTTP：`http://127.0.0.1:18880/mcp`
    - Legacy SSE：`http://127.0.0.1:18880/sse`

    ---

    ## 工具：CursorGood

    ### 参数

    | 参数 | 类型 | 必填 | 说明 |
    | --- | --- | --- | --- |
    | `message` | `string` | ✅ | 展示给用户的消息内容 |
    | `session_id` | `string` | ✅ | Session ID，用于路由到对应对话框 |
    | `predefined_options` | `string[]` | ❌ | 快捷回复选项按钮 |
    | `session_topic` | `string` | ❌ | 会话主题描述 |

    ### 调用示例

    ```json
    {
      "name": "CursorGood",
      "arguments": {
        "message": "你好！请确认是否继续执行？",
        "session_id": "cursor-session-abc123",
        "session_topic": "Feature: 用户登录模块",
        "predefined_options": ["继续执行", "暂停", "调整方案"]
      }
    }
    ```

    ### 返回值格式

    **用户已回复：**
    ```
    ╔══════════════════════════════════════╗
    ║  ⚡ USER_INSTRUCTION_RECEIVED         ║
    ╚══════════════════════════════════════╝

    用户输入: 继续执行
    ```

    图片附件以 MCP `content` 项格式返回：`{ "type": "image", "data": "<base64>", "mimeType": "image/png" }`

    ---

    ## session_id 使用规范

    - 同一个 AI 对话的所有 `CursorGood` 调用应使用**相同的 session_id**
    - ONE 会按 session_id 路由到对应对话框，新 session_id 自动创建新会话

    ---

    ## 端口配置

    默认端口：**18880**
    可在 ONE「系统设置」中修改，修改后需重启 ONE 并更新 MCP 注册配置。

    ---

    > 随 ONE App 发布同步更新
    """
}
