# ONE

> AI 原生效率助理 — macOS App（原 Magicer）

[![Version](https://img.shields.io/badge/version-2.2.3-blue.svg)](https://github.com/whoishzp/one/releases)
[![Platform](https://img.shields.io/badge/platform-macOS%2013%2B-lightgrey.svg)](https://developer.apple.com/macos/)
[![Swift](https://img.shields.io/badge/swift-5.9%2B-orange.svg)](https://swift.org)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

ONE 是一个面向 AI 原生用户的个人效率助理，提供**定时提醒**、**AI 反馈（CursorGood）**和**前端开发工具**功能模块，应用在 Dock 和 Menu Bar 中均常驻。

## 截图

> 安装后效果：Dock + Menu Bar 常驻 → 弹出全屏蒙层（覆盖所有屏幕） → 倒计时后可关闭

## 功能特性

### 定时提醒

- **多规则并行**：创建多条提醒规则，各自独立计时，互不干扰
- **提醒时机双模式**：「桌面提醒」全屏蒙层；「定时脚本」按同一套时间策略执行 Shell（`/bin/sh -c`），可配置日志目录，每次执行追加写入 `one-<规则UUID>.log`（标准输出与标准错误、退出码）；支持一键复制命令
- **循环提醒**：每隔 N 分钟触发一次，重启后自动恢复剩余倒计时（本地缓存）
- **定点提醒**：每天指定时刻触发，可配置多个时刻
- **一次提醒**：选择指定时刻，触发一次后自动停用；关闭蒙层后还可配置「跟进提醒」在 N 分钟后再次弹出
- **跟进提醒**：任意触发模式均可配置关闭蒙层后 N 分钟自动补发一次（0 = 不跟进）
- **8 套蒙层主题**：黑白极简 / 深蓝平静 / 深红警告 / 深绿清新 / 粉嫩可爱 / 马卡龙 / 冰霜冷调 / 温柔晚霞
- **主题预览**：规则编辑时可实时预览各主题蒙层效果
- **全屏蒙层**：弹窗覆盖所有屏幕及扩展屏，切换桌面（Space）后自动抢回焦点，优先级高于所有窗口；可关闭时支持 ESC 键关闭
- **倒计时锁定**：可设置弹窗最短停留时长（0 = 随时可关）
- **可配置 Enter 后门次数**：每条规则可独立设置 3 秒内连按 Enter 的次数（1~100，默认 4）来强制显示关闭按钮
- **实时时钟**：弹窗全屏展示 `yyyy-MM-dd HH:mm:ss` 格式当前时间，每秒跳动，作为各主题主视觉元素
- **可配置关闭按钮文案**：每条规则可自定义关闭按钮文字（留空默认 OK）；按钮统一改为 ghost 风格小按钮，固定在屏幕右下角
- **实时状态面板**：查看每条规则距下次触发的倒计时与进度条

### 下班模式

- 点击右上角「下班」按钮，全屏黑幕遮屏，暂停所有提醒
- 防止系统休眠（`ProcessInfo.beginActivity`）
- 可选密码保护退出（系统设置中配置）
- 黑屏上有漂浮的动态眼睛动画，多个眼睛以物理碰撞方式自由移动
- 退出时自动恢复已暂停的提醒规则

### 系统设置

- **开机自启**：原生 `SMAppService` 实现
- **下班密码**：可设置/修改/清除密码，支持纯空格及任意字符
- **启动命令**：App 启动时自动执行配置的 Shell 命令（可配置多条，各自启用/禁用）；每条可一键复制完整 shell 到剪贴板（复制后柔和提示，成功约 3 秒 / 失败约 5 秒）、一键立即执行；手动执行结束后显示柔和提示条（约 6 秒后淡出，含退出码或错误摘要）
- **下班快捷键**：自定义全局键盘快捷键（需含修饰键），在任意应用中均可触发下班/取消下班

### Fe 助手（开发者工具）

| 工具 | 功能 |
| --- | --- |
| JSON 美化 | 树形展开/折叠视图、嵌套 JSON 字符串自动解析展开、悬停复制整个节点子树 JSON、叶子节点鼠标框选复制、复制全部 |
| JSON 比对 | 双面板可直接编辑、自动格式化、黄色高亮差异行 |
| 信息编码转换 | Unicode/URL/Base64/MD5/SHA1/HEX/HTML/JWT/Cookie 等 18 种操作 |
| 时间(戳)转换 | 智能解析多种格式、实时当前时间、快捷操作、双击复制 |

## 系统要求

| 项目 | 要求 |
| --- | --- |
| macOS | 13.0 (Ventura) 或更高 |
| 架构 | Apple Silicon / Intel |

## 安装

### 方式一：下载安装包（推荐）

1. 前往 [Releases](https://github.com/whoishzp/one/releases) 下载最新 `.dmg`
2. 打开 DMG，将 `ONE.app` 拖入 `Applications` 文件夹
3. 首次运行时在「系统设置 → 安全性 → 仍然打开」允许

### 方式二：从源码构建

```bash
git clone git@github.com:whoishzp/one.git
cd magicer
./build.sh
open ONE.app
```

## 使用

1. 启动后自动打开设置窗口（Dock + Menu Bar 均常驻图标）
2. **定时提醒**：新增规则，配置触发方式（循环/定点/一次）、蒙层主题和停留时长，可选跟进提醒
3. **当前状态**：实时查看各规则倒计时进度
4. **下班模式**：点击右上角「下班」按钮（或 Fe 助手工具栏快捷按钮）进入全屏黑幕模式；可在系统设置配置全局快捷键
5. **系统设置**：配置开机自启、下班密码、启动命令、下班全局快捷键
6. **Fe 助手**：4 个前端开发工具横向切换
7. 关闭设置窗口不退出应用，随时从 Menu Bar 或 Dock 重新打开

## 开发

### 环境依赖

- Xcode Command Line Tools（`xcode-select --install`）
- Swift 5.9+
- macOS 13+（编译目标）

### 构建

```bash
# Debug 编译
swift build

# Release 打包（更新 VERSION 后执行）
./release.sh
```

### 目录结构

```
magicer/
├── Sources/
│   ├── App/
│   │   ├── main.swift                   # App 入口（Dock + Menu Bar）
│   │   ├── AppDelegate.swift            # 窗口管理 + 生命周期
│   │   ├── MenuBarManager.swift         # 状态栏图标 + 菜单
│   │   ├── HideOnCloseWindow.swift      # 隐藏式关闭窗口
│   │   ├── HotkeyManager.swift          # 全局快捷键监听（下班模式）
│   │   ├── StartupCommandRunner.swift   # 启动命令执行器（含手动执行结果结构）
│   │   └── ScheduledScriptExecutor.swift # 定时脚本规则执行 + 文件日志
│   ├── Models/
│   │   ├── ReminderRule.swift           # 提醒规则数据模型
│   │   ├── RulesStore.swift             # 规则持久化 (UserDefaults)
│   │   ├── Theme.swift                  # 8 套蒙层主题 + 布局定义
│   │   ├── AppSettings.swift            # 全局设置模型
│   │   ├── OffWorkShortcut.swift        # 下班快捷键数据模型
│   │   └── StartupCommand.swift         # 启动命令数据模型
│   ├── Timer/
│   │   └── RuleTimerManager.swift       # 多规则并行计时引擎（含缓存恢复）
│   ├── Overlay/
│   │   ├── OverlayManager.swift         # 全屏蒙层管理 + 键盘监听
│   │   ├── OverlayLayouts.swift         # 8 种蒙层布局实现
│   │   └── CloseButtonView.swift        # 自定义关闭按钮
│   ├── OffWork/
│   │   ├── OffWorkManager.swift         # 下班模式逻辑 + 密码验证
│   │   ├── OffWorkState.swift           # 下班状态 ObservableObject
│   │   └── ScanningEyesView.swift       # 物理碰撞浮动眼睛动画
│   └── Settings/
│       ├── SettingsView.swift           # 主设置窗口（左侧导航栏）
│       ├── ReminderView.swift           # 定时提醒（状态+规则子 Tab）
│       ├── StatusView.swift             # 状态卡片 + 实时倒计时
│       ├── System/
│       │   ├── AppSettingsView.swift    # 系统设置页
│       │   ├── SkillManagerView.swift   # AI Skill 管理
│       │   ├── SkillInstaller.swift     # Skill 导出/安装
│       │   └── SkillContent.swift       # 嵌入式 Skill 内容
│       ├── Rules/
│       │   ├── RuleEditView.swift       # 规则编辑（桌面/脚本切换 + 内联面板）
│       │   ├── DesktopTimingPanel.swift # 桌面提醒：触发方式 + 跟进/时长
│       │   ├── ScheduledScriptTimingPanel.swift # 定时脚本：触发 + 命令 + 日志目录
│       │   └── ThemeCard.swift          # 主题选择卡片
│       ├── Preview/
│       │   └── ThemePreviewView.swift   # 蒙层主题预览
│       └── FeHelper/
│           ├── FeHelperView.swift       # Fe 助手主容器
│           ├── JsonBeautifyView.swift   # JSON 美化工具
│           ├── JsonDiffView.swift       # JSON 对比工具
│           ├── JsonEditorPanel.swift    # 可编辑语法高亮面板
│           ├── JsonSyntaxHighlighter.swift # JSON 语法着色
│           ├── EncodingView.swift       # 信息编码转换工具
│           └── TimestampView.swift      # 时间(戳)转换工具
├── Resources/
│   └── AppIcon.icns
├── Info.plist
├── Package.swift
├── VERSION
├── build.sh                             # 编译 + 打包 .app
└── release.sh                           # 升版 + 打包 DMG（仅保留最新）
```

### 版本管理

每次修改代码后：

```bash
# 1. 修改 VERSION 文件
echo "1.48.0" > VERSION

# 2. 打包发布（自动清理旧 DMG，生成新安装包）
./release.sh

# 3. 推送
git add -A && git commit -m "release: v1.48.0" && git push
git tag v1.48.0 && git push origin v1.48.0
```

## 最新版本

### v2.2.3（2026-06-12）

- **图片预览**：聊天中的图片支持点击放大查看
- **内部变量清理**：dingtalkBlue → accentBlue

完整变更历史请查看 [CHANGELOG.md](CHANGELOG.md)

## License

[MIT](LICENSE)

---

> 灵感来自 [cursor-stop](https://github.com/whoishzp/cursor-stop)
