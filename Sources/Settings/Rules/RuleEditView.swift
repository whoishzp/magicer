import SwiftUI

struct RuleEditView: View {
    @Binding var rule: ReminderRule
    @State private var showDeleteAlert = false
    @State private var previewTheme: ThemeColors? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                basicSection
                timingSection
                if rule.actionKind == .desktop {
                    textSection
                    themeSection
                }
                controlSection
            }
            .padding(28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .navigationTitle(rule.name)
        .sheet(isPresented: Binding(
            get: { previewTheme != nil },
            set: { if !$0 { previewTheme = nil } }
        )) {
            if let t = previewTheme {
                ThemePreviewView(theme: t, ruleName: rule.name, reminderText: rule.reminderText)
                    .frame(width: 720, height: 480)
            }
        }
        .alert("删除规则", isPresented: $showDeleteAlert) {
            Button("删除", role: .destructive) {
                RulesStore.shared.deleteRules(at: IndexSet(
                    RulesStore.shared.rules.indices.filter { RulesStore.shared.rules[$0].id == rule.id }
                ))
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("确定删除规则「\(rule.name)」？此操作不可撤销。")
        }
    }

    // MARK: - Basic

    private var basicSection: some View {
        sectionCard("基本信息") {
            HStack {
                Text("规则名称")
                    .frame(width: 80, alignment: .leading)
                TextField("如：专注提醒", text: $rule.name)
                    .textFieldStyle(.roundedBorder)
            }
            HStack {
                Text("启用")
                    .frame(width: 80, alignment: .leading)
                Toggle("", isOn: $rule.isEnabled)
                    .labelsHidden()
                Spacer()
            }
        }
    }

    // MARK: - Timing (desktop vs script + inline panels)

    private var timingSection: some View {
        sectionCard("提醒时机") {
            HStack(spacing: 8) {
                Button {
                    withAnimation(.easeInOut(duration: 0.12)) { rule.actionKind = .desktop }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "rectangle.on.rectangle").font(.system(size: 11, weight: .medium))
                        Text("桌面提醒").font(.system(size: 12, weight: .medium))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .foregroundColor(rule.actionKind == .desktop ? .white : .secondary)
                }
                .buttonStyle(GlassTabButtonStyle(isSelected: rule.actionKind == .desktop, cornerRadius: 6))

                Button {
                    withAnimation(.easeInOut(duration: 0.12)) { rule.actionKind = .script }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "terminal.fill").font(.system(size: 11, weight: .medium))
                        Text("定时脚本").font(.system(size: 12, weight: .medium))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .foregroundColor(rule.actionKind == .script ? .white : .secondary)
                }
                .buttonStyle(GlassTabButtonStyle(isSelected: rule.actionKind == .script, cornerRadius: 6))

                Spacer()
            }

            if rule.actionKind == .desktop {
                DesktopTimingPanel(rule: $rule)
            } else {
                ScheduledScriptTimingPanel(rule: $rule)
            }
        }
    }

    // MARK: - Text

    private var textSection: some View {
        sectionCard("提示文字") {
            TextEditor(text: $rule.reminderText)
                .font(.body)
                .frame(height: 90)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )
        }
    }

    // MARK: - Theme

    private var themeSection: some View {
        sectionCard("蒙层风格") {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(ThemeColors.all, id: \.id) { theme in
                    ThemeCard(theme: theme, isSelected: rule.themeId == theme.id) {
                        previewTheme = theme
                    }
                    .onTapGesture { rule.themeId = theme.id }
                }
            }
        }
    }

    // MARK: - Controls

    private var controlSection: some View {
        HStack {
            Spacer()
            Button(role: .destructive) {
                showDeleteAlert = true
            } label: {
                Label("删除此规则", systemImage: "trash")
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: - Section Card Helper

    @ViewBuilder
    private func sectionCard<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            VStack(alignment: .leading, spacing: 14) {
                content()
            }
            .padding(16)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(10)
        }
    }
}
