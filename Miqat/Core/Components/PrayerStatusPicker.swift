import SwiftUI

struct PrayerStatusPicker: View {
    let prayer   : Prayer
    let date     : Date
    let record   : PrayerRecord?
    let isCurrent: Bool
    let onSelect : (PrayerTrackerStatus) -> Void

    private var prayerLabel: String  { prayer.label(for: date) }
    private var prayerColor: Color   { prayer.color(for: date) }
    private var isJumuah: Bool       { prayerLabel == "Jumu'ah" }

    private var options: [PrayerTrackerStatus] {
        let base = isCurrent
            ? PrayerTrackerStatus.allCases.filter { $0 != .prayedKaza && $0 != .missed }
            : PrayerTrackerStatus.allCases
        return base.filter { $0 != record?.status }
    }

    private func rowLabel(for status: PrayerTrackerStatus) -> String {
        status == .prayedWithJamaat && isJumuah ? "Prayed \(prayerLabel)" : status.label
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: prayer.icon)
                        .font(.system(size: 15))
                        .foregroundStyle(prayerColor)
                    Text(prayerLabel)
                        .font(.system(size: 14, weight: .bold))
                    Spacer()
                    if let current = record?.status {
                        HStack(spacing: 4) {
                            Image(systemName: current.icon).font(.system(size: 10))
                            Text(current.shortLabel).font(.system(size: 11, weight: .medium))
                        }
                        .foregroundStyle(current.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(current.color.opacity(0.12), in: Capsule())
                    }
                }
                if isJumuah {
                    Text("\(prayerLabel) · \(date.formatted(.dateTime.weekday(.wide)))")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.primary.opacity(0.04))

            Divider().opacity(0.5)

            ForEach(options, id: \.self) { status in
                Button { onSelect(status) } label: {
                    HStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(status.color.opacity(0.15))
                                .frame(width: 28, height: 28)
                            Image(systemName: status.icon)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(status.color)
                        }
                        Text(rowLabel(for: status))
                            .font(.system(size: 13))
                            .foregroundStyle(.primary)
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if status != options.last {
                    Divider().padding(.leading, 52).opacity(0.25)
                }
            }
        }
        .frame(width: 230)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .focusEffectDisabled()
    }
}
