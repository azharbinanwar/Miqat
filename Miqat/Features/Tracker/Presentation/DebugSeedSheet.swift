#if DEBUG
import SwiftUI

enum DebugSeedStatus: String, CaseIterable {
    case onTime  = "On Time"
    case jamaat  = "Jamaat"
    case kaza    = "Kaza"
    case missed  = "Missed"
    case random  = "Random"
    case mixed   = "Mixed"

    private static let cycle: [PrayerTrackerStatus] = [.prayedOnTime, .prayedWithJamaat, .prayedKaza, .prayedOnTime, .missed]
    private static let all:   [PrayerTrackerStatus] = PrayerTrackerStatus.allCases

    func resolve(index: Int, dayOffset: Int) -> PrayerTrackerStatus {
        switch self {
        case .onTime:  return .prayedOnTime
        case .jamaat:  return .prayedWithJamaat
        case .kaza:    return .prayedKaza
        case .missed:  return .missed
        case .random:  return Self.all.randomElement()!
        case .mixed:   return Self.cycle[(index + dayOffset) % Self.cycle.count]
        }
    }
}

struct DebugSeedSheet: View {
    @Environment(PrayerTrackerViewModel.self) private var trackerVM
    @Environment(\.dismiss) private var dismiss

    enum Action: String, CaseIterable { case insert = "Insert", delete = "Delete" }

    @State private var action: Action = .insert
    @State private var fromDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
    @State private var toDate   = Date()
    @State private var selectedPrayers: Set<Prayer> = Set(Prayer.allCases.filter(\.isPrayer))
    @State private var seedStatus: DebugSeedStatus  = .mixed
    @State private var isWorking   = false
    @State private var resultMsg   = ""

    private let prayers = Prayer.allCases.filter(\.isPrayer)

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header
            actionPicker
            dateRange
            prayerToggles
            if action == .insert { statusPicker }
            if !resultMsg.isEmpty { resultLabel }
            Spacer(minLength: 0)
            actionButton
            if action == .delete {
                deleteAllButton
            }
        }
        .padding(20)
        .frame(width: 400, height: action == .insert ? 420 : 360)
    }

    // MARK: – Subviews

    private var header: some View {
        HStack {
            Image(systemName: "ladybug.fill")
                .foregroundStyle(.orange)
            Text("Debug Seed")
                .font(.system(size: 16, weight: .bold))
            Spacer()
            Button("Done") { dismiss() }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
        }
    }

    private var actionPicker: some View {
        Picker("", selection: $action) {
            ForEach(Action.allCases, id: \.self) { Text($0.rawValue).tag($0) }
        }
        .pickerStyle(.segmented)
        .onChange(of: action) { _, _ in resultMsg = "" }
    }

    private var dateRange: some View {
        VStack(alignment: .leading, spacing: 8) {
            label("DATE RANGE")
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("From").font(.system(size: 11)).foregroundStyle(.secondary)
                    DatePicker("", selection: $fromDate, displayedComponents: .date)
                        .labelsHidden()
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("To").font(.system(size: 11)).foregroundStyle(.secondary)
                    DatePicker("", selection: $toDate, displayedComponents: .date)
                        .labelsHidden()
                }
            }
        }
    }

    private var prayerToggles: some View {
        VStack(alignment: .leading, spacing: 8) {
            label("PRAYERS")
            HStack(spacing: 8) {
                ForEach(prayers, id: \.self) { prayer in
                    let on = selectedPrayers.contains(prayer)
                    Button {
                        if on { selectedPrayers.remove(prayer) } else { selectedPrayers.insert(prayer) }
                    } label: {
                        Text(String(prayer.label.prefix(1)))
                            .font(.system(size: 13, weight: .bold))
                            .frame(width: 40, height: 36)
                            .background(on ? prayer.color : Color.secondary.opacity(0.12),
                                        in: RoundedRectangle(cornerRadius: 8))
                            .foregroundStyle(on ? .white : .secondary)
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
                Button("All") { selectedPrayers = Set(prayers) }
                    .buttonStyle(.plain).font(.system(size: 11)).foregroundStyle(AppColor.accentTeal)
                Button("None") { selectedPrayers.removeAll() }
                    .buttonStyle(.plain).font(.system(size: 11)).foregroundStyle(.secondary)
            }
        }
    }

    private var statusPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            label("STATUS")
            Picker("", selection: $seedStatus) {
                ForEach(DebugSeedStatus.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
        }
    }

    private var resultLabel: some View {
        Text(resultMsg)
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
            .padding(.vertical, 2)
    }

    private var actionButton: some View {
        Button {
            guard !isWorking else { return }
            isWorking = true
            resultMsg = ""
            let count: Int
            if action == .insert {
                count = trackerVM.debugInsert(from: fromDate, to: toDate,
                                              prayers: prayers.filter { selectedPrayers.contains($0) },
                                              status: seedStatus)
                resultMsg = "✅ \(count) records inserted"
            } else {
                count = trackerVM.debugDelete(from: fromDate, to: toDate)
                resultMsg = "🗑 \(count) records deleted"
            }
            isWorking = false
        } label: {
            Group {
                if isWorking {
                    ProgressView().scaleEffect(0.75)
                } else {
                    Text(action == .insert ? "Insert Records" : "Delete Range")
                        .font(.system(size: 14, weight: .semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(action == .insert ? AppColor.accentTeal : Color.red.opacity(0.75),
                        in: RoundedRectangle(cornerRadius: 10))
            .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
        .disabled(isWorking || selectedPrayers.isEmpty)
    }

    private var deleteAllButton: some View {
        Button("Delete ALL records") {
            trackerVM.debugDeleteAll()
            resultMsg = "🗑 All records deleted"
        }
        .buttonStyle(.plain)
        .font(.system(size: 12))
        .foregroundStyle(Color.red.opacity(0.7))
        .frame(maxWidth: .infinity)
    }

    private func label(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.tertiary)
            .tracking(1)
    }
}
#endif
