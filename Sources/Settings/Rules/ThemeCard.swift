import SwiftUI

/// Theme selection card shown in the rule editor's overlay style grid.
struct ThemeCard: View {
    let theme: ThemeColors
    let isSelected: Bool
    let onPreview: () -> Void

    @State private var hovered = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(theme.swiftUIBackground)
                .frame(height: 88)

            VStack(spacing: 6) {
                Text("⏸")
                    .font(.title2)
                    .foregroundColor(theme.swiftUIPrimary)
                Text(theme.name)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.swiftUILabelColor)
            }

            // Preview button appears on hover (top-right corner)
            if hovered {
                VStack {
                    HStack {
                        Spacer()
                        Button { onPreview() } label: {
                            Image(systemName: "eye.fill")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(theme.swiftUILabelColor.opacity(0.8))
                                .padding(5)
                                .background(Color(theme.background).opacity(0.7))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .padding(6)
                    }
                    Spacer()
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    isSelected
                        ? theme.swiftUIPrimary
                        : (theme.isDark ? Color.secondary.opacity(0.2) : Color.secondary.opacity(0.35)),
                    lineWidth: isSelected ? 3 : 1
                )
        )
        .overlay(
            isSelected && !theme.isDark
                ? RoundedRectangle(cornerRadius: 10)
                    .stroke(theme.swiftUIPrimary.opacity(0.5), lineWidth: 6)
                    .blur(radius: 3)
                    .padding(-2)
                : nil
        )
        .shadow(color: isSelected ? theme.swiftUIPrimary.opacity(theme.isDark ? 0.45 : 0.5) : .clear,
                radius: isSelected ? 8 : 0)
        .scaleEffect(isSelected ? 1.03 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
        .contentShape(Rectangle())
        .onHover { inside in
            hovered = inside
            if inside { NSCursor.pointingHand.push() } else { NSCursor.pop() }
        }
    }
}
