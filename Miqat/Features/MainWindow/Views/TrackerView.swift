import SwiftUI

// MARK: - Data

enum TrackerStatus {
    case prayed, missed, upcoming, future
}

struct TrackerCell: Identifiable {
    let id = UUID()
    let prayer: Prayer
    let day: String
    let date: Int
    let status: TrackerStatus
    let isToday: Bool
}

struct TrackerDayColumn: Identifiable {
    let id = UUID()
    let day: String
    let date: Int
    let isToday: Bool
    let cells: [TrackerStatus]   // one per prayer: fajr dhuhr asr maghrib isha
}

// MARK: - Generic Tiles

// One generic cell tile — prayer × day intersection
struct TrackerCellTile: View {
    let status: TrackerStatus
    let isToday: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(background)

            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(iconColor)
        }
        .frame(width: 44, height: 44)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isToday ? Color(hex: "#0D9488").opacity(0.4) : Color.clear, lineWidth: 1.5)
        )
    }

    private var background: Color {
        switch status {
        case .prayed:   return Color(hex: "#0D9488").opacity(0.15)
        case .missed:   return Color(hex: "#DC2626").opacity(0.12)
        case .upcoming: return Color(hex: "#F59E0B").opacity(0.1)
        case .future:   return Color.primary.opacity(0.04)
        }
    }

    private var icon: String {
        switch status {
        case .prayed:   return "checkmark"
        case .missed:   return "xmark"
        case .upcoming: return "clock"
        case .future:   return "minus"
        }
    }

    private var iconColor: Color {
        switch status {
        case .prayed:   return Color(hex: "#0D9488")
        case .missed:   return Color(hex: "#DC2626")
        case .upcoming: return Color(hex: "#F59E0B")
        case .future:   return Color.primary.opacity(0.2)
        }
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
                .foregroundStyle(isToday ? Color(hex: "#0D9488") : .primary)
                .frame(width: 26, height: 26)
                .background {
                    if isToday {
                        Circle().stroke(Color(hex: "#0D9488"), lineWidth: 1.5)
                    }
                }
        }
        .frame(width: 44)
    }
}

// MARK: - Tracker View

struct TrackerView: View {
    @State private var viewMode: TrackerMode = .week

    enum TrackerMode: String, CaseIterable {
        case week = "Week"
        case month = "Month"
    }

    private let prayers: [Prayer] = [.fajr, .dhuhr, .asr, .maghrib, .isha]

    private let columns: [TrackerDayColumn] = [
        TrackerDayColumn(day: "MON", date: 12, isToday: false, cells: [.prayed, .prayed, .prayed, .prayed, .prayed]),
        TrackerDayColumn(day: "TUE", date: 13, isToday: false, cells: [.prayed, .prayed, .missed, .prayed, .prayed]),
        TrackerDayColumn(day: "WED", date: 14, isToday: false, cells: [.prayed, .prayed, .prayed, .missed, .prayed]),
        TrackerDayColumn(day: "THU", date: 15, isToday: false, cells: [.prayed, .missed, .prayed, .prayed, .prayed]),
        TrackerDayColumn(day: "FRI", date: 16, isToday: false, cells: [.prayed, .prayed, .prayed, .prayed, .prayed]),
        TrackerDayColumn(day: "SAT", date: 17, isToday: false, cells: [.prayed, .prayed, .prayed, .prayed, .missed]),
        TrackerDayColumn(day: "SUN", date: 18, isToday: true,  cells: [.prayed, .prayed, .upcoming, .upcoming, .upcoming]),
    ]

    var body: some View {
        VStack(spacing: 0) {
            topBar
            Divider().opacity(0.4)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    weekSummaryCards
                    if viewMode == .week {
                        trackerGrid
                    } else {
                        monthlyGrid
                        prayerCompletionBars
                    }
                }
                .padding(24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Top bar
    private var topBar: some View {
        HStack {
            HStack(spacing: 4) {
                Button { } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(7)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .buttonStyle(.plain)

                Text("12 – 18 Jun 2026")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(minWidth: 140)

                Button { } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(7)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .buttonStyle(.plain)
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
                            .background(viewMode == mode ? Color(hex: "#0D9488") : Color.clear,
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
    private var monthlyColumns: [TrackerDayColumn] {
        (1...30).map { day in
            let isPast   = day < 18
            let isToday  = day == 18
            let statuses: [TrackerStatus] = isPast
                ? [.prayed, day % 5 == 0 ? .missed : .prayed, day % 4 == 0 ? .missed : .prayed,
                   day % 7 == 0 ? .missed : .prayed, day % 3 == 0 ? .missed : .prayed]
                : isToday
                    ? [.prayed, .prayed, .upcoming, .upcoming, .upcoming]
                    : [.future, .future, .future, .future, .future]
            return TrackerDayColumn(day: "", date: day, isToday: isToday, cells: statuses)
        }
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
                                .foregroundStyle(col.isToday ? Color(hex: "#0D9488") : .secondary)
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
                                    TrackerCellTile(status: col.cells[index], isToday: col.isToday)
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

    // MARK: Per-prayer completion bars
    private var prayerCompletionBars: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Monthly Completion")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("June 2026")
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

    private let prayerCompletions: [(Prayer, Double)] = [
        (.fajr, 0.82), (.dhuhr, 0.94), (.asr, 0.76), (.maghrib, 0.88), (.isha, 0.65)
    ]

    // MARK: Summary cards
    private var weekSummaryCards: some View {
        HStack(spacing: 12) {
            SummaryCard(icon: "flame.fill",           iconColor: Color(hex: "#F59E0B"),
                        label: "Current Streak",       value: "12 days")
            SummaryCard(icon: "checkmark.circle.fill", iconColor: Color(hex: "#0D9488"),
                        label: "This Week",            value: "31/35")
            SummaryCard(icon: "percent",               iconColor: Color(hex: "#7C3AED"),
                        label: "Completion",           value: "88%")
            SummaryCard(icon: "star.fill",             iconColor: Color(hex: "#F59E0B"),
                        label: "Best Streak",          value: "21 days")
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
                        ForEach(columns) { col in
                            TrackerCellTile(
                                status: col.cells[index],
                                isToday: col.isToday
                            )
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
        percent >= 0.8 ? Color(hex: "#0D9488") :
        percent >= 0.5 ? Color(hex: "#F59E0B") : Color(hex: "#DC2626")
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
