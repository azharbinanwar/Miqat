import SwiftUI

// MARK: - Data models

struct DailyBar: Identifiable {
    let id    = UUID()
    let day   : String
    let completed: Int
    let total : Int
    var isToday: Bool = false
    var percent: Double { total > 0 ? Double(completed) / Double(total) : 0 }
}

struct PrayerStat: Identifiable {
    let id       = UUID()
    let prayer   : Prayer
    let completed: Int
    let total    : Int
    var percent  : Double { total > 0 ? Double(completed) / Double(total) : 0 }
}

// MARK: - Generic tiles (reusable)

struct DailyCompletionChart: View {
    let bars: [DailyBar]
    private let maxValue   : Int    = 5
    private let chartHeight: CGFloat = 110
    private let gridLines          = [0, 1, 2, 3, 4, 5]

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            VStack(spacing: 0) {
                ForEach(gridLines.reversed(), id: \.self) { n in
                    Text("\(n)")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.quaternary)
                        .frame(height: chartHeight / CGFloat(maxValue))
                }
            }
            .frame(width: 10)
            .offset(y: -6)

            GeometryReader { geo in
                let barWidth = max(3, (geo.size.width - CGFloat(max(bars.count - 1, 1)) * 6) / CGFloat(max(bars.count, 1)))
                let stepH    = chartHeight / CGFloat(maxValue)

                ZStack(alignment: .bottomLeading) {
                    ForEach(gridLines, id: \.self) { n in
                        Rectangle()
                            .fill(Color.primary.opacity(n == 0 ? 0.12 : 0.05))
                            .frame(height: n == 0 ? 1 : 0.5)
                            .offset(y: -(CGFloat(n) * stepH))
                    }
                    HStack(alignment: .bottom, spacing: 6) {
                        ForEach(bars) { bar in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(LinearGradient(colors: [barColor(bar).opacity(0.7), barColor(bar)],
                                                     startPoint: .top, endPoint: .bottom))
                                .frame(width: barWidth, height: max(4, stepH * CGFloat(bar.completed)))
                                .overlay(alignment: .top) {
                                    if bar.isToday {
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(Color.white.opacity(0.4), lineWidth: 1.5)
                                    }
                                }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                }
                .frame(height: chartHeight)
            }
            .frame(height: chartHeight)
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .padding(.bottom, 2)

        HStack(spacing: 0) {
            Spacer().frame(width: 20)
            HStack(spacing: 0) {
                ForEach(bars) { bar in
                    VStack(spacing: 3) {
                        if bar.isToday {
                            Text(bar.day)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 20, height: 20)
                                .background(AppColor.accentTeal, in: Circle())
                        } else {
                            Text(bar.day)
                                .font(.system(size: 9))
                                .foregroundStyle(.quaternary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private func barColor(_ bar: DailyBar) -> Color {
        bar.percent >= 1.0 ? AppColor.accentTeal :
        bar.percent >= 0.6 ? AppColor.accentGold : AppColor.alert
    }
}

struct PrayerStatRow: View {
    let stat: PrayerStat

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: stat.prayer.icon)
                .font(.system(size: 14))
                .foregroundStyle(stat.prayer.color)
                .frame(width: 20)

            Text(stat.prayer.rawValue)
                .font(.system(size: 13, weight: .medium))
                .frame(width: 65, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(Color.primary.opacity(0.06)).frame(height: 7)
                    RoundedRectangle(cornerRadius: 4).fill(barColor).frame(width: geo.size.width * stat.percent, height: 7)
                }
                .frame(maxHeight: .infinity)
            }
            .frame(height: 7)

            Text("\(Int(stat.percent * 100))%")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(barColor)
                .frame(width: 36, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var barColor: Color {
        stat.percent >= 0.8 ? AppColor.accentTeal :
        stat.percent >= 0.5 ? AppColor.accentGold : AppColor.alert
    }
}

// MARK: - Stats View

struct StatsView: View {
    @Environment(PrayerTrackerViewModel.self) private var trackerVM
    @State private var period: StatPeriod = .week

    enum StatPeriod: String, CaseIterable {
        case week = "Week", month = "Month", year = "Year"
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            Divider().opacity(0.4)
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    summaryRow
                    dailyChartCard
                    prayerBreakdownCard
                }
                .padding(24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Top bar
    private var topBar: some View {
        HStack {
            Text("Overview").font(.system(size: 16, weight: .bold))
            Spacer()
            HStack(spacing: 0) {
                ForEach(StatPeriod.allCases, id: \.self) { p in
                    Button { withAnimation(.spring(duration: 0.2)) { period = p } } label: {
                        Text(p.rawValue)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(period == p ? .white : .secondary)
                            .padding(.horizontal, 14).padding(.vertical, 6)
                            .background(period == p ? AppColor.accentTeal : Color.clear,
                                        in: RoundedRectangle(cornerRadius: 7))
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(Color(NSColor.controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.08), lineWidth: 1))
        }
        .padding(.horizontal, 24).padding(.vertical, 14)
    }

    // MARK: Summary cards
    private var summaryRow: some View {
        let current  = trackerVM.getCurrentStreak()
        let maxS     = trackerVM.getMaxStreak()
        let prayed   = periodPrayed
        let total    = periodTotalPossible
        let pct      = total > 0 ? Int(Double(prayed) / Double(total) * 100) : 0

        return HStack(spacing: 12) {
            InfoCard(icon: "percent",               iconColor: AppColor.accentPurple,
                        label: "Completion",           value: "\(pct)%")
            InfoCard(icon: "checkmark.circle.fill", iconColor: AppColor.accentTeal,
                        label: periodLabel,            value: "\(prayed)/\(total)")
            InfoCard(icon: "star.fill",             iconColor: AppColor.accentGold,
                        label: "Best Streak",          value: "\(maxS.days) days")
            InfoCard(icon: "flame.fill",            iconColor: AppColor.accentGold,
                        label: "Current Streak",       value: "\(current.days) days")
        }
    }

    private var periodPrayed: Int {
        periodRecords.values.flatMap { $0 }
            .filter { $0.prayer.isPrayer && $0.status.keepsStreak }.count
    }

    private var periodTotalPossible: Int {
        let cal   = Calendar.current
        let today = cal.startOfDay(for: Date())
        switch period {
        case .week:  return 7 * 5
        case .month:
            let days = cal.range(of: .day, in: .month, for: today)?.count ?? 30
            return days * 5
        case .year:  return 365 * 5
        }
    }

    // MARK: Daily chart card
    private var dailyChartCard: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Daily Completion").font(.system(size: 13, weight: .semibold)).foregroundStyle(.secondary)
                Spacer()
                Text(rangeLabel).font(.system(size: 12)).foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16).padding(.top, 14).padding(.bottom, 16)

            Divider().padding(.horizontal, 16).opacity(0.4)

            DailyCompletionChart(bars: dailyBars)
                .padding(.top, 12).padding(.bottom, 12)
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.06), lineWidth: 1))
    }

    // MARK: Per-prayer breakdown
    private var prayerBreakdownCard: some View {
        let stats   = prayerStats
        let sorted  = stats.sorted { $0.percent < $1.percent }
        let weakest = sorted.first
        let second  = sorted.dropFirst().first
        // Only flag if weakest is at least 10% behind the next one — not just tied for last
        let showWarning = weakest.map { w in
            w.percent < 0.8 && (second.map { w.percent < $0.percent - 0.1 } ?? true)
        } ?? false

        return VStack(spacing: 0) {
            HStack {
                Text("Per Prayer").font(.system(size: 13, weight: .semibold)).foregroundStyle(.secondary)
                Spacer()
                if showWarning, let w = weakest {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 11)).foregroundStyle(AppColor.alert)
                        Text("\(w.prayer.rawValue) needs attention").font(.system(size: 11)).foregroundStyle(AppColor.alert)
                    }
                }
            }
            .padding(.horizontal, 16).padding(.top, 14).padding(.bottom, 4)

            Divider().padding(.horizontal, 16).opacity(0.4)

            VStack(spacing: 0) {
                ForEach(Array(stats.enumerated()), id: \.element.id) { index, stat in
                    PrayerStatRow(stat: stat)
                    if index < stats.count - 1 { Divider().padding(.leading, 115).opacity(0.3) }
                }
            }
            .padding(.bottom, 4)
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.06), lineWidth: 1))
    }

    // MARK: Data helpers

    private var periodRecords: [Date: [PrayerRecord]] {
        let cal   = Calendar.current
        let today = cal.startOfDay(for: Date())
        switch period {
        case .week:
            let start = cal.date(byAdding: .day, value: -6, to: today)!
            return trackerVM.rangeRecords(from: start, to: today.addingTimeInterval(86400))
        case .month:
            return trackerVM.monthRecords(for: Date())
        case .year:
            let start = cal.date(byAdding: .month, value: -11,
                to: cal.date(from: cal.dateComponents([.year, .month], from: today))!)!
            return trackerVM.rangeRecords(from: start, to: today.addingTimeInterval(86400))
        }
    }

    private var dailyBars: [DailyBar] {
        let cal     = Calendar.current
        let today   = cal.startOfDay(for: Date())
        let records = periodRecords

        if period == .year {
            // Monthly bars for year view — 12 bars
            let fmt = DateFormatter(); fmt.dateFormat = "MMM"
            return (0..<12).compactMap { offset in
                let monthStart = cal.date(byAdding: .month, value: offset - 11,
                    to: cal.date(from: cal.dateComponents([.year, .month], from: today))!)!
                guard let monthEnd = cal.date(byAdding: .month, value: 1, to: monthStart),
                      monthStart <= today else { return nil }
                let days = cal.dateComponents([.day], from: monthStart, to: min(monthEnd, today)).day ?? 1
                let recs = records.filter { $0.key >= monthStart && $0.key < monthEnd }
                let prayed = recs.values.flatMap { $0 }.filter { $0.prayer.isPrayer && $0.status.keepsStreak }.count
                let total  = days * 5
                let avg    = total > 0 ? min(5, prayed / max(days, 1)) : 0
                return DailyBar(day: fmt.string(from: monthStart), completed: avg, total: 5,
                                isToday: cal.isDate(monthStart, equalTo: today, toGranularity: .month))
            }
        }

        // Daily bars for week/month
        let fmt   = DateFormatter(); fmt.dateFormat = "d"
        let days  = period == .week ? 7 : 30
        let start = cal.date(byAdding: .day, value: -(days - 1), to: today)!
        return (0..<days).compactMap { offset in
            let day = cal.date(byAdding: .day, value: offset, to: start)!
            guard day <= today else { return nil }
            let recs   = records[day] ?? []
            let prayed = recs.filter { $0.prayer.isPrayer && $0.status.keepsStreak }.count
            return DailyBar(day: fmt.string(from: day), completed: prayed, total: 5, isToday: cal.isDateInToday(day))
        }
    }

    private var prayerStats: [PrayerStat] {
        let allRecs  = periodRecords.values.flatMap { $0 }
        let total    = periodTotalPossible / 5  // days in period
        return Prayer.allCases.filter(\.isPrayer).map { prayer in
            let prayed = allRecs.filter { $0.prayer == prayer && $0.status.keepsStreak }.count
            return PrayerStat(prayer: prayer, completed: prayed, total: total)
        }
    }

    private var periodLabel: String {
        switch period { case .week: "This Week"; case .month: "This Month"; case .year: "This Year" }
    }

    private var rangeLabel: String {
        let fmt = DateFormatter(); fmt.dateFormat = "d MMM"
        let cal = Calendar.current
        let today = Date()
        switch period {
        case .week:
            let start = cal.date(byAdding: .day, value: -6, to: today)!
            return "\(fmt.string(from: start)) – \(fmt.string(from: today))"
        case .month:
            let f = DateFormatter(); f.dateFormat = "MMMM yyyy"
            return f.string(from: today)
        case .year:
            let f = DateFormatter(); f.dateFormat = "yyyy"
            return f.string(from: today)
        }
    }
}
