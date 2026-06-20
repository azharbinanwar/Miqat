import SwiftUI

/// Tappable settings row: icon + label on left, current value + chevron on right.
/// Use for any row that opens a picker, sheet, or dialog.
struct SettingsDetailRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(iconColor)
                    .frame(width: 20)

                Text(title)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)

                Spacer()

                Text(value)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.primary)

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
