import SwiftUI

struct FloatingPanelContextMenu: View {
    @Environment(SettingsViewModel.self) private var settingsVM
    var activePeriod: Prayer = .isha
    var onOpenSettings: () -> Void = {}
    @State private var locationVM = LocationViewModel.shared
    @State private var showLocations = false

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().opacity(0.15)
            modeRow
            Divider().padding(.leading, 44).opacity(0.1)
            madhabRow
            Divider().opacity(0.15)
            locationRow
            Divider().opacity(0.15)
            settingsRow
        }
        .frame(width: 290)
        .background(LinearGradient(colors: activePeriod.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.08), lineWidth: 1))
        .animation(.spring(duration: 0.22), value: showLocations)
        .animation(.spring(duration: 0.22), value: settingsVM.settings.floatingPanelMode)
    }

    // MARK: Header

    private var header: some View {
        HStack {
            Text("Panel")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
            Spacer()
            Text(settingsVM.settings.floatingPanelMode.rawValue)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.4))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }

    // MARK: Mode + Size (sub-row when not Off)

    private var modeRow: some View {
        VStack(spacing: 0) {
            menuRow(icon: "square.on.square", label: "Mode") {
                chipPicker(
                    FloatingPanelMode.allCases,
                    selected: settingsVM.settings.floatingPanelMode,
                    label: { $0.rawValue }
                ) { mode in settingsVM.update { $0.floatingPanelMode = mode } }
            }
            if settingsVM.settings.floatingPanelMode != .off {
                menuRow(icon: "macwindow", label: "Size") {
                    chipPicker(
                        FloatingPanelSize.allCases,
                        selected: settingsVM.settings.floatingPanelSize,
                        label: { $0.shortLabel }
                    ) { size in settingsVM.update { $0.floatingPanelSize = size } }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: Madhab

    private var madhabRow: some View {
        menuRow(icon: "person.fill", label: "Madhab") {
            chipPicker(
                [Madhab.hanafi, .shafi],
                selected: settingsVM.settings.madhab,
                label: { $0.rawValue }
            ) { madhab in settingsVM.update { $0.madhab = madhab } }
        }
    }

    // MARK: Location

    private var locationRow: some View {
        VStack(spacing: 0) {
            menuRow(icon: "location.fill", label: "Location") {
                Button {
                    withAnimation(.spring(duration: 0.2)) { showLocations.toggle() }
                } label: {
                    HStack(spacing: 4) {
                        Text(locationVM.activeCityName)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                            .lineLimit(1)
                        Image(systemName: showLocations ? "chevron.up" : "chevron.down")
                            .font(.system(size: 9))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }
            if showLocations {
                locationDropdown
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var locationDropdown: some View {
        VStack(spacing: 0) {
            ForEach(Array(locationVM.locations.enumerated()), id: \.element.id) { index, loc in
                let isActive = locationVM.activeLocationId == loc.id
                Button {
                    withAnimation(.spring(duration: 0.18)) {
                        locationVM.setActive(loc)
                        showLocations = false
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: isActive ? "location.fill" : "location")
                            .font(.system(size: 11))
                            .foregroundStyle(isActive ? AppColor.accentTeal : .white.opacity(0.5))
                            .frame(width: 16)
                        Text(loc.city)
                            .font(.system(size: 12, weight: isActive ? .semibold : .regular))
                            .foregroundStyle(isActive ? .white : .white.opacity(0.65))
                        Spacer()
                        if isActive {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(AppColor.accentTeal)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 9)
                    .background(isActive ? Color.white.opacity(0.08) : Color.clear)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                if index < locationVM.locations.count - 1 {
                    Divider().padding(.leading, 36).opacity(0.1)
                }
            }
        }
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
    }

    // MARK: Settings

    private var settingsRow: some View {
        Button(action: onOpenSettings) {
            HStack(spacing: 12) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(width: 28)
                Text("Open Settings")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.85))
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.3))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: Generic helpers

    private func menuRow<Content: View>(icon: String, label: String, @ViewBuilder trailing: () -> Content) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.55))
                .frame(width: 28)
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.75))
            Spacer()
            trailing()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func chipPicker<T: Hashable>(
        _ cases: [T],
        selected: T,
        label: @escaping (T) -> String,
        onSelect: @escaping (T) -> Void
    ) -> some View {
        HStack(spacing: 0) {
            ForEach(cases, id: \.self) { item in
                Button {
                    withAnimation(.spring(duration: 0.18)) { onSelect(item) }
                } label: {
                    Text(label(item))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(selected == item ? .white : .white.opacity(0.45))
                        .padding(.horizontal, 8)
                        .frame(height: 26)
                        .background(
                            selected == item ? AppColor.accentTeal : Color.clear,
                            in: RoundedRectangle(cornerRadius: 6)
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Right-click detector (kept for potential reuse)

struct RightClickDetector: NSViewRepresentable {
    let onRightClick: () -> Void

    func makeNSView(context: Context) -> RightClickView { RightClickView(onRightClick: onRightClick) }
    func updateNSView(_ nsView: RightClickView, context: Context) { nsView.onRightClick = onRightClick }

    class RightClickView: NSView {
        var onRightClick: () -> Void
        init(onRightClick: @escaping () -> Void) { self.onRightClick = onRightClick; super.init(frame: .zero) }
        required init?(coder: NSCoder) { fatalError() }
        override func rightMouseDown(with event: NSEvent) { onRightClick() }
    }
}
