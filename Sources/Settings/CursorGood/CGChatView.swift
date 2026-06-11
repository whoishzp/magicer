import SwiftUI
import AppKit

struct CGChatView: View {
    @ObservedObject private var mgr = CGSessionManager.shared
    @State private var inputText: String = ""
    @State private var pastedImages: [NSImage] = []
    @State private var isHoveringDrop = false
    @FocusState private var isInputFocused: Bool
    @State private var pasteMonitor: Any? = nil
    @State private var lastSessionId: String? = nil
    @AppStorage("cgInputHeight") private var inputHeight: Double = 120
    @State private var dragStartHeight: Double = 0

    private var session: CGSession? {
        guard let id = mgr.selectedSessionId else { return nil }
        return mgr.sessions.first { $0.id == id }
    }

    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !pastedImages.isEmpty
    }

    var body: some View {
        Group {
            if let session = session {
                VStack(spacing: 0) {
                    chatHeader(session)
                    Divider()
                    messageList(session)
                    Divider()
                    inputArea
                }
            } else {
                emptyState
            }
        }
        .onAppear {
            installPasteMonitor()
            lastSessionId = mgr.selectedSessionId
            if let sid = mgr.selectedSessionId {
                inputText = mgr.draftTexts[sid] ?? ""
            }
        }
        .onChange(of: mgr.selectedSessionId) { newId in
            if let old = lastSessionId {
                mgr.draftTexts[old] = inputText
            }
            inputText = mgr.draftTexts[newId ?? ""] ?? ""
            pastedImages = []
            lastSessionId = newId
        }
        .onDisappear {
            if let m = pasteMonitor { NSEvent.removeMonitor(m) }
            pasteMonitor = nil
        }
    }

    // MARK: - Header

    private func chatHeader(_ session: CGSession) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(session.displayTitle)
                    .font(.system(size: 14, weight: .semibold))
                Text("session: \(String(session.id.prefix(8)))…")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button {
                exportChat(session)
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("导出聊天记录")

            Button {
                mgr.deleteSession(id: session.id)
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("删除此会话")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Message list

    private func messageList(_ session: CGSession) -> some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(session.messages) { msg in
                        messageRow(msg)
                            .id(msg.id)
                    }
                }
                .padding(16)
            }
            .onChange(of: session.messages.count) { _ in
                scrollToBottom(proxy: proxy, session: session)
            }
            .onChange(of: mgr.selectedSessionId) { _ in
                scrollToBottom(proxy: proxy, session: session)
            }
            .onAppear {
                scrollToBottom(proxy: proxy, session: session)
            }
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy, session: CGSession) {
        guard let lastId = session.messages.last?.id else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo(lastId, anchor: .bottom)
            }
        }
    }

    @ViewBuilder
    private func messageRow(_ msg: CGMessage) -> some View {
        if msg.role == .ai {
            aiMessageView(msg)
        } else {
            userMessageView(msg)
        }
    }

    // MARK: - AI message bubble

    private func aiMessageView(_ msg: CGMessage) -> some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text(msg.text)
                    .font(.system(size: 13))
                    .foregroundColor(.primary)
                    .textSelection(.enabled)

                if !msg.options.isEmpty {
                    CGFlowLayout(spacing: 8) {
                        ForEach(msg.options, id: \.self) { opt in
                            Button(opt) {
                                submitReply(text: opt)
                            }
                            .buttonStyle(OptionButtonStyle())
                        }
                    }
                }

                Text(msg.timestamp, style: .time)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(Color(NSColor.windowBackgroundColor))
            .cornerRadius(10)

            Spacer()
        }
    }

    // MARK: - User message bubble

    private static let wechatGreen = Color(red: 0.58, green: 0.93, blue: 0.41)

    private func userMessageView(_ msg: CGMessage) -> some View {
        HStack {
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                if !msg.text.isEmpty {
                    Text(msg.text)
                        .font(.system(size: 13))
                        .foregroundColor(.black)
                        .textSelection(.enabled)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Self.wechatGreen)
                        .cornerRadius(10)
                }
                ForEach(msg.images, id: \.self) { b64 in
                    if let data = Data(base64Encoded: b64),
                       let img = NSImage(data: data) {
                        Image(nsImage: img)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 200)
                            .cornerRadius(8)
                    }
                }
                HStack(spacing: 4) {
                    if msg.deliveryStatus == .pending {
                        Image(systemName: "clock")
                            .font(.system(size: 9))
                            .foregroundColor(.orange)
                        Text("等待 AI 响应")
                            .font(.system(size: 10))
                            .foregroundColor(.orange)
                    }
                    Text(msg.timestamp, style: .time)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Input area

    private var inputArea: some View {
        VStack(spacing: 0) {
            // Drag handle to resize input area
            Rectangle()
                .fill(Color(NSColor.separatorColor).opacity(0.5))
                .frame(height: 4)
                .contentShape(Rectangle())
                .onHover { hovering in
                    if hovering {
                        NSCursor.resizeUpDown.push()
                    } else {
                        NSCursor.pop()
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 1)
                        .onChanged { value in
                            if dragStartHeight == 0 { dragStartHeight = inputHeight }
                            let newHeight = dragStartHeight - value.translation.height
                            inputHeight = min(max(newHeight, 80), 300)
                        }
                        .onEnded { _ in
                            dragStartHeight = 0
                        }
                )

            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    TextEditor(text: $inputText)
                        .font(.system(size: 13))
                        .scrollContentBackground(.hidden)
                        .focused($isInputFocused)
                        .frame(maxHeight: .infinity)

                    if !pastedImages.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(pastedImages.indices, id: \.self) { i in
                                    ZStack(alignment: .topTrailing) {
                                        Image(nsImage: pastedImages[i])
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 48, height: 48)
                                            .clipped()
                                            .cornerRadius(6)
                                        Button {
                                            pastedImages.remove(at: i)
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 14))
                                                .foregroundColor(.white)
                                        }
                                        .buttonStyle(.plain)
                                        .offset(x: 5, y: -5)
                                    }
                                }
                            }
                            .padding(.bottom, 6)
                        }
                    }

                    HStack(spacing: 8) {
                        Button {
                            pasteImageFromClipboard()
                        } label: {
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        .help("粘贴图片")

                        Spacer()

                        Text("Ctrl+Enter")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary.opacity(0.4))

                        Button {
                            sendInput()
                        } label: {
                            Text("发送")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(canSend ? .white : .secondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 5)
                                .background(canSend ? Color.blue : Color(NSColor.controlBackgroundColor))
                                .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                        .disabled(!canSend)
                        .keyboardShortcut(.return, modifiers: .control)
                    }
                    .padding(.top, 4)
                }
                .padding(10)
                .frame(height: max(inputHeight, 80))
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                )
                .padding(.horizontal, 12)
            }
            .padding(.vertical, 10)
        }
    }

    // MARK: - Actions

    private func sendInput() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty || !pastedImages.isEmpty,
              let sessionId = mgr.selectedSessionId else { return }

        let b64images = pastedImages.compactMap { img -> String? in
            guard let tiff = img.tiffRepresentation,
                  let bmp = NSBitmapImageRep(data: tiff),
                  let png = bmp.representation(using: .png, properties: [:]) else { return nil }
            return png.base64EncodedString()
        }

        mgr.submitReply(sessionId: sessionId, text: text, images: b64images)
        inputText = ""
        pastedImages = []
        mgr.draftTexts.removeValue(forKey: sessionId)
    }

    private func submitReply(text: String) {
        guard let sessionId = mgr.selectedSessionId else { return }
        mgr.submitReply(sessionId: sessionId, text: text, images: [])
    }

    private func exportChat(_ session: CGSession) {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        var lines: [String] = []
        lines.append("# \(session.displayTitle)")
        lines.append("Session: \(session.id)")
        lines.append("导出时间: \(df.string(from: Date()))")
        lines.append("")
        lines.append("---")
        lines.append("")
        for msg in session.messages {
            let role = msg.role == .ai ? "🤖 AI" : "👤 用户"
            let time = df.string(from: msg.timestamp)
            lines.append("**\(role)** (\(time))")
            lines.append("")
            if !msg.text.isEmpty { lines.append(msg.text) }
            if !msg.images.isEmpty {
                lines.append("_[\(msg.images.count) 张图片]_")
            }
            if !msg.options.isEmpty {
                lines.append("选项: \(msg.options.joined(separator: " | "))")
            }
            lines.append("")
        }
        let content = lines.joined(separator: "\n")
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        let safeName = session.displayTitle
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
        panel.nameFieldStringValue = "\(safeName).md"
        panel.message = "选择聊天记录导出位置"
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            try? content.write(to: url, atomically: true, encoding: .utf8)
        }
    }

    private func installPasteMonitor() {
        if pasteMonitor != nil { return }
        pasteMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [self] event in
            guard event.modifierFlags.intersection(.deviceIndependentFlagsMask) == .command,
                  event.charactersIgnoringModifiers == "v" else { return event }
            let pb = NSPasteboard.general
            guard let types = pb.types else { return event }
            let hasImage = types.contains(.png) || types.contains(.tiff)
            let hasText = types.contains(.string)
            if hasImage && !hasText {
                pasteImageFromClipboard()
                return nil
            }
            return event
        }
    }

    private func pasteImageFromClipboard() {
        let pb = NSPasteboard.general
        guard let img = NSImage(pasteboard: pb) else { return }
        pastedImages.append(img)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.3))
            Text("选择左侧会话查看对话")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            Spacer()
        }
    }
}

// MARK: - Option button style

private struct OptionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(configuration.isPressed
                        ? Color.green.opacity(0.3)
                        : Color(NSColor.controlBackgroundColor))
            .foregroundColor(.primary)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(NSColor.separatorColor), lineWidth: 1)
            )
    }
}

// MARK: - Simple flow layout

private struct CGFlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        var width: CGFloat = 0
        var height: CGFloat = 0
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0
        let maxWidth = proposal.width ?? .infinity

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth + size.width > maxWidth && rowWidth > 0 {
                width = max(width, rowWidth - spacing)
                height += rowHeight + spacing
                rowWidth = 0
                rowHeight = 0
            }
            rowWidth  += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        width  = max(width, rowWidth - spacing)
        height += rowHeight
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX && x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
