import SwiftUI

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
                .foregroundStyle(Color(hex: "#0D9488"))
                .frame(width: 40, height: 40)
                .background(Color(hex: "#0D9488").opacity(0.1), in: RoundedRectangle(cornerRadius: 10))

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
                        .strokeBorder(isActive ? Color(hex: "#0D9488") : Color.secondary.opacity(0.25), lineWidth: 1.5)
                        .frame(width: 20, height: 20)
                    if isActive {
                        Circle()
                            .fill(Color(hex: "#0D9488"))
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
        .background(isActive ? Color(hex: "#0D9488").opacity(0.05) : Color.clear)
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
                        iconColor: Color(hex: "#0D9488"),
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
            HStack(spacing: 12) {
                Image(systemName: "location.circle")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: "#2563EB"))
                    .frame(width: 28, height: 28)
                    .background(Color(hex: "#2563EB").opacity(0.12), in: RoundedRectangle(cornerRadius: 7))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Use current location")
                        .font(.system(size: 13, weight: .medium))
                    Text(vm.gpsStatus.isEmpty ? "Detect via GPS" : vm.gpsStatus)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button { vm.startGPS() } label: {
                    Text("Detect")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color(hex: "#2563EB"))
                        .padding(.horizontal, 11)
                        .padding(.vertical, 6)
                        .background(Color(hex: "#2563EB").opacity(0.1), in: RoundedRectangle(cornerRadius: 7))
                        .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color(hex: "#2563EB").opacity(0.2), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider().padding(.leading, 58).opacity(0.3)

            // Add City tile
            Button { showDialog = true } label: {
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "#7C3AED"))
                        .frame(width: 28, height: 28)
                        .background(Color(hex: "#7C3AED").opacity(0.12), in: RoundedRectangle(cornerRadius: 7))
                    Text("Add City")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
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
}
