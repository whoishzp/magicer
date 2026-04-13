# WorkStop

> 工作中断提醒 — macOS Menu Bar App

[![Version](https://img.shields.io/badge/version-1.1.0-blue.svg)](https://github.com/whoishzp/work-stop/releases)
[![Platform](https://img.shields.io/badge/platform-macOS%2013%2B-lightgrey.svg)](https://developer.apple.com/macos/)
[![Swift](https://img.shields.io/badge/swift-5.9%2B-orange.svg)](https://swift.org)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

WorkStop 是一个轻量的 macOS Menu Bar 应用，定时弹出全屏提醒蒙层，帮助你在长时间工作中养成规律休息的习惯。

## 截图

> 安装后效果：Menu Bar 常驻 → 弹出全屏蒙层（覆盖所有屏幕） → 倒计时后可关闭

## 功能特性

- **多规则并行**：创建多条提醒规则，各自独立计时，互不干扰
- **循环提醒**：每隔 N 分钟触发一次
- **定点提醒**：每天指定时刻触发，可配置多个时刻
- **4 套蒙层主题**：深红警告 / 深蓝平静 / 深绿清新 / 黑白极简
- **全屏蒙层**：弹窗覆盖所有屏幕及全屏 Space，优先级高于所有窗口
- **倒计时锁定**：可设置弹窗最短停留时长（0 = 随时可关）
- **Enter 后门**：弹窗期间 3 秒内连按 Enter 4 次，强制显示关闭按钮
- **实时状态面板**：查看每条规则距下次触发的倒计时与进度条
- **开机自启**：系统原生 `SMAppService` 实现，无残留

## 系统要求

| 项目 | 要求 |
| --- | --- |
| macOS | 13.0 (Ventura) 或更高 |
| 架构 | Apple Silicon / Intel (Universal) |

## 安装

### 方式一：下载安装包（推荐）

1. 前往 [Releases](https://github.com/whoishzp/work-stop/releases) 下载最新 `.dmg`
2. 打开 DMG，将 `WorkStop.app` 拖入 `Applications` 文件夹
3. 首次运行时在「系统设置 → 安全性 → 仍然打开」允许

### 方式二：从源码构建

```bash
git clone git@github.com:whoishzp/work-stop.git
cd work-stop
./build.sh
open WorkStop.app
```

## 使用

1. 启动后自动打开设置窗口（Menu Bar 也会出现图标）
2. 「规则配置」页面新增规则，设置触发方式和蒙层参数
3. 「当前状态」页面实时查看各规则倒计时
4. 在「开机自启」菜单项启用后随系统自动运行
5. 关闭设置窗口不退出应用，随时从 Menu Bar 图标重新打开

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
work-stop/
├── Sources/
│   ├── main.swift                   # App 入口
│   ├── AppDelegate.swift            # Menu Bar 图标 + 开机自启
│   ├── HideOnCloseWindow.swift      # 隐藏式关闭窗口
│   ├── Models/
│   │   ├── ReminderRule.swift       # 提醒规则数据模型
│   │   ├── RulesStore.swift         # 持久化 (UserDefaults)
│   │   └── Theme.swift              # 蒙层主题颜色定义
│   ├── Timer/
│   │   └── RuleTimerManager.swift   # 多规则并行计时引擎
│   ├── Overlay/
│   │   └── OverlayWindow.swift      # 全屏蒙层 + Enter 后门
│   └── Settings/
│       ├── SettingsView.swift       # 设置主窗口（Tab 切换）
│       ├── StatusView.swift         # 状态卡片 + 实时倒计时
│       └── RuleEditView.swift       # 规则编辑表单
├── Resources/
│   └── AppIcon.icns
├── Info.plist
├── Package.swift
├── VERSION
├── build.sh                         # 编译 + 打包 .app
└── release.sh                       # 升版 + 打包 DMG + 存档
```

### 版本管理

每次修改代码后：

```bash
# 1. 修改 VERSION 文件
echo "1.2.0" > VERSION

# 2. 打包发布
./release.sh

# 3. 推送
git add -A && git commit -m "release: v1.2.0" && git push
```

## 变更日志

### v1.1.0（2026-04-13）

- 初始发布
- 多规则并行计时
- 循环 + 定点两种触发模式
- 4 套蒙层主题
- 实时状态面板
- Enter 键后门
- 开机自启支持

## 贡献

欢迎提交 Issue 和 Pull Request。

1. Fork 本仓库
2. 创建功能分支 `git checkout -b feat/my-feature`
3. 提交改动 `git commit -m "feat: add my feature"`
4. 推送并提 PR

## License

[MIT](LICENSE)

---

> 灵感来自 [cursor-stop](https://github.com/whoishzp/cursor-stop)
