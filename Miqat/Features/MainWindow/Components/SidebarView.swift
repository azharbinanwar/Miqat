import SwiftUI

enum SidebarItem: String, CaseIterable {
    case today         = "Today"
    case monthly       = "Monthly"
    case tracker       = "Tracker"
    case stats         = "Stats"
    case notifications = "Notifications"
    case location      = "Location"
    case settings      = "Settings"

    var icon: String {
        switch self {
        case .today:         return "sun.max.fill"
        case .monthly:       return "calendar"
        case .tracker:       return "checkmark.circle.fill"
        case .stats:         return "chart.bar.fill"
        case .notifications: return "bell.fill"
        case .location:      return "location.fill"
        case .settings:      return "gearshape.fill"
        }
    }

    var section: SidebarSection {
        switch self {
        case .today, .monthly:              return .main
        case .tracker, .stats:              return .track
        case .notifications, .location, .settings: return .more
        }
    }
}

enum SidebarSection: String {
    case main  = "MAIN"
    case track = "TRACK"
    case more  = "MORE"
}

struct SidebarView: View {
    @Binding var selected: SidebarItem

    private let sections: [(SidebarSection, [SidebarItem])] = [
        (.main,  [.today, .monthly]),
        (.track, [.tracker, .stats]),
        (.more,  [.notifications, .location, .settings]),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            appBrand
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 16)

            Divider().opacity(0.4)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(sections, id: \.0.rawValue) { section, items in
                        sectionHeader(section.rawValue)
                        ForEach(items, id: \.self) { item in
                            SidebarRow(item: item, isSelected: selected == item)
                                .onTapGesture { withAnimation(.easeInOut(duration: 0.15)) { selected = item } }
                        }
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 12)
            }

            Spacer(minLength: 0)

            Divider().opacity(0.4)

            locationBar
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
        }
        .frame(width: 210)
        .background(Color(NSColor.windowBackgroundColor))
    }

    private var appBrand: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: "#0D9488"))
                    .frame(width: 36, height: 36)
                Image(systemName: "building.columns.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("Miqat")
                    .font(.system(size: 15, weight: .bold))
                Text("Prayer Times")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.tertiary)
            .tracking(1.2)
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 4)
    }

    private var locationBar: some View {
        HStack(spacing: 6) {
            Image(systemName: "location.fill")
                .font(.system(size: 11))
                .foregroundStyle(Color(hex: "#0D9488"))
            Text(LocationViewModel.shared.activeLocation?.city ?? "No location set")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }
}

struct SidebarRow: View {
    let item: SidebarItem
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: item.icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isSelected ? Color(hex: "#0D9488") : Color.secondary)
                .frame(width: 20, alignment: .center)

            Text(item.rawValue)
                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? Color.primary : Color.secondary)

            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color(hex: "#0D9488").opacity(0.15) : Color.clear)
        )
        .padding(.horizontal, 10)
        .contentShape(Rectangle())
    }
}
