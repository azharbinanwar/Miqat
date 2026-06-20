import SwiftUI

struct AdjustmentRow: View {
    let label: String
    let icon: String
    let iconColor: Color
    @Binding var value: Int
    var range: ClosedRange<Int> = -30...30
    var step: Int = 1
    var unit: String = "min"
    var showSign: Bool = true

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(iconColor)
                .frame(width: 28, height: 28)
                .background(iconColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 7))

            Text(label)
                .font(.system(size: 13, weight: .medium))

            Spacer()

            HStack(spacing: 0) {
                Button {
                    if value - step >= range.lowerBound { value -= step }
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(value > range.lowerBound ? .primary : .tertiary)
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Text(displayValue)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(valueColor)
                    .frame(width: 36, alignment: .center)

                Button {
                    if value + step <= range.upperBound { value += step }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(value < range.upperBound ? .primary : .tertiary)
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .background(Color(NSColor.controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.08), lineWidth: 1))

            if !unit.isEmpty {
                Text(unit)
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                    .frame(width: 24, alignment: .leading)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
    }

    private var displayValue: String {
        if !showSign { return "\(value)" }
        if value == 0 { return "0" }
        return value > 0 ? "+\(value)" : "\(value)"
    }

    private var valueColor: Color {
        if !showSign { return AppColor.accentTeal }
        if value == 0 { return .secondary }
        return value > 0 ? AppColor.accentTeal : AppColor.alert
    }
}
