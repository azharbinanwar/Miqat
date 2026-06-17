import SwiftUI

struct PrayerCardView: View {
    let entry: PrayerEntry

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                // Icon + name
                HStack {
                    Image(systemName: entry.prayer.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(entry.prayer.color)
                    Spacer()
                }

                Text(entry.prayer.rawValue)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)

                // Time
                Text(entry.time)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(timeColor)
                    .minimumScaleFactor(0.8)

                Text(entry.madhab)
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)

                Spacer()

                // Status
                statusBadge
            }
            .padding(12)
        }
        .frame(width: 110, height: 160)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(borderColor, lineWidth: 1.5)
        )
    }

    @ViewBuilder
    private var statusBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: statusIcon)
                .font(.system(size: 10))
            Text(entry.status.rawValue)
                .font(.system(size: 10, weight: .medium))
        }
        .foregroundStyle(statusColor)
    }

    private var statusIcon: String {
        switch entry.status {
        case .prayed:   return "checkmark.circle.fill"
        case .passed:   return "checkmark.circle.fill"
        case .current:  return "circle.fill"
        case .upcoming: return "bell"
        case .alert:    return "bell.fill"
        }
    }

    private var statusColor: Color {
        switch entry.status {
        case .prayed:   return Color(hex: "#0D9488")
        case .passed:   return Color(hex: "#0D9488")
        case .current:  return Color(hex: "#0D9488")
        case .upcoming: return .secondary
        case .alert:    return Color(hex: "#DC2626")
        }
    }

    private var timeColor: Color {
        if entry.isAlert { return Color(hex: "#DC2626") }
        if entry.isCurrent { return Color(hex: "#0D9488") }
        return .primary
    }

    private var borderColor: Color {
        if entry.isAlert   { return Color(hex: "#DC2626").opacity(0.6) }
        if entry.isCurrent { return Color(hex: "#0D9488").opacity(0.6) }
        return Color.primary.opacity(0.08)
    }

    @ViewBuilder
    private var cardBackground: some View {
        if entry.isCurrent {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(hex: "#0D9488").opacity(0.08))
        } else if entry.isAlert {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(hex: "#DC2626").opacity(0.06))
        } else {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(NSColor.controlBackgroundColor))
        }
    }
}
