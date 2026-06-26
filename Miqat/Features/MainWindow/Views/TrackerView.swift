import SwiftUI

// MARK: - Data

struct TrackerCell: Identifiable {
    let id = UUID()
    let prayer: Prayer
    let day: String
    let date: Int
    let status: PrayerTrackerStatus
    let isToday: Bool
}

struct TrackerDayColumn: Identifiable {
    let id = UUID()
    let day: String
    let date: Int
    let fullDate: Date
    let isToday: Bool
    let cells: [PrayerTrackerStatus?]  // nil = no record
}

// MARK: - Generic Tiles

// One generic cell tile — prayer × day intersection
struct TrackerCellTile: View {
    let status: PrayerTrackerStatus?  // nil = future, no record
    let isToday: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(background)

            if let status {
                Image(systemName: status.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(status.color)
            }
        }
        .frame(width: 44, height: 44)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isToday ? AppColor.accentTeal.opacity(0.4) : Color.clear, lineWidth: 1.5)
        )
    }

    private var background: Color {
        guard let status else { return Color.primary.opacity(0.04) }
        return status.color.opacity(0.15)
    }
}

// One generic day column header tile
struct TrackerDayHeader: View {
    let day: String
    let date: Int
    let isToday: Bool

    var body: some View {
        VStack(spacing: 4) {
            Text(day)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .tracking(0.5)
            Text("\(date)")
                .font(.system(size: 13, weight: isToday ? .bold : .medium))
                .foregroundStyle(isToday ? AppColor.accentTeal : .primary)
                .frame(width: 26, height: 26)
                .background {
                    if isToday {
                        Circle().stroke(AppColor.accentTeal, lineWidth: 1.5)
                    }
                }
        }
        .frame(width: 44)
    }
}

// MARK: - Tappable Cell (owns popover — anchors to itself)

struct TappableTrackerCell: View {
    @Environment(PrayerTrackerViewModel.self) private var trackerVM

    let prayer   : Prayer
    let status   : PrayerTrackerStatus?
    let record   : PrayerRecord?
    let date     : Date        // startOfDay
    let isToday  : Bool
    let isFuture : Bool
    let isCurrent: Bool
    var onUpdate : () -> Void

    @State private var showPicker = false

    var body: some View {
        TrackerCellTile(status: status, isToday: isToday)
            .opacity(isFuture ? 0.3 : 1)
            .onTapGesture { if !isFuture { showPicker = true } }
            .popover(isPresented: $showPicker, arrowEdge: .bottom) {
                PrayerStatusPicker(prayer: prayer, date: date, record: record, isCurrent: isCurrent) { newStatus in
                    if let record {
                        trackerVM.mark(record, as: newStatus)
                    } else {
                        trackerVM.create(prayer: prayer, prayerTime: date, status: newStatus)
                    }
                    showPicker = false
                    onUpdate()
                }
            }
    }
}

// MARK: - Tracker View

struct TrackerView: View {
    @Environment(PrayerTrackerViewModel.self) private var trackerVM
    @Environment(PrayerTimeViewModel.self)    private var prayerVM
    @Environment(SettingsViewModel.self)      private var settingsVM
    @State private var viewMode   : TrackerMode = .week
    @State private var weekOffset : Int = 0
    @State private var monthOffset: Int = 0
    @State private var weekCache  : [Date: [PrayerRecord]] = [:]
    @State private var monthCache : [Date: [PrayerRecord]] = [:]

    enum TrackerMode: String, CaseIterable {
        case week = "Week"
        case month = "Month"
    }

    private let prayers = Prayer.allCases.filter(\.isPrayer)

    private var weekStart: Date {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let weekday = cal.component(.weekday, from: today)
        let daysToMon = (weekday == 1 ? -6 : 2 - weekday)
        let monday = cal.date(byAdding: .day, value: daysToMon + weekOffset * 7, to: today)!
        return monday
    }

    private var columns: [TrackerDayColumn] {
        let cal  = Calendar.current
        let days = ["MON","TUE","WED","THU","FRI","SAT","SUN"]
        return (0..<7).map { offset in
            let date    = cal.date(byAdding: .day, value: offset, to: weekStart)!
            let key     = cal.startOfDay(for: date)
            let records = weekCache[key] ?? []
            let isToday = cal.isDateInToday(date)
            let cells   = prayers.map { prayer in
                records.first(where: { $0.prayer == prayer })?.status
            }
            return TrackerDayColumn(day: days[offset], date: cal.component(.day, from: date),
                                    fullDate: key, isToday: isToday, cells: cells)
        }
    }

    private func loadWeek() {
        weekCache = trackerVM.weekRecords(from: weekStart)
    }

    private var isAtPresent: Bool {
        viewMode == .week ? weekOffset >= 0 : monthOffset >= 0
    }

    private var weekLabel: String {
        let cal = Calendar.current
        let end = cal.date(byAdding: .day, value: 6, to: weekStart)!
        let f   = DateFormatter()
        f.dateFormat = "d MMM"
        let f2  = DateFormatter()
        f2.dateFormat = "d MMM yyyy"
        return "\(f.string(from: weekStart)) – \(f2.string(from: end))"
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            Divider().opacity(0.4)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    weekSummaryCards
                    if viewMode == .week {
                        trackerGrid
                        weekCompletionBars
                    } else {
                        monthlyGrid
                        prayerCompletionBars
                    }
                }
                .padding(24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { loadWeek(); loadMonth() }
        .onChange(of: weekOffset)   { loadWeek() }
        .onChange(of: monthOffset)  { loadMonth() }
    }

    // MARK: Top bar
    private var topBar: some View {
        HStack {
            HStack(spacing: 4) {
                Button { viewMode == .week ? (weekOffset -= 1) : (monthOffset -= 1) } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(7)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .buttonStyle(.plain)

                Text(viewMode == .week ? weekLabel : monthLabel)
                    .font(.system(size: 14, weight: .semibold))
                    .frame(minWidth: 140)

                Button { viewMode == .week ? (weekOffset += 1) : (monthOffset += 1) } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(isAtPresent ? Color.primary.opacity(0.2) : .secondary)
                        .padding(7)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(isAtPresent)
            }

            Spacer()

            // Week / Month toggle
            HStack(spacing: 0) {
                ForEach(TrackerMode.allCases, id: \.self) { mode in
                    Button { withAnimation(.spring(duration: 0.2)) { viewMode = mode } } label: {
                        Text(mode.rawValue)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(viewMode == mode ? .white : .secondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(viewMode == mode ? AppColor.accentTeal : Color.clear,
                                        in: RoundedRectangle(cornerRadius: 7))
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(Color(NSColor.controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.08), lineWidth: 1))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
    }

    // MARK: Monthly grid
    private var displayedMonth: Date {
        let cal  = Calendar.current
        let base = cal.date(from: cal.dateComponents([.year, .month], from: Date())) ?? Date()
        return cal.date(byAdding: .month, value: monthOffset, to: base) ?? base
    }

    private var monthLabel: String {
        let f = DateFormatter(); f.dateFormat = "MMMM yyyy"
        return f.string(from: displayedMonth)
    }

    private var monthlyColumns: [TrackerDayColumn] {
        let cal   = Calendar.current
        guard let range = cal.range(of: .day, in: .month, for: displayedMonth),
              let start = cal.date(from: cal.dateComponents([.year, .month], from: displayedMonth))
        else { return [] }

        return range.map { dayNum in
            let date    = cal.date(byAdding: .day, value: dayNum - 1, to: start)!
            let key     = cal.startOfDay(for: date)
            let records = monthCache[key] ?? []
            let isToday = cal.isDateInToday(date)
            let cells   = prayers.map { prayer in
                records.first(where: { $0.prayer == prayer })?.status
            }
            return TrackerDayColumn(day: "", date: dayNum, fullDate: key, isToday: isToday, cells: cells)
        }
    }

    private func loadMonth() {
        monthCache = trackerVM.monthRecords(for: displayedMonth)
    }

    private var monthlyGrid: some View {
        VStack(spacing: 0) {
            // Day numbers header
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    // Day number headers
                    HStack(spacing: 4) {
                        Text("").frame(width: 85)
                        ForEach(monthlyColumns) { col in
                            Text("\(col.date)")
                                .font(.system(size: 10, weight: col.isToday ? .bold : .regular))
                                .foregroundStyle(col.isToday ? AppColor.accentTeal : .secondary)
                                .frame(width: 28)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                    Divider().padding(.horizontal, 16).opacity(0.4)

                    // Prayer rows
                    VStack(spacing: 0) {
                        ForEach(Array(prayers.enumerated()), id: \.element) { index, prayer in
                            HStack(spacing: 4) {
                                // Prayer label
                                HStack(spacing: 6) {
                                    Image(systemName: prayer.icon)
                                        .font(.system(size: 11))
                                        .foregroundStyle(prayer.color)
                                    Text(prayer.rawValue)
                                        .font(.system(size: 11, weight: .medium))
                                }
                                .frame(width: 85, alignment: .leading)

                                // Small cells across all 30 days
                                ForEach(monthlyColumns) { col in
                                    let cal       = Calendar.current
                                    let today     = cal.startOfDay(for: Date())
                                    let isFuture  = col.fullDate > today
                                    let record    = (monthCache[col.fullDate] ?? []).first(where: { $0.prayer == prayer })
                                    let isCurrent = prayerVM.currentPrayer == prayer && col.isToday
                                    TappableTrackerCell(
                                        prayer: prayer, status: col.cells[index], record: record,
                                        date: col.fullDate, isToday: col.isToday,
                                        isFuture: isFuture, isCurrent: isCurrent
                                    ) { loadWeek(); loadMonth() }
                                    .frame(width: 28, height: 28)
                                    .scaleEffect(0.63)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 5)

                            if index < prayers.count - 1 {
                                Divider().padding(.leading, 98).opacity(0.3)
                            }
                        }
                    }
                    .padding(.bottom, 12)
                }
            }
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.06), lineWidth: 1))
    }

    // MARK: Weekly completion bars
    private var weekCompletionBars: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Weekly Completion")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(weekLabel)
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 12)

            Divider().padding(.horizontal, 16).opacity(0.4)

            VStack(spacing: 0) {
                ForEach(Array(weekPrayerCompletions.enumerated()), id: \.offset) { index, item in
                    PrayerCompletionBar(prayer: item.0, percent: item.1)
                    if index < weekPrayerCompletions.count - 1 {
                        Divider().padding(.leading, 100).opacity(0.3)
                    }
                }
            }
            .padding(.bottom, 8)
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.06), lineWidth: 1))
    }

    private var weekPrayerCompletions: [(Prayer, Double)] {
        let pastCols  = columns.filter { !($0.fullDate > Calendar.current.startOfDay(for: Date())) }
        let pastCount = Double(pastCols.count)
        guard pastCount > 0 else { return prayers.map { ($0, 0.0) } }
        return prayers.enumerated().map { i, prayer in
            let prayed = Double(pastCols.filter { $0.cells[i]?.keepsStreak == true }.count)
            return (prayer, prayed / pastCount)
        }
    }

    // MARK: Per-prayer completion bars
    private var prayerCompletionBars: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Monthly Completion")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(monthLabel)
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 12)

            Divider().padding(.horizontal, 16).opacity(0.4)

            VStack(spacing: 0) {
                ForEach(Array(prayerCompletions.enumerated()), id: \.offset) { index, item in
                    PrayerCompletionBar(prayer: item.0, percent: item.1)
                    if index < prayerCompletions.count - 1 {
                        Divider().padding(.leading, 100).opacity(0.3)
                    }
                }
            }
            .padding(.bottom, 8)
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.06), lineWidth: 1))
    }

    private var prayerCompletions: [(Prayer, Double)] {
        let cols = monthlyColumns.filter { !Calendar.current.isDateInToday(
            Calendar.current.date(from: DateComponents(
                year: Calendar.current.component(.year, from: displayedMonth),
                month: Calendar.current.component(.month, from: displayedMonth),
                day: $0.date
            )) ?? Date()
        )}
        let pastCount = Double(cols.count)
        guard pastCount > 0 else { return prayers.map { ($0, 0.0) } }
        return prayers.enumerated().map { i, prayer in
            let prayed = Double(cols.filter { $0.cells[i]?.keepsStreak == true }.count)
            return (prayer, prayed / pastCount)
        }
    }

    // MARK: Summary cards
    private var weekSummaryCards: some View {
        let weekPrayed  = columns.reduce(0) { $0 + $1.cells.filter { $0?.keepsStreak == true }.count }
        let weekTotal   = columns.filter { !$0.isToday }.count * prayers.count
        let weekPct     = weekTotal > 0 ? Int(Double(weekPrayed) / Double(weekTotal) * 100) : 0

        return HStack(spacing: 12) {
            SummaryCard(icon: "percent",               iconColor: AppColor.accentPurple,
                        label: "Completion",           value: "\(weekPct)%")
            SummaryCard(icon: "checkmark.circle.fill", iconColor: AppColor.accentTeal,
                        label: "This Week",            value: "\(weekPrayed)/\(weekTotal)")
            SummaryCard(icon: "star.fill",             iconColor: AppColor.accentGold,
                        label: "Best Streak",          value: "\(trackerVM.getMaxStreak().days) days")
            SummaryCard(icon: "flame.fill",            iconColor: AppColor.accentGold,
                        label: "Current Streak",       value: "\(trackerVM.currentStreak) days")
        }
    }

    // MARK: Tracker grid
    private var trackerGrid: some View {
        VStack(spacing: 0) {
            // Day headers row
            HStack(spacing: 8) {
                Text("")
                    .frame(width: 72)
                ForEach(columns) { col in
                    TrackerDayHeader(day: col.day, date: col.date, isToday: col.isToday)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider().padding(.horizontal, 16).opacity(0.4)

            // Prayer rows — one row per prayer, cells across days
            VStack(spacing: 0) {
                ForEach(Array(prayers.enumerated()), id: \.element) { index, prayer in
                    HStack(spacing: 8) {
                        // Prayer label
                        HStack(spacing: 8) {
                            Image(systemName: prayer.icon)
                                .font(.system(size: 13))
                                .foregroundStyle(prayer.color)
                                .frame(width: 18)
                            Text(prayer.rawValue)
                                .font(.system(size: 13, weight: .medium))
                        }
                        .frame(width: 85, alignment: .leading)

                        // Cells across all days
                        ForEach(Array(columns.enumerated()), id: \.element.id) { _, col in
                            let cal          = Calendar.current
                            let today        = cal.startOfDay(for: Date())
                            let isDateFuture = col.fullDate > today
                            let isPrayerFuture: Bool = col.isToday && {
                                guard let t = prayerVM.todayEntries.first(where: { $0.prayer == prayer })?.date
                                else { return true }
                                return t > Date()
                            }()
                            let isFuture  = isDateFuture || isPrayerFuture
                            let record    = (weekCache[col.fullDate] ?? []).first(where: { $0.prayer == prayer })
                            let isCurrent = prayerVM.currentPrayer == prayer && col.isToday
                            TappableTrackerCell(
                                prayer: prayer, status: col.cells[index], record: record,
                                date: col.fullDate, isToday: col.isToday,
                                isFuture: isFuture, isCurrent: isCurrent
                            ) { loadWeek(); loadMonth() }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)

                    if index < prayers.count - 1 {
                        Divider().padding(.leading, 106).opacity(0.3)
                    }
                }
            }
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.06), lineWidth: 1))
    }
}

// MARK: - Prayer Completion Bar (generic)

struct PrayerCompletionBar: View {
    let prayer: Prayer
    let percent: Double

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: prayer.icon)
                .font(.system(size: 13))
                .foregroundStyle(prayer.color)
                .frame(width: 18)

            Text(prayer.rawValue)
                .font(.system(size: 13, weight: .medium))
                .frame(width: 60, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.primary.opacity(0.06))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(barColor)
                        .frame(width: geo.size.width * percent, height: 8)
                }
            }
            .frame(height: 8)

            Text("\(Int(percent * 100))%")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(barColor)
                .frame(width: 36, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var barColor: Color {
        percent >= 0.8 ? AppColor.accentTeal :
        percent >= 0.5 ? AppColor.accentGold : AppColor.alert
    }
}

// MARK: - Summary Card (generic)

struct SummaryCard: View {
    let icon: String
    let iconColor: Color
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(iconColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 20, weight: .bold))
                Text(label)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.primary.opacity(0.06), lineWidth: 1))
    }
}
