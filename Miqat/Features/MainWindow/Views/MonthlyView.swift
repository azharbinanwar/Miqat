import SwiftUI

// MARK: - Data Models

struct DayEntry: Identifiable {
    let id      = UUID()
    let day     : Int
    let fullDate: Date
    let isToday : Bool
    let isCurrentMonth: Bool
}

struct MonthlyPrayerItem: Identifiable {
    let id           = UUID()
    let referenceTime: ReferenceTime
    let time         : String
    let status       : PrayerStatus
}

// MARK: - Prayer Tile

struct MonthlyPrayerTile: View {
    let item: MonthlyPrayerItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.referenceTime.icon)
                .font(.system(size: 13))
                .foregroundStyle(item.referenceTime.color)
                .frame(width: 20)

            Text(item.referenceTime.rawValue)
                .font(.system(size: 13))

            Spacer()

            Text(item.time)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(.secondary)

            statusIcon
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 11)
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch item.status {
        case .prayed:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 13))
                .foregroundStyle(item.referenceTime.color)
        case .passed:
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 13))
                .foregroundStyle(.secondary.opacity(0.5))
        case .current:
            Circle().fill(item.referenceTime.color).frame(width: 7, height: 7)
        case .alert:
            Image(systemName: "bell.fill")
                .font(.system(size: 11))
                .foregroundStyle(AppColor.alert)
        case .upcoming:
            Circle().stroke(Color.secondary.opacity(0.3), lineWidth: 1).frame(width: 7, height: 7)
        }
    }
}

// MARK: - Day Cell

struct DayCell: View {
    let day       : DayEntry
    let isSelected: Bool

    private let prayerColors: [Color] = ReferenceTime.allCases
        .filter { $0.isPrayer }
        .map(\.color)

    var body: some View {
        VStack(spacing: 5) {
            Text("\(day.day)")
                .font(.system(size: 13, weight: day.isToday ? .bold : .regular))
                .foregroundStyle(
                    !day.isCurrentMonth ? Color.secondary.opacity(0.3) :
                    isSelected          ? Color.white :
                    day.isToday         ? AppColor.accentTeal : Color.primary
                )
                .frame(width: 28, height: 28)
                .background {
                    if isSelected {
                        Circle().fill(AppColor.accentTeal)
                    } else if day.isToday {
                        Circle().stroke(AppColor.accentTeal, lineWidth: 1.5)
                    }
                }

            HStack(spacing: 2) {
                ForEach(Array(prayerColors.enumerated()), id: \.offset) { _, color in
                    Circle()
                        .fill(day.isCurrentMonth ? color.opacity(day.isToday ? 0.9 : 0.45) : Color.clear)
                        .frame(width: 4, height: 4)
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .opacity(day.isCurrentMonth ? 1 : 0.3)
    }
}

// MARK: - Monthly View

struct MonthlyView: View {
    @Environment(PrayerTimeViewModel.self) private var prayerVM
    @Environment(SettingsViewModel.self)  private var settingsVM

    @State private var displayedMonth: Date = Calendar.current.startOfMonth(for: Date())
    @State private var selectedDate  : Date? = Date()
    @State private var selectedItems : [MonthlyPrayerItem] = []

    private let columns  = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            calendarPanel
            Divider()
            detailPanel.frame(width: 260)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { loadPrayerItems(for: selectedDate ?? Date()) }
    }

    // MARK: Calendar panel

    private var calendarPanel: some View {
        VStack(spacing: 0) {
            monthHeader
            Divider().opacity(0.4)
            weekdayLabels
            Divider().opacity(0.4)

            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(buildDays(for: displayedMonth)) { day in
                    DayCell(day: day, isSelected: selectedDate.map {
                        Calendar.current.isDate($0, inSameDayAs: day.fullDate)
                    } ?? false)
                    .onTapGesture {
                        guard day.isCurrentMonth else { return }
                        withAnimation(.easeInOut(duration: 0.15)) { selectedDate = day.fullDate }
                        loadPrayerItems(for: day.fullDate)
                    }
                }
            }
            .padding(12)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var monthHeader: some View {
        HStack {
            Button {
                displayedMonth = Calendar.current.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(8)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)

            Spacer()
            Text(monthTitle).font(.system(size: 16, weight: .bold))
            Spacer()

            Button {
                displayedMonth = Calendar.current.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(8)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private var weekdayLabels: some View {
        HStack {
            ForEach(weekdays, id: \.self) { day in
                Text(day)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: Detail panel

    private var detailPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 3) {
                Text(selectedDate != nil ? gregorianDate : "Select a day")
                    .font(.system(size: 15, weight: .bold))
                Text(selectedDate != nil ? hijriDate : "")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)

            Divider().opacity(0.4)

            if !selectedItems.isEmpty {
                VStack(spacing: 0) {
                    ForEach(Array(selectedItems.enumerated()), id: \.element.id) { index, item in
                        MonthlyPrayerTile(item: item)
                        if index < selectedItems.count - 1 {
                            Divider().padding(.leading, 52).opacity(0.3)
                        }
                    }
                }
                .padding(.top, 4)
            } else {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.system(size: 32))
                        .foregroundStyle(.quaternary)
                    Text("Tap a day")
                        .font(.system(size: 13))
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                Spacer()
            }
        }
        .background(.ultraThinMaterial)
    }

    // MARK: Helpers

    private var monthTitle: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: displayedMonth)
    }

    private var gregorianDate: String {
        guard let date = selectedDate else { return "" }
        let f = DateFormatter()
        f.dateFormat = "MMMM d, yyyy"
        return f.string(from: date)
    }

    private var hijriDate: String {
        guard let date = selectedDate else { return "" }
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .islamicUmmAlQura)
        f.dateFormat = "d MMMM yyyy"
        return f.string(from: date)
    }

    private func buildDays(for month: Date) -> [DayEntry] {
        let cal = Calendar.current
        guard let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: month)),
              let range = cal.range(of: .day, in: .month, for: month)
        else { return [] }

        let firstWeekday = cal.component(.weekday, from: monthStart) - 1
        var days: [DayEntry] = []

        // Leading days from previous month
        for offset in (1...max(1, firstWeekday)).reversed() {
            if firstWeekday == 0 { break }
            let date = cal.date(byAdding: .day, value: -offset, to: monthStart)!
            days.append(DayEntry(day: cal.component(.day, from: date), fullDate: date,
                                 isToday: false, isCurrentMonth: false))
        }

        // Current month
        for dayNum in range {
            let date = cal.date(byAdding: .day, value: dayNum - 1, to: monthStart)!
            days.append(DayEntry(day: dayNum, fullDate: date,
                                 isToday: cal.isDateInToday(date), isCurrentMonth: true))
        }

        // Trailing days
        let trailing = (7 - days.count % 7) % 7
        if trailing > 0, let lastDay = days.last {
            for offset in 1...trailing {
                let date = cal.date(byAdding: .day, value: offset, to: lastDay.fullDate)!
                days.append(DayEntry(day: cal.component(.day, from: date), fullDate: date,
                                     isToday: false, isCurrentMonth: false))
            }
        }

        return days
    }

    private func loadPrayerItems(for date: Date) {
        let repo     = ServiceLocator.shared.resolve(LocationRepository.self)
        let location = repo.getActiveLocation() ?? Location.presets[0]
        let settings = settingsVM.settings.prayerCalculationSettings
        let cal      = Calendar.current
        let isToday  = cal.isDateInToday(date)
        let isPast   = date < cal.startOfDay(for: Date()) && !isToday

        let entries = PrayerEngineService().calculateTimes(for: date, location: location, settings: settings)

        selectedItems = entries.enumerated().map { idx, entry in
            let status: PrayerStatus
            if isToday {
                status = entry.status
            } else if isPast {
                // Deterministic pseudo-random: looks realistic without CoreData
                status = (idx + cal.component(.day, from: date)) % 5 == 0 ? .passed : .prayed
            } else {
                status = .upcoming
            }
            return MonthlyPrayerItem(referenceTime: entry.referenceTime, time: entry.time, status: status)
        }
    }
}

// MARK: - Calendar Extension

private extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let comps = dateComponents([.year, .month], from: date)
        return self.date(from: comps) ?? date
    }
}
