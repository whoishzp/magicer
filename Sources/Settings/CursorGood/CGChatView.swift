import SwiftUI
import AppKit

struct CGChatView: View {
    @ObservedObject private var mgr = CGSessionManager.shared
    @State private var inputText: String = ""
    @State private var pastedImages: [NSImage] = []
    @State private var isHoveringDrop = false
    @FocusState private var isInputFocused: Bool
    @State private var pasteMonitor: Any? = nil

    private var session: CGSession? {
        guard let id = mgr.selectedSessionId else { return nil }
        return mgr.sessions.first { $0.id == id }
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
            pasteMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [self] event in
                // Intercept Cmd+V only when clipboard contains image data
                if event.modifierFlags.contains(.command),
                   event.characters == "v",
                   let types = NSPasteboard.general.types,
                   types.contains(.png) || types.contains(.tiff) {
                    pasteImageFromClipboard()
                    return nil  // consume event
                }
                return event  // pass through (let TextEditor handle text paste)
            }
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
                if let lastId = session.messages.last?.id {
                    withAnimation { proxy.scrollTo(lastId, anchor: .bottom) }
                }
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
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 13))
                    .foregroundColor(.blue)
                    .frame(width: 20)
                Text(msg.text)
                    .font(.system(size: 13))
                    .textSelection(.enabled)
                Spacer()
            }

            // Option buttons
            if !msg.options.isEmpty {
                CGFlowLayout(spacing: 8) {
                    ForEach(msg.options, id: \.self) { opt in
                        Button(opt) {
                            submitReply(text: opt)
                        }
                        .buttonStyle(OptionButtonStyle())
                    }
                }
                .padding(.leading, 28)
            }

            Text(msg.timestamp, style: .time)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .padding(.leading, 28)
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }

    // MARK: - User message bubble

    private func userMessageView(_ msg: CGMessage) -> some View {
        HStack {
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                if !msg.text.isEmpty {
                    Text(msg.text)
                        .font(.system(size: 13))
                        .foregroundColor(.white)
                        .textSelection(.enabled)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                // Attached images
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
                Text(msg.timestamp, style: .time)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Input area

    private var inputArea: some View {
        VStack(spacing: 8) {
            // Pasted images preview
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
                    .padding(.horizontal, 12)
                }
            }

            HStack(alignment: .bottom, spacing: 8) {
                TextEditor(text: $inputText)
                    .font(.system(size: 13))
                    .frame(minHeight: 36, maxHeight: 100)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                    )
                    .focused($isInputFocused)

                VStack(spacing: 4) {
                    Button {
                        pasteImageFromClipboard()
                    } label: {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .padding(6)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .help("粘贴图片")

                    Button {
                        sendInput()
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && pastedImages.isEmpty
                                        ? Color.secondary : Color.blue)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && pastedImages.isEmpty)
                    .help("发送（Ctrl+Enter）")
                    .keyboardShortcut(.return, modifiers: .control)
                }
            }
            .padding(.horizontal, 12)

            Text("Ctrl+Enter 发送")
                .font(.system(size: 10))
                .foregroundColor(.secondary.opacity(0.5))
        }
        .padding(.vertical, 10)
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
    }

    private func submitReply(text: String) {
        guard let sessionId = mgr.selectedSessionId else { return }
        mgr.submitReply(sessionId: sessionId, text: text, images: [])
    }

    private func pasteImageFromClipboard() {
        let pb = NSPasteboard.general
        guard let types = pb.types,
              let type = types.first(where: { $0 == .png || $0 == .tiff }),
              let data = pb.data(forType: type),
              let img = NSImage(data: data) else { return }
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
                        ? Color.blue.opacity(0.8)
                        : Color.blue.opacity(0.15))
            .foregroundColor(.blue)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.blue.opacity(0.4), lineWidth: 1)
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
