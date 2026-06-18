import SwiftUI

// MARK: - Data

struct DailyBar: Identifiable {
    let id = UUID()
    let day: String
    let completed: Int
    let total: Int
    var isToday: Bool = false
    var percent: Double { Double(completed) / Double(total) }
}

struct PrayerStat: Identifiable {
    let id = UUID()
    let prayer: Prayer
    let completed: Int
    let total: Int
    let streak: Int
    var percent: Double { Double(completed) / Double(total) }
}

// MARK: - Generic Tiles

// Full realistic chart — grid lines + Y-axis + coloured bars + today marker
struct DailyCompletionChart: View {
    let bars: [DailyBar]
    let maxValue: Int = 5
    private let chartHeight: CGFloat = 110
    private let gridLines = [0, 1, 2, 3, 4, 5]

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            // Y-axis labels
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

            // Chart area
            GeometryReader { geo in
                let barWidth = (geo.size.width - CGFloat(bars.count - 1) * 8) / CGFloat(bars.count)
                let stepH    = chartHeight / CGFloat(maxValue)

                ZStack(alignment: .bottomLeading) {
                    // Grid lines
                    ForEach(gridLines, id: \.self) { n in
                        Rectangle()
                            .fill(Color.primary.opacity(n == 0 ? 0.12 : 0.05))
                            .frame(height: n == 0 ? 1 : 0.5)
                            .offset(y: -(CGFloat(n) * stepH))
                    }

                    // Bars
                    HStack(alignment: .bottom, spacing: 8) {
                        ForEach(Array(bars.enumerated()), id: \.element.id) { _, bar in
                            VStack(spacing: 4) {
                                // Count label on top of bar
                                Text(bar.completed < bar.total ? "\(bar.completed)" : "")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(barColor(bar))
                                    .opacity(bar.completed < bar.total ? 1 : 0)

                                RoundedRectangle(cornerRadius: 5)
                                    .fill(
                                        LinearGradient(
                                            colors: [barColor(bar).opacity(0.7), barColor(bar)],
                                            startPoint: .top, endPoint: .bottom
                                        )
                                    )
                                    .frame(
                                        width: barWidth,
                                        height: max(4, stepH * CGFloat(bar.completed))
                                    )
                                    .overlay(alignment: .top) {
                                        if bar.isToday {
                                            RoundedRectangle(cornerRadius: 5)
                                                .stroke(Color.white.opacity(0.4), lineWidth: 1.5)
                                        }
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

        // X-axis day labels + today pill
        HStack(spacing: 0) {
            Spacer().frame(width: 20)    // Y-axis gutter
            HStack(spacing: 8) {
                ForEach(bars) { bar in
                    VStack(spacing: 3) {
                        if bar.isToday {
                            Text(bar.day)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 22, height: 22)
                                .background(Color(hex: "#0D9488"), in: Circle())
                        } else {
                            Text(bar.day)
                                .font(.system(size: 10))
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
        bar.percent >= 1.0 ? Color(hex: "#0D9488") :
        bar.percent >= 0.6 ? Color(hex: "#F59E0B") : Color(hex: "#DC2626")
    }
}

// One generic prayer stat row
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
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.primary.opacity(0.06))
                        .frame(height: 7)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(barColor)
                        .frame(width: geo.size.width * stat.percent, height: 7)
                }
                .frame(maxHeight: .infinity)
            }
            .frame(height: 7)

            Text("\(Int(stat.percent * 100))%")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(barColor)
                .frame(width: 36, alignment: .trailing)

            HStack(spacing: 3) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Color(hex: "#F59E0B"))
                Text("\(stat.streak)d")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .frame(width: 36, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var barColor: Color {
        stat.percent >= 0.8 ? Color(hex: "#0D9488") :
        stat.percent >= 0.5 ? Color(hex: "#F59E0B") : Color(hex: "#DC2626")
    }
}

// MARK: - Stats View

struct StatsView: View {
    @State private var period: StatPeriod = .week

    enum StatPeriod: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
    }

    private let summaryCards: [(String, String, String, Color)] = [
        ("flame.fill",            "12 days",  "Current Streak", Color(hex: "#F59E0B")),
        ("star.fill",             "21 days",  "Best Streak",    Color(hex: "#F59E0B")),
        ("checkmark.circle.fill", "31/35",    "This Week",      Color(hex: "#0D9488")),
        ("percent",               "88%",      "Completion",     Color(hex: "#7C3AED")),
    ]

    private let weekBars: [DailyBar] = [
        DailyBar(day: "5",  completed: 4, total: 5, isToday: false),
        DailyBar(day: "6",  completed: 5, total: 5, isToday: false),
        DailyBar(day: "7",  completed: 3, total: 5, isToday: false),
        DailyBar(day: "8",  completed: 5, total: 5, isToday: false),
        DailyBar(day: "9",  completed: 4, total: 5, isToday: false),
        DailyBar(day: "10", completed: 2, total: 5, isToday: false),
        DailyBar(day: "11", completed: 5, total: 5, isToday: false),
        DailyBar(day: "12", completed: 4, total: 5, isToday: false),
        DailyBar(day: "13", completed: 5, total: 5, isToday: false),
        DailyBar(day: "14", completed: 3, total: 5, isToday: false),
        DailyBar(day: "15", completed: 5, total: 5, isToday: false),
        DailyBar(day: "16", completed: 4, total: 5, isToday: false),
        DailyBar(day: "17", completed: 5, total: 5, isToday: false),
        DailyBar(day: "18", completed: 2, total: 5, isToday: true),
    ]

    private let prayerStats: [PrayerStat] = [
        PrayerStat(prayer: .fajr,    completed: 14, total: 17, streak: 4),
        PrayerStat(prayer: .dhuhr,   completed: 16, total: 17, streak: 12),
        PrayerStat(prayer: .asr,     completed: 13, total: 17, streak: 3),
        PrayerStat(prayer: .maghrib, completed: 15, total: 17, streak: 8),
        PrayerStat(prayer: .isha,    completed: 11, total: 17, streak: 2),
    ]

    var body: some View {
        VStack(spacing: 0) {
            topBar
            Divider().opacity(0.4)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Summary cards row
                    HStack(spacing: 12) {
                        ForEach(summaryCards, id: \.0) { icon, value, label, color in
                            SummaryCard(icon: icon, iconColor: color, label: label, value: value)
                        }
                    }

                    // Daily bar chart
                    dailyChartCard

                    // Per-prayer breakdown
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
            Text("Overview")
                .font(.system(size: 16, weight: .bold))

            Spacer()

            HStack(spacing: 0) {
                ForEach(StatPeriod.allCases, id: \.self) { p in
                    Button { withAnimation(.spring(duration: 0.2)) { period = p } } label: {
                        Text(p.rawValue)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(period == p ? .white : .secondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(period == p ? Color(hex: "#0D9488") : Color.clear,
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

    // MARK: Daily chart card
    private var dailyChartCard: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Daily Completion")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("12 – 18 Jun")
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 16)

            Divider().padding(.horizontal, 16).opacity(0.4)

            DailyCompletionChart(bars: weekBars)
                .padding(.top, 12)
                .padding(.bottom, 12)
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.06), lineWidth: 1))
    }

    // MARK: Per-prayer breakdown card
    private var prayerBreakdownCard: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Per Prayer")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(Color(hex: "#DC2626"))
                    Text("Isha needs attention")
                        .font(.system(size: 11))
                        .foregroundStyle(Color(hex: "#DC2626"))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 4)

            Divider().padding(.horizontal, 16).opacity(0.4)

            VStack(spacing: 0) {
                ForEach(Array(prayerStats.enumerated()), id: \.element.id) { index, stat in
                    PrayerStatRow(stat: stat)
                    if index < prayerStats.count - 1 {
                        Divider().padding(.leading, 115).opacity(0.3)
                    }
                }
            }
            .padding(.bottom, 4)
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.06), lineWidth: 1))
    }
}
