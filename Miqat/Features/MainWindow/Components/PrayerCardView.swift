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

                Text(entry.label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)

                // Time
                Text(entry.time)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(timeColor)
                    .minimumScaleFactor(0.8)

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
        case .current:  return "circle.fill"
        case .soon:     return "bell.fill"
        case .upcoming: return entry.isPast ? "checkmark.circle" : "bell"
        }
    }

    private var statusColor: Color {
        switch entry.status {
        case .current:  return entry.prayer.color
        case .soon:     return AppColor.softAmber
        case .upcoming: return entry.isPast ? entry.prayer.color : .secondary
        }
    }

    private var timeColor: Color {
        if entry.status == .soon    { return AppColor.softAmber }
        if entry.isCurrent          { return entry.prayer.color }
        return .primary
    }

    private var borderColor: Color {
        if entry.status == .soon   { return AppColor.softAmber.opacity(0.6) }
        if entry.isCurrent         { return entry.prayer.color.opacity(0.6) }
        return Color.primary.opacity(0.08)
    }

    @ViewBuilder
    private var cardBackground: some View {
        if entry.isCurrent {
            RoundedRectangle(cornerRadius: 14)
                .fill(entry.prayer.color.opacity(0.08))
        } else if entry.status == .soon {
            RoundedRectangle(cornerRadius: 14)
                .fill(AppColor.alert.opacity(0.06))
        } else {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(NSColor.controlBackgroundColor))
        }
    }
}
