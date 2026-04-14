import SwiftUI

struct TimestampView: View {
    @State private var timestampInput: String = ""
    @State private var dateOutput: String = ""
    @State private var dateInput: String = ""
    @State private var timestampOutput: String = ""
    @State private var currentTs: String = ""
    @State private var timer: Timer?
    @State private var selectedFormat: Int = 0

    private let formats = ["yyyy-MM-dd HH:mm:ss", "yyyy/MM/dd HH:mm:ss", "MM/dd/yyyy HH:mm:ss", "yyyy-MM-dd"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Current timestamp
                currentTimeSection

                Divider()

                // Timestamp → Date
                ts2DateSection

                Divider()

                // Date → Timestamp
                date2TsSection
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            updateCurrent()
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in updateCurrent() }
        }
        .onDisappear { timer?.invalidate() }
    }

    // MARK: - Sections

    private var currentTimeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("当前时间戳", systemImage: "clock.fill")
                .font(.system(size: 13, weight: .semibold))
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("秒级 (s)").font(.caption).foregroundColor(.secondary)
                    Text(currentTs).font(.system(size: 16, design: .monospaced)).fontWeight(.medium)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("毫秒级 (ms)").font(.caption).foregroundColor(.secondary)
                    Text("\(currentTs)000").font(.system(size: 16, design: .monospaced)).fontWeight(.medium)
                }
                Spacer()
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(currentTs, forType: .string)
                } label: {
                    Label("复制秒级", systemImage: "doc.on.clipboard")
                        .font(.system(size: 12))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(12)
            .background(Color.accentColor.opacity(0.06))
            .cornerRadius(8)
        }
    }

    private var ts2DateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("时间戳 → 格式化时间", systemImage: "arrow.right")
                .font(.system(size: 13, weight: .semibold))
            HStack(spacing: 10) {
                TextField("输入 Unix 时间戳（支持秒/毫秒）", text: $timestampInput)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 13, design: .monospaced))
                Button("转换") { convertTs2Date() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }
            if !dateOutput.isEmpty {
                Text(dateOutput)
                    .font(.system(size: 14, design: .monospaced))
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.green.opacity(0.07))
                    .cornerRadius(6)
            }
        }
    }

    private var date2TsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("格式化时间 → 时间戳", systemImage: "arrow.left")
                .font(.system(size: 13, weight: .semibold))
            Picker("格式", selection: $selectedFormat) {
                ForEach(0..<formats.count, id: \.self) { i in
                    Text(formats[i]).tag(i)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 220)
            HStack(spacing: 10) {
                TextField("例如：2024-01-15 10:30:00", text: $dateInput)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 13, design: .monospaced))
                Button("转换") { convertDate2Ts() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }
            if !timestampOutput.isEmpty {
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("秒级").font(.caption).foregroundColor(.secondary)
                        Text(timestampOutput).font(.system(size: 14, design: .monospaced))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("毫秒级").font(.caption).foregroundColor(.secondary)
                        Text("\(timestampOutput)000").font(.system(size: 14, design: .monospaced))
                    }
                    Spacer()
                    Button("复制秒级") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(timestampOutput, forType: .string)
                    }
                    .buttonStyle(.bordered).controlSize(.small)
                }
                .padding(10)
                .background(Color.blue.opacity(0.07))
                .cornerRadius(6)
            }
        }
    }

    // MARK: - Logic

    private func updateCurrent() {
        currentTs = "\(Int(Date().timeIntervalSince1970))"
    }

    private func convertTs2Date() {
        let raw = timestampInput.trimmingCharacters(in: .whitespaces)
        guard var ts = Double(raw) else { dateOutput = "无法解析时间戳"; return }
        if ts > 1e12 { ts /= 1000 }
        let date = Date(timeIntervalSince1970: ts)
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd HH:mm:ss"
        fmt.locale = Locale(identifier: "zh_CN")
        dateOutput = fmt.string(from: date) + "  (本地时区: \(TimeZone.current.identifier))"
    }

    private func convertDate2Ts() {
        let fmt = DateFormatter()
        fmt.dateFormat = formats[selectedFormat]
        fmt.locale = Locale(identifier: "zh_CN")
        let raw = dateInput.trimmingCharacters(in: .whitespaces)
        if let date = fmt.date(from: raw) {
            timestampOutput = "\(Int(date.timeIntervalSince1970))"
        } else {
            timestampOutput = "日期格式不匹配，期望: \(formats[selectedFormat])"
        }
    }
}
