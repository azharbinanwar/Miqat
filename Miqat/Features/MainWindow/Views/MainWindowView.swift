import SwiftUI

struct MainWindowView: View {
    @State private var selectedItem: SidebarItem = .today
    @State private var isHanafi = true

    var body: some View {
        HStack(spacing: 0) {
            SidebarView(selected: $selectedItem)
            Divider()

            VStack(spacing: 0) {
                HeaderBar(isHanafi: $isHanafi)
                Divider()

                switch selectedItem {
                case .today:
                    TodayView(isHanafi: $isHanafi)
                case .monthly:
                    MonthlyView()
                default:
                    placeholderView(selectedItem.rawValue)
                }
            }
        }
        .frame(minWidth: 780, minHeight: 680)
    }

    private func placeholderView(_ title: String) -> some View {
        VStack {
            Spacer()
            Image(systemName: "building.columns.fill")
                .font(.system(size: 40))
                .foregroundStyle(.quaternary)
            Text(title)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.tertiary)
                .padding(.top, 8)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Header Bar

struct HeaderBar: View {
    @Binding var isHanafi: Bool

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(MockPrayerData.hijriDate)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                Text(MockPrayerData.fullDate)
                    .font(.system(size: 18, weight: .bold))
            }
            Spacer()

            HStack(spacing: 0) {
                madhhabButton("Hanafi", selected: isHanafi)  { isHanafi = true }
                madhhabButton("Shafi",  selected: !isHanafi) { isHanafi = false }
            }
            .background(Color(NSColor.controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.08), lineWidth: 1))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
    }

    private func madhhabButton(_ label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(selected ? .white : .secondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(selected ? Color(hex: "#0D9488") : Color.clear,
                            in: RoundedRectangle(cornerRadius: 7))
                .animation(.spring(duration: 0.2), value: selected)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MainWindowView()
        .preferredColorScheme(.dark)
}
