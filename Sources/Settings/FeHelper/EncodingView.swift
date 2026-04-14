import SwiftUI
import CryptoKit

struct EncodingView: View {
    enum Mode: String, CaseIterable {
        case base64   = "Base64"
        case url      = "URL编码"
        case md5      = "MD5"
        case sha256   = "SHA256"
    }

    @State private var selectedMode: Mode = .base64
    @State private var input: String = ""
    @State private var output: String = ""
    @State private var encodeDirection: Direction = .encode

    enum Direction { case encode, decode }

    var body: some View {
        VStack(spacing: 0) {
            modeBar
            Divider()
            converterBody
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var modeBar: some View {
        HStack(spacing: 6) {
            ForEach(Mode.allCases, id: \.self) { m in
                Button(m.rawValue) {
                    selectedMode = m
                    output = ""
                }
                .font(.system(size: 12))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(selectedMode == m ? Color.accentColor.opacity(0.15) : Color.clear)
                .foregroundColor(selectedMode == m ? .accentColor : .secondary)
                .cornerRadius(5)
                .buttonStyle(.plain)
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(selectedMode == m ? Color.accentColor : Color.clear, lineWidth: 1))
            }
            Spacer()
            if selectedMode == .base64 || selectedMode == .url {
                Picker("", selection: $encodeDirection) {
                    Text("编码").tag(Direction.encode)
                    Text("解码").tag(Direction.decode)
                }
                .pickerStyle(.segmented)
                .frame(width: 100)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
    }

    private var converterBody: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("输入").font(.caption).foregroundColor(.secondary)
                    Spacer()
                    Button("清空") { input = ""; output = "" }
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

            Button {
                convert()
            } label: {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.accentColor)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("结果").font(.caption).foregroundColor(.secondary)
                    Spacer()
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
    }

    private func convert() {
        let trimmed = input
        switch selectedMode {
        case .base64:
            if encodeDirection == .encode {
                output = Data(trimmed.utf8).base64EncodedString()
            } else {
                if let data = Data(base64Encoded: trimmed),
                   let str = String(data: data, encoding: .utf8) {
                    output = str
                } else { output = "Base64 解码失败" }
            }
        case .url:
            if encodeDirection == .encode {
                output = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            } else {
                output = trimmed.removingPercentEncoding ?? ""
            }
        case .md5:
            let digest = Insecure.MD5.hash(data: Data(trimmed.utf8))
            output = digest.map { String(format: "%02hhx", $0) }.joined()
        case .sha256:
            let digest = SHA256.hash(data: Data(trimmed.utf8))
            output = digest.map { String(format: "%02hhx", $0) }.joined()
        }
    }
}
