import SwiftUI

// MARK: - Data Models

struct DayEntry: Identifiable {
    let id = UUID()
    let date: Int
    let isToday: Bool
    let isCurrentMonth: Bool
    let prayerDots: [DotStatus]
}

enum DotStatus {
    case prayed, missed, upcoming, none
    var color: Color {
        switch self {
        case .prayed:   return AppColor.teal
        case .missed:   return AppColor.alert
        case .upcoming: return AppColor.upcoming
        case .none:     return Color.clear
        }
    }
}

struct MonthlyPrayerItem: Identifiable {
    let id = UUID()
    let referenceTime: ReferenceTime
    let time: String
    let status: PrayerStatus
}

// MARK: - Generic Tiles

// One generic tile for every prayer row in the detail panel
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
                .foregroundStyle(AppColor.teal)
        case .passed:
            Image(systemName: "minus.circle")
                .font(.system(size: 13))
                .foregroundStyle(.tertiary)
        default:
            Circle()
                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                .frame(width: 13, height: 13)
        }
    }
}

// One generic tile for every day cell in the calendar grid
struct DayCell: View {
    let day: DayEntry
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 5) {
            Text("\(day.date)")
                .font(.system(size: 13, weight: day.isToday ? .bold : .regular))
                .foregroundStyle(
                    !day.isCurrentMonth ? Color.secondary.opacity(0.3) :
                    isSelected          ? Color.white :
                    day.isToday         ? AppColor.teal : Color.primary
                )
                .frame(width: 28, height: 28)
                .background {
                    if isSelected {
                        Circle().fill(AppColor.teal)
                    } else if day.isToday {
                        Circle().stroke(AppColor.teal, lineWidth: 1.5)
                    }
                }

            HStack(spacing: 2) {
                ForEach(Array(day.prayerDots.enumerated()), id: \.offset) { _, dot in
                    Circle()
                        .fill(day.isCurrentMonth ? dot.color : Color.clear)
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
    @State private var selectedDay: DayEntry? = nil

    private let days    = MonthlyView.mockDays()
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    private let mockPrayerItems: [MonthlyPrayerItem] = [
        MonthlyPrayerItem(referenceTime: .fajr,    time: "4:18 AM",  status: .prayed),
        MonthlyPrayerItem(referenceTime: .sunrise, time: "5:47 AM",  status: .passed),
        MonthlyPrayerItem(referenceTime: .dhuhr,   time: "12:08 PM", status: .prayed),
        MonthlyPrayerItem(referenceTime: .asr,     time: "4:42 PM",  status: .upcoming),
        MonthlyPrayerItem(referenceTime: .maghrib, time: "7:21 PM",  status: .upcoming),
        MonthlyPrayerItem(referenceTime: .isha,    time: "8:54 PM",  status: .upcoming),
    ]

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            calendarPanel
            Divider()
            detailPanel
                .frame(width: 260)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Calendar panel
    private var calendarPanel: some View {
        VStack(spacing: 0) {
            monthHeader
            Divider().opacity(0.4)
            weekdayLabels
            Divider().opacity(0.4)

            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(days) { day in
                    DayCell(day: day, isSelected: selectedDay?.id == day.id)
                        .onTapGesture {
                            guard day.isCurrentMonth else { return }
                            withAnimation(.easeInOut(duration: 0.15)) { selectedDay = day }
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
            Button { } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(8)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)

            Spacer()
            Text("June 2026").font(.system(size: 16, weight: .bold))
            Spacer()

            Button { } label: {
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
                Text(selectedDay != nil ? "June \(selectedDay!.date), 2026" : "Select a day")
                    .font(.system(size: 15, weight: .bold))
                Text(selectedDay != nil ? "21 Dhul Hijjah 1447" : "")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)

            Divider().opacity(0.4)

            if selectedDay != nil {
                VStack(spacing: 0) {
                    ForEach(Array(mockPrayerItems.enumerated()), id: \.element.id) { index, item in
                        MonthlyPrayerTile(item: item)
                        if index < mockPrayerItems.count - 1 {
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

    // MARK: Mock data
    static func mockDays() -> [DayEntry] {
        var days: [DayEntry] = []
        for d in [29, 30, 31] {
            days.append(DayEntry(date: d, isToday: false, isCurrentMonth: false,
                                 prayerDots: [.none, .none, .none, .none, .none]))
        }
        for d in 1...30 {
            let isPast  = d < 18
            let isToday = d == 18
            let dots: [DotStatus] = isPast
                ? [.prayed, .prayed, d % 4 == 0 ? .missed : .prayed, d % 6 == 0 ? .missed : .prayed, .prayed]
                : isToday
                    ? [.prayed, .prayed, .upcoming, .upcoming, .upcoming]
                    : [.none, .none, .none, .none, .none]
            days.append(DayEntry(date: d, isToday: isToday, isCurrentMonth: true, prayerDots: dots))
        }
        return days
    }
}
