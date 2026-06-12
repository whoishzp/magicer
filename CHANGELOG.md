# Changelog

All notable changes to ONE are documented in this file.
Format follows [Keep a Changelog](https://keepachangelog.com/).

## [2.4.1] - 2026-06-12

### Fixed
- **MCP 断线恢复**：ONE 重启后自动从持久化会话重建待发送队列（`queuedInputs`），Cursor Agent 重试时可立即获取之前的回复
- **未送达消息提示**：会话中存在未送达消息时显示橙色提示条

### Changed
- **CursorGood 规则升级**：自动安装的 `one-cursorgood.mdc` 现包含完整的强制规则（核心要求、输出流程、连接失败自动重试等），不再依赖 `main.mdc`

## [2.4.0] - 2026-06-12

### Added
- **GitHub 同步**：系统设置新增 GitHub 同步模块，支持配置仓库地址、自动定时同步上传（默认 60 秒）、手动一键上传、从 GitHub 恢复（二次确认）、SSH Key 检测
- **统一数据存储**：所有配置数据迁移至 `~/.one/data/` 集中管理（`ONEDataStore`），新模块强制使用此目录，为 GitHub 同步提供基础
- **会话归档**：CursorGood 会话列表自动归档超过 24 小时未更新的会话，归档区默认折叠

### Changed
- **存储架构**：RulesStore、AppSettings、UIState、RuleTimerManager、StartupCommandRunner、CGSessionManager 全部从 UserDefaults 迁移到文件存储，首次启动自动迁移旧数据

## [2.3.0] - 2026-06-12

### Added
- **醒目元素配置**：每条规则可选择蒙层醒目元素 — 「时间」（大时钟居中，默认）或「提示文字」（大文字居中，时钟缩小至下方）
- **侧栏折叠**：主侧栏支持折叠/展开（图标+文字 ↔ 纯图标），状态持久化
- **图片预览**：聊天中的图片支持点击放大查看，全屏遮罩 + 右上角关闭按钮

### Fixed
- **屏幕拔除蒙层错位**：监听 `didChangeScreenParametersNotification`，扩展屏断开时自动重建蒙层窗口，保留倒计时状态

### Changed
- **Skill 文件同步**：新增 `prominentItem` 参数文档
- **内部变量清理**：dingtalkBlue → accentBlue

## [2.2.0] - 2026-06-12

### Changed
- **品牌统一**：代码/配置/日志中的 Magicer/WorkStop/ws_ 全部改为 ONE/one_
- **Package/Binary 名称**：WorkStop → ONE
- **Bundle ID 统一**：build.sh 与 Info.plist 均为 `com.mader.one`
- **聊天界面**：重新设计消息气泡配色（蓝色用户气泡 + 浅灰背景 + 白色 AI 气泡）
- **暗色模式适配**：聊天界面颜色使用 NSColor dynamic provider 自动适配
- **版本规则**：打包必升版本号，禁止两次发布使用同一版本号
- **设计规范**：新增架构师视角设计原则和 PRD 设计规范

### Fixed
- **自动滚动**：修复 LazyVStack 底部未渲染消息无法 scrollTo 的问题（加常驻锚点）
- **MCP 断连保护**：客户端断连时自动 resume continuation，防止内存泄漏
- **Force unwrap**：修复 5 处生产路径上的强制解包（ReminderHTTPServer/CGMcpServer/OverlayWindow/TimestampView）
- **下班退出"保持暂停"**：不再错误地禁用所有规则，保留原始快照状态
- **@StateObject 误用**：ReminderView 改为正确的 @ObservedObject
- **窗口可见性判断**：改用通知驱动替代硬编码 title 匹配

### Added
- **UserDefaults 数据迁移**：升级时自动迁移旧 key 数据，用户配置不丢失
- **优雅关闭**：退出时显式停止 HTTP/MCP server 和定时器
- **OverlayManager @MainActor**：显式标注线程安全
- **MCP 断连取消**：CGSessionManager 新增 cancelPendingCall 方法
- **CHANGELOG.md**：独立变更日志文件

### Removed
- **死代码清理**：移除未使用的 debounceTimers 字段

## [2.1.0] - 2026-06-11

### Added
- **MCP 改名**：key 从 `user-cursor-good` 改为 `one-cursor-good`
- **自动化安装**：启动自动注册 MCP + 安装 Cursor 规则
- **微信/钉钉风格**：消息气泡配色 + 输入框内置按钮
- **输入框草稿管理**：按会话保存/恢复
- **智能会话切换**：窗口已打开时新消息不强制切换
- **消息状态**：待发送消息显示等待状态
- **聊天导出**：单个会话导出为 Markdown
- **Cmd+V 粘贴图片修复**

## [2.0.1] - 2026-06-11

### Added
- **CursorGood 原生模块**：内置 MCP HTTP 服务（18880 端口）
- **Skill 管理**：系统设置中手动导出/安装 Skill 文档

## [1.85.0] - 2026-06-11

### Changed
- **品牌升级**：Magicer → ONE，图标更新
- **模块排序**：支持拖拽自由排序

## [1.84.0] - 2026-06-11

### Added
- **回车关闭次数可配置**：每条规则独立设置

## [1.83.0] - 2026-06-10

### Changed
- **关闭行为分级**：硬锁定选项

## [1.82.0] - 2026-06-10

### Changed
- **渐变 + 光晕球背景**：8 个主题重新设计
- **统一单一排版模板**

## [1.81.0] - 2026-06-10

### Changed
- **全面重设计 8 套蒙层主题**
- **关闭按钮迁移至右下角**
- **可配置关闭按钮文案**

## [1.75.0] - 2026-04-17

### Changed
- 侧边栏底部新增版本号显示
- Skill 主题 ID 列表修正

## [1.74.0] - 2026-04-17

### Fixed
- JSON 美化 5 级 fallback 解析策略

## [1.73.0] - 2026-04-17

### Fixed
- JSON 美化字符串外字面量转义处理

## [1.72.0] - 2026-04-17

### Fixed
- JSON 美化转义格式解析兼容

## [1.71.0] - 2026-04-17

### Added
- 全屏蒙层 ESC 键快速关闭

## [1.70.0] - 2026-04-17

### Changed
- JSON 美化解析失败时展示具体错误信息

## [1.69.0] - 2026-04-17

### Fixed
- JSON 美化兼容转义格式输入

## [1.68.0] - 2026-04-17

### Fixed
- 新建规则后不再立即弹出蒙层

## [1.67.0] - 2026-04-17

### Added
- JSON 美化嵌套 JSON 字符串自动解析

## [1.66.0] - 2026-04-17

### Changed
- 定时提醒改为桌面提醒/定时脚本双模式

## [1.65.0] - 2026-04-16

### Added
- 启动命令复制反馈提示条
- Cursor Good 强制规则

## [1.64.0] - 2026-04-16

### Added
- 启动命令一键复制

## [1.63.0] - 2026-04-16

### Removed
- 启动命令执行记录列表（仅保留提示条）

## [1.62.0] - 2026-04-16

### Added
- 启动命令执行记录 + 手动执行反馈

## [1.61.0] - 2026-04-16

### Added
- 启动命令一键执行按钮

## [1.60.0] - 2026-04-15

### Added
- Carbon 全局快捷键（无权限方案）

## [1.59.0] - 2026-04-15

### Changed
- 全局快捷键 global+local monitor
- 输入监控权限状态提示

## [1.58.0] - 2026-04-15

### Added
- 下班模式 + Fe 助手双快捷键

## [1.57.0] - 2026-04-15

### Added
- Fe 助手工具栏下班快捷按钮
- 下班快捷键系统设置

## [1.56.0] - 2026-04-14

### Added
- 嵌入式 HTTP Server（127.0.0.1:18879）
- Skill 一键安装（Cursor + Claude）

## [1.55.0] - 2026-04-14

### Removed
- 手动导出 Skill 按钮

## [1.54.0] - 2026-04-14

### Fixed
- 全屏覆盖根本修复（参考 cursor-stop）

## [1.53.0] - 2026-04-14

### Fixed
- 全屏蒙层白框
- MCP 服务 + 时间冲突检测

## [1.52.0] - 2026-04-14

### Fixed
- 历史规则升级兼容
- 扩展屏 full-screen Space 覆盖
- JSON 美化重写为树形视图

## [1.51.0] - 2026-04-14

### Added
- 一次提醒触发方式
- 跟进提醒
- Space 切换焦点恢复

## [1.47.0] - 2026-04-14

### Fixed
- 循环提醒本地缓存恢复
- 时间戳 Int 溢出崩溃

## [1.31.0] - 2026-04-13

### Changed
- 合并定时提醒子 Tab
- 新增信息编码转换工具

## [1.27.0] - 2026-04-12

### Added
- Fe 助手模块

## [1.22.0] - 2026-04-12

### Changed
- WorkStop → Magicer 更名

## [1.15.0] - 2026-04-11

### Added
- 8 套蒙层主题
- 下班模式动态眼睛

## [1.6.0] - 2026-04-11

### Added
- 下班模式

## [1.1.0] - 2026-04-10

### Added
- 初始发布
