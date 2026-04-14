import SwiftUI

struct JsonDiffView: View {
    @State private var left: String = ""
    @State private var right: String = ""
    @State private var leftLines: [DiffLine] = []
    @State private var rightLines: [DiffLine] = []
    @State private var diffCount = 0
    @State private var errorMsg: String = ""
    @State private var hasCompared = false

    struct DiffLine: Identifiable {
        let id = UUID()
        let lineNumber: Int
        let text: String
        let isDiff: Bool
    }

    var body: some View {
        VStack(spacing: 0) {
            // Input row
            HStack(spacing: 8) {
                jsonInputPanel(title: "JSON A", text: $left)
                VStack(spacing: 8) {
                    Button {
                        compare()
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "arrow.left.arrow.right.circle.fill")
                                .font(.system(size: 26))
                                .foregroundColor(.accentColor)
                            Text("对比").font(.caption).foregroundColor(.accentColor)
                        }
                    }
                    .buttonStyle(.plain)
                    if hasCompared {
                        Button("清空") {
                            left = ""; right = ""
                            leftLines = []; rightLines = []
                            errorMsg = ""; hasCompared = false
                        }
                        .font(.caption).buttonStyle(.plain).foregroundColor(.secondary)
                    }
                }
                .frame(width: 56)
                jsonInputPanel(title: "JSON B", text: $right)
            }
            .padding(12)
            .frame(maxHeight: 200)

            if hasCompared {
                Divider()
                diffResultView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func jsonInputPanel(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundColor(.secondary)
            TextEditor(text: text)
                .font(.system(size: 11, design: .monospaced))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.3), lineWidth: 1))
        }
    }

    private var diffResultView: some View {
        VStack(spacing: 0) {
            // Status bar
            HStack {
                if errorMsg.isEmpty {
                    if diffCount == 0 {
                        Label("完全相同", systemImage: "checkmark.circle.fill")
                            .font(.caption).foregroundColor(.green)
                    } else {
                        Label("\(diffCount) 处差异", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption).foregroundColor(.orange)
                    }
                } else {
                    Label(errorMsg, systemImage: "xmark.circle.fill")
                        .font(.caption).foregroundColor(.red)
                }
                Spacer()
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 2).fill(Color.yellow.opacity(0.4)).frame(width: 14, height: 10)
                        Text("差异行").font(.caption2).foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(JsonSyntaxHighlighter.bgColor.opacity(0.8))

            // Side-by-side diff
            HStack(spacing: 0) {
                diffPanel(lines: leftLines, title: "JSON A")
                Divider().background(Color.gray.opacity(0.3))
                diffPanel(lines: rightLines, title: "JSON B")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(JsonSyntaxHighlighter.bgColor)
        }
    }

    private func diffPanel(lines: [DiffLine], title: String) -> some View {
        VStack(spacing: 0) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(JsonSyntaxHighlighter.lineNumColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(JsonSyntaxHighlighter.bgColor.opacity(0.9))
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
                        .background(line.isDiff ? Color.yellow.opacity(0.18) : Color.clear)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Compare Logic

    private func compare() {
        errorMsg = ""; leftLines = []; rightLines = []; diffCount = 0

        guard let dataA = left.data(using: .utf8),
              let objA = try? JSONSerialization.jsonObject(with: dataA) else {
            errorMsg = "JSON A 解析失败"; hasCompared = true; return
        }
        guard let dataB = right.data(using: .utf8),
              let objB = try? JSONSerialization.jsonObject(with: dataB) else {
            errorMsg = "JSON B 解析失败"; hasCompared = true; return
        }
        let opts: JSONSerialization.WritingOptions = [.prettyPrinted, .sortedKeys]
        let strA = (try? JSONSerialization.data(withJSONObject: objA, options: opts))
            .flatMap { String(data: $0, encoding: .utf8) } ?? ""
        let strB = (try? JSONSerialization.data(withJSONObject: objB, options: opts))
            .flatMap { String(data: $0, encoding: .utf8) } ?? ""

        let linesA = strA.components(separatedBy: "\n")
        let linesB = strB.components(separatedBy: "\n")
        let maxLen = max(linesA.count, linesB.count)

        var lResult: [DiffLine] = []
        var rResult: [DiffLine] = []

        for i in 0..<maxLen {
            let la = i < linesA.count ? linesA[i] : ""
            let lb = i < linesB.count ? linesB[i] : ""
            let diff = la != lb
            if diff { diffCount += 1 }
            lResult.append(DiffLine(lineNumber: i + 1, text: la, isDiff: diff))
            rResult.append(DiffLine(lineNumber: i + 1, text: lb, isDiff: diff))
        }

        leftLines = lResult
        rightLines = rResult
        hasCompared = true
    }
}
