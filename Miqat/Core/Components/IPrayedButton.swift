import SwiftUI

struct IPrayedButton: View {
    let prayer : Prayer
    let date   : Date
    var compact: Bool = false

    @Environment(PrayerTrackerViewModel.self) private var trackerVM
    @Environment(PrayerTimeViewModel.self)    private var prayerVM
    @State private var showPicker = false

    private var record        : PrayerRecord? { trackerVM.records(for: date).first(where: { $0.prayer == prayer }) }
    private var isCurrent     : Bool          { prayerVM.currentPrayer == prayer }
    private var prayed        : Bool          { record?.status.keepsStreak == true }
    private var accent        : Color         { prayer.color(for: date) }
    // Use the actual engine-calculated prayer time, not just the calendar date
    private var actualPrayerTime: Date {
        prayerVM.displayEntries.first(where: { $0.prayer == prayer })?.date ?? date
    }

    var body: some View {
        HStack(spacing: 4) {
            if !compact {
                // Left — default quick action: mark prayedOnTime
                Button {
                    guard !prayed else { return }
                    if let record { trackerVM.mark(record, as: .prayedOnTime) }
                    else { trackerVM.create(prayer: prayer, prayerTime: actualPrayerTime, status: .prayedOnTime) }
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: prayed ? (record?.status.icon ?? "checkmark.circle.fill") : "circle")
                            .font(.system(size: 13, weight: .semibold))
                        Text(prayed ? (record?.status.shortLabel ?? "Prayed") : "I Prayed")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .foregroundStyle(prayed ? accent : .white)
                    .background(prayed ? .white : .white.opacity(0.15), in: RoundedRectangle(cornerRadius: 9))
                }
                .buttonStyle(.plain)
            }

            // Pencil — opens picker (always shown)
            Button { showPicker = true } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.8))
                    .frame(width: 36, height: 36)
                    .background(.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 9))
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showPicker, arrowEdge: .bottom) {
                PrayerStatusPicker(prayer: prayer, date: date, record: record, isCurrent: isCurrent) { status in
                    if let record { trackerVM.mark(record, as: status) }
                    else { trackerVM.create(prayer: prayer, prayerTime: actualPrayerTime, status: status) }
                    showPicker = false
                }
            }
        }
    }
}
