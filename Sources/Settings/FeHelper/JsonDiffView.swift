import SwiftUI

struct JsonDiffView: View {
    @State private var left: String = ""
    @State private var right: String = ""
    @State private var diffResult: [DiffLine] = []
    @State private var errorMsg: String = ""

    struct DiffLine: Identifiable {
        let id = UUID()
        let text: String
        let kind: Kind
        enum Kind { case same, added, removed }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Inputs
            HStack(spacing: 8) {
                jsonInputPanel(title: "JSON A", text: $left)
                VStack {
                    Button {
                        compare()
                    } label: {
                        Image(systemName: "arrow.left.arrow.right.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.accentColor)
                    }
                    .buttonStyle(.plain).help("对比")
                }
                jsonInputPanel(title: "JSON B", text: $right)
            }
            .padding(12)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if !diffResult.isEmpty || !errorMsg.isEmpty {
                Divider()
                diffResultPanel
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func jsonInputPanel(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title).font(.caption).foregroundColor(.secondary)
                Spacer()
                Button("清空") { text.wrappedValue = "" }
                    .font(.caption).buttonStyle(.plain).foregroundColor(.secondary)
            }
            TextEditor(text: text)
                .font(.system(size: 12, design: .monospaced))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.3), lineWidth: 1))
        }
    }

    private var diffResultPanel: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                if errorMsg.isEmpty {
                    Text("对比结果").font(.caption).foregroundColor(.secondary)
                    Spacer()
                    let diffs = diffResult.filter { $0.kind != .same }.count
                    Text(diffs == 0 ? "完全相同 ✓" : "\(diffs) 处差异")
                        .font(.caption)
                        .foregroundColor(diffs == 0 ? .green : .orange)
                } else {
                    Text(errorMsg).font(.caption).foregroundColor(.red)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)

            if errorMsg.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 1) {
                        ForEach(diffResult) { line in
                            Text(line.text)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(lineColor(line.kind))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 1)
                                .background(lineBg(line.kind))
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
                }
                .frame(maxHeight: 200)
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
    }

    private func lineColor(_ kind: DiffLine.Kind) -> Color {
        switch kind {
        case .same: return .primary
        case .added: return .green
        case .removed: return .red
        }
    }

    private func lineBg(_ kind: DiffLine.Kind) -> Color {
        switch kind {
        case .same: return .clear
        case .added: return Color.green.opacity(0.08)
        case .removed: return Color.red.opacity(0.08)
        }
    }

    private func compare() {
        errorMsg = ""
        diffResult = []
        guard let dataA = left.data(using: .utf8),
              let objA = try? JSONSerialization.jsonObject(with: dataA) else {
            errorMsg = "JSON A 解析失败"; return
        }
        guard let dataB = right.data(using: .utf8),
              let objB = try? JSONSerialization.jsonObject(with: dataB) else {
            errorMsg = "JSON B 解析失败"; return
        }
        let optsA = try? JSONSerialization.data(withJSONObject: objA, options: [.prettyPrinted, .sortedKeys])
        let optsB = try? JSONSerialization.data(withJSONObject: objB, options: [.prettyPrinted, .sortedKeys])
        let linesA = (String(data: optsA ?? Data(), encoding: .utf8) ?? "").components(separatedBy: "\n")
        let linesB = (String(data: optsB ?? Data(), encoding: .utf8) ?? "").components(separatedBy: "\n")
        diffResult = simpleDiff(linesA, linesB)
    }

    private func simpleDiff(_ a: [String], _ b: [String]) -> [DiffLine] {
        var results: [DiffLine] = []
        let setA = Set(a.enumerated().map { "\($0.offset):\($0.element)" })
        let setB = Set(b.enumerated().map { "\($0.offset):\($0.element)" })
        let maxLen = max(a.count, b.count)
        for i in 0..<maxLen {
            let la = i < a.count ? a[i] : nil
            let lb = i < b.count ? b[i] : nil
            if la == lb {
                results.append(DiffLine(text: "  \(la ?? "")", kind: .same))
            } else {
                if let la { results.append(DiffLine(text: "- \(la)", kind: .removed)) }
                if let lb { results.append(DiffLine(text: "+ \(lb)", kind: .added)) }
            }
        }
        _ = setA; _ = setB
        return results
    }
}
