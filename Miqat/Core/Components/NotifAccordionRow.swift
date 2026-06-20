import SwiftUI

struct NotifAccordionRow<Content: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    var subtitle: String?
    @Binding var enabled: Bool
    @ViewBuilder let content: () -> Content

    @State private var expanded = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Button {
                    withAnimation(.spring(duration: 0.22)) { expanded.toggle() }
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: icon)
                            .font(.system(size: 14))
                            .foregroundStyle(enabled ? iconColor : .secondary.opacity(0.35))
                            .frame(width: 20)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(title)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(enabled ? .primary : .secondary)

                            if enabled, let subtitle {
                                Text(subtitle)
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        if enabled {
                            Image(systemName: expanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(!enabled)

                Toggle("", isOn: $enabled)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .tint(iconColor)
                    .onChange(of: enabled) { _, on in
                        if !on { withAnimation { expanded = false } }
                    }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            if expanded && enabled {
                VStack(spacing: 0) {
                    Divider().padding(.horizontal, 16).opacity(0.3)
                    content()
                }
                .background(Color.primary.opacity(0.03))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}
