import SwiftUI

struct JsonBeautifyView: View {
    @State private var input: String = ""
    @State private var output: String = ""
    @State private var error: String = ""
    @State private var isCompact = false

    var body: some View {
        HStack(spacing: 0) {
            // Left: input
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("输入 JSON").font(.caption).foregroundColor(.secondary)
                    Spacer()
                    Button("清空") { input = ""; output = ""; error = "" }
                        .font(.caption).buttonStyle(.plain).foregroundColor(.secondary)
                    Button("粘贴") { input = NSPasteboard.general.string(forType: .string) ?? "" }
                        .font(.caption).buttonStyle(.plain).foregroundColor(.accentColor)
                }
                TextEditor(text: $input)
                    .font(.system(size: 12, design: .monospaced))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.3), lineWidth: 1))
            }
            .padding(12)

            VStack(spacing: 10) {
                Toggle("压缩", isOn: $isCompact)
                    .font(.caption).toggleStyle(.checkbox)
                Button {
                    formatJSON()
                } label: {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
                .help("格式化")
            }
            .padding(.vertical, 12)

            // Right: output
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("格式化结果").font(.caption).foregroundColor(.secondary)
                    Spacer()
                    if !error.isEmpty {
                        Text(error).font(.caption).foregroundColor(.red).lineLimit(1)
                    }
                    Button("复制") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(output, forType: .string)
                    }
                    .font(.caption).buttonStyle(.plain).foregroundColor(.accentColor)
                    .disabled(output.isEmpty)
                }
                TextEditor(text: $output)
                    .font(.system(size: 12, design: .monospaced))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.3), lineWidth: 1))
            }
            .padding(12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: input) { _ in
            if !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                formatJSON()
            }
        }
    }

    private func formatJSON() {
        error = ""
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard let data = input.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) else {
            error = "JSON 解析失败"
            output = ""
            return
        }
        let opts: JSONSerialization.WritingOptions = isCompact ? [] : [.prettyPrinted, .sortedKeys]
        if let formatted = try? JSONSerialization.data(withJSONObject: obj, options: opts),
           let str = String(data: formatted, encoding: .utf8) {
            output = str
        }
    }
}
