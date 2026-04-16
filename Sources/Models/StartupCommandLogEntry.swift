import Foundation

/// 启动命令执行来源
enum StartupCommandRunSource: String, Codable {
    case startup
    case manual
}

/// 单条执行记录（启动时或设置里手动运行）
struct StartupCommandLogEntry: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var date: Date
    var label: String
    /// 命令前若干字符，便于辨认
    var commandPreview: String
    var source: StartupCommandRunSource
    var success: Bool
    /// 未能启动进程时为 nil
    var exitCode: Int?
    var errorDetail: String?
}
