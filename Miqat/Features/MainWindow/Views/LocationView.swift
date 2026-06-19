import SwiftUI
import AppKit

// MARK: - Location Row

struct LocationRow: View {
    let location  : Location
    let isActive  : Bool
    let onSelect  : () -> Void
    let onDelete  : (() -> Void)?   // nil = seed city, no delete

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: location.icon)
                .font(.system(size: 18))
                .foregroundStyle(AccentColor.current)
                .frame(width: 40, height: 40)
                .background(AccentColor.current.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 3) {
                Text(location.label)
                    .font(.system(size: 13, weight: .semibold))
                Text(location.city)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 10) {
                // Radio circle
                ZStack {
                    Circle()
                        .strokeBorder(isActive ? AccentColor.current : Color.secondary.opacity(0.25), lineWidth: 1.5)
                        .frame(width: 20, height: 20)
                    if isActive {
                        Circle()
                            .fill(AccentColor.current)
                            .frame(width: 12, height: 12)
                    }
                }

                if let onDelete {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.secondary.opacity(0.35))
                            .padding(6)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(isActive ? AccentColor.current.opacity(0.05) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture { if !isActive { onSelect() } }
    }
}

// MARK: - Location View

struct LocationView: View {
    @State private var vm         = LocationViewModel.shared
    @State private var showDialog = false

    var body: some View {
        VStack(spacing: 0) {
            topBar
            Divider().opacity(0.4)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    locationsCard(
                        title: "Default Cities",
                        icon: "building.columns.fill",
                        iconColor: AccentColor.current,
                        items: vm.seedLocations,
                        deleteable: false
                    )

                    if !vm.userLocations.isEmpty {
                        locationsCard(
                            title: "My Cities",
                            icon: "mappin.circle.fill",
                            iconColor: Color(hex: "#7C3AED"),
                            items: vm.userLocations,
                            deleteable: true
                        )
                    }

                    addCard
                }
                .padding(24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showDialog) {
            CitySearchDialog { result in
                vm.addFromSearch(result)
                showDialog = false
            }
        }
    }

    // MARK: Top bar

    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Location")
                    .font(.system(size: 16, weight: .bold))
                Text("Tap a city to use it for prayer times")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
    }

    // MARK: Locations card

    private func locationsCard(title: String, icon: String, iconColor: Color, items: [Location], deleteable: Bool) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundStyle(iconColor)
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 4)

            Divider().padding(.horizontal, 16).opacity(0.4)

            VStack(spacing: 0) {
                ForEach(items) { loc in
                    LocationRow(
                        location: loc,
                        isActive: vm.activeLocationId == loc.id,
                        onSelect: { withAnimation { vm.setActive(loc) } },
                        onDelete: deleteable ? { withAnimation { vm.delete(loc) } } : nil
                    )
                    if loc.id != items.last?.id {
                        Divider().padding(.leading, 70).opacity(0.3)
                    }
                }
            }
            .padding(.bottom, 4)
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.06), lineWidth: 1))
    }

    // MARK: Add card

    private var addCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: "#0D9488"))
                Text("Add a place")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 4)

            Divider().padding(.horizontal, 16).opacity(0.4)

            // GPS row
            HStack(spacing: 14) {
                Image(systemName: vm.fetchState == .fetching ? "location.fill" : "location.circle")
                    .font(.system(size: 16))
                    .foregroundStyle(AccentColor.current)
                    .frame(width: 36, height: 36)
                    .background(AccentColor.current.opacity(0.1), in: RoundedRectangle(cornerRadius: 9))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Use current location")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.primary)
                    Text(gpsStatusText)
                        .font(.system(size: 11))
                        .foregroundStyle(gpsStatusColor)
                }

                Spacer()

                if vm.fetchState == .fetching {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Button {
                        if vm.fetchState == .denied {
                            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices") {
                                NSWorkspace.shared.open(url)
                            }
                        } else {
                            vm.startGPS()
                        }
                    } label: {
                        Text(vm.fetchState == .denied ? "Open Settings" : vm.fetchState == .failed ? "Retry" : "Detect")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(vm.fetchState == .failed || vm.fetchState == .denied ? Color(hex: "#DC2626") : AccentColor.current)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(
                                (vm.fetchState == .failed || vm.fetchState == .denied ? Color(hex: "#DC2626") : AccentColor.current).opacity(0.1),
                                in: Capsule()
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider().padding(.leading, 66).opacity(0.3)

            // Add City row
            Button { showDialog = true } label: {
                HStack(spacing: 14) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16))
                        .foregroundStyle(AccentColor.current)
                        .frame(width: 36, height: 36)
                        .background(AccentColor.current.opacity(0.1), in: RoundedRectangle(cornerRadius: 9))

                    Text("Add City")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.primary)

                    Spacer()

                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AccentColor.current.opacity(0.5))
                        .frame(width: 28, height: 28)
                        .background(AccentColor.current.opacity(0.08), in: Circle())
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.bottom, 4)
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.06), lineWidth: 1))
    }

    private var gpsStatusText: String {
        if !vm.gpsStatus.isEmpty { return vm.gpsStatus }
        switch vm.fetchState {
        case .denied:     return "Permission denied"
        case .failed:     return "Detection failed — tap to retry"
        case .fetching:   return "Detecting…"
        case .requesting: return "Requesting permission…"
        case .done:       return "Location detected"
        default:          return "Detect via GPS"
        }
    }

    private var gpsStatusColor: Color {
        switch vm.fetchState {
        case .denied, .failed: return Color(hex: "#DC2626")
        case .done:            return Color(hex: "#0D9488")
        default:               return .secondary
        }
    }

}
