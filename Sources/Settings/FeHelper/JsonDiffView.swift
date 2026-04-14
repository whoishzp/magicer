import SwiftUI

struct JsonDiffView: View {
    @State private var left: String = ""
    @State private var right: String = ""
    @State private var leftLines: [DiffLine] = []
    @State private var rightLines: [DiffLine] = []
    @State private var diffCount = 0
    @State private var leftError: String = ""
    @State private var rightError: String = ""

    struct DiffLine: Identifiable {
        let id = UUID()
        let lineNumber: Int
        let text: String
        let isDiff: Bool
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top: two raw input areas
            HStack(alignment: .top, spacing: 8) {
                inputPanel(title: "JSON A", text: $left, error: leftError)
                inputPanel(title: "JSON B", text: $right, error: rightError)
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 6)

            // Status bar
            HStack(spacing: 8) {
                if leftError.isEmpty && rightError.isEmpty {
                    if left.isEmpty || right.isEmpty {
                        Text("在上方粘贴 JSON，自动对比")
                            .font(.caption).foregroundColor(.secondary)
                    } else if leftLines.isEmpty {
                        Text("等待输入...")
                            .font(.caption).foregroundColor(.secondary)
                    } else if diffCount == 0 {
                        Label("完全相同", systemImage: "checkmark.circle.fill")
                            .font(.caption).foregroundColor(.green)
                    } else {
                        Label("\(diffCount) 处差异", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption).foregroundColor(.orange)
                    }
                } else {
                    if !leftError.isEmpty {
                        Label("A: \(leftError)", systemImage: "xmark.circle.fill")
                            .font(.caption).foregroundColor(.red)
                    }
                    if !rightError.isEmpty {
                        Label("B: \(rightError)", systemImage: "xmark.circle.fill")
                            .font(.caption).foregroundColor(.red)
                    }
                }
                Spacer()
                if !left.isEmpty || !right.isEmpty {
                    Button("清空全部") {
                        left = ""; right = ""
                        leftLines = []; rightLines = []
                        leftError = ""; rightError = ""
                        diffCount = 0
                    }
                    .font(.caption).buttonStyle(.plain).foregroundColor(.secondary)
                }
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 2).fill(Color.yellow.opacity(0.5)).frame(width: 14, height: 10)
                        Text("差异行").font(.caption2).foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // Bottom: syntax highlighted diff panels
            if !leftLines.isEmpty || !rightLines.isEmpty {
                HStack(spacing: 0) {
                    diffPanel(lines: leftLines, title: "JSON A")
                    Divider().background(Color.gray.opacity(0.3))
                    diffPanel(lines: rightLines, title: "JSON B")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(JsonSyntaxHighlighter.bgColor)
            } else {
                ZStack {
                    JsonSyntaxHighlighter.bgColor
                    if !left.isEmpty || !right.isEmpty {
                        ProgressView().scaleEffect(0.7)
                    } else {
                        Text("粘贴 JSON 到上方输入框，将在此处自动显示格式化对比结果")
                            .font(.system(size: 12))
                            .foregroundColor(JsonSyntaxHighlighter.lineNumColor)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: left) { _ in autoCompare() }
        .onChange(of: right) { _ in autoCompare() }
    }

    // MARK: - Input Panel

    private func inputPanel(title: String, text: Binding<String>, error: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title).font(.caption).foregroundColor(.secondary)
                Spacer()
                if !error.isEmpty {
                    Text(error).font(.caption).foregroundColor(.red).lineLimit(1)
                }
                Button("粘贴") {
                    text.wrappedValue = NSPasteboard.general.string(forType: .string) ?? ""
                }
                .font(.caption).buttonStyle(.plain).foregroundColor(.accentColor)
                Button("清空") { text.wrappedValue = "" }
                    .font(.caption).buttonStyle(.plain).foregroundColor(.secondary)
            }
            TextEditor(text: text)
                .font(.system(size: 11, design: .monospaced))
                .frame(maxWidth: .infinity)
                .frame(height: 90)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(error.isEmpty ? Color.secondary.opacity(0.25) : Color.red.opacity(0.4), lineWidth: 1)
                )
        }
    }

    // MARK: - Diff Panel

    private func diffPanel(lines: [DiffLine], title: String) -> some View {
        VStack(spacing: 0) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(JsonSyntaxHighlighter.lineNumColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(JsonSyntaxHighlighter.bgColor.opacity(0.95))
            Divider().background(Color.gray.opacity(0.2))
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(lines) { line in
                        HStack(spacing: 0) {
                            Text("\(line.lineNumber)")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(JsonSyntaxHighlighter.lineNumColor)
                                .frame(width: 36, alignment: .trailing)
                                .padding(.trailing, 8)
                            Text(JsonSyntaxHighlighter.highlight(line.text))
                                .font(.system(size: 11, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.vertical, 1)
                        .padding(.leading, 4)
                        .background(line.isDiff ? Color.yellow.opacity(0.20) : Color.clear)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Auto Compare

    private func autoCompare() {
        leftError = ""; rightError = ""

        let trimLeft = left.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimRight = right.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimLeft.isEmpty || !trimRight.isEmpty else {
            leftLines = []; rightLines = []; diffCount = 0; return
        }

        let objA: Any?
        let objB: Any?

        if !trimLeft.isEmpty {
            if let d = trimLeft.data(using: .utf8), let obj = try? JSONSerialization.jsonObject(with: d) {
                objA = obj
            } else {
                leftError = "JSON 解析失败"
                objA = nil
            }
        } else { objA = nil }

        if !trimRight.isEmpty {
            if let d = trimRight.data(using: .utf8), let obj = try? JSONSerialization.jsonObject(with: d) {
                objB = obj
            } else {
                rightError = "JSON 解析失败"
                objB = nil
            }
        } else { objB = nil }

        let opts: JSONSerialization.WritingOptions = [.prettyPrinted, .sortedKeys]

        let strA = objA.flatMap { try? JSONSerialization.data(withJSONObject: $0, options: opts) }
            .flatMap { String(data: $0, encoding: .utf8) } ?? trimLeft
        let strB = objB.flatMap { try? JSONSerialization.data(withJSONObject: $0, options: opts) }
            .flatMap { String(data: $0, encoding: .utf8) } ?? trimRight

        let linesA = strA.components(separatedBy: "\n")
        let linesB = strB.components(separatedBy: "\n")
        let maxLen = max(linesA.count, linesB.count)

        var lResult: [DiffLine] = []
        var rResult: [DiffLine] = []
        var diffs = 0

        for i in 0..<maxLen {
            let la = i < linesA.count ? linesA[i] : ""
            let lb = i < linesB.count ? linesB[i] : ""
            let diff = la != lb
            if diff { diffs += 1 }
            lResult.append(DiffLine(lineNumber: i + 1, text: la, isDiff: diff))
            rResult.append(DiffLine(lineNumber: i + 1, text: lb, isDiff: diff))
        }

        leftLines = lResult
        rightLines = rResult
        diffCount = diffs
    }
}
