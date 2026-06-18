import SwiftUI

// MARK: - Data

struct SavedLocation: Identifiable {
    let id = UUID()
    var label: String
    var city: String
    var country: String
    var coordinates: String
    var isActive: Bool
    var isStarred: Bool
    var icon: String
}

// MARK: - Generic Tiles

// One generic tile per saved location
struct LocationRow: View {
    let location: SavedLocation
    let onSelect: () -> Void
    let onStar: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            // Emoji + active indicator
            ZStack(alignment: .bottomTrailing) {
                Image(systemName: location.icon)
                    .font(.system(size: 18))
                    .foregroundStyle(Color(hex: "#0D9488"))
                    .frame(width: 40, height: 40)
                    .background(Color(hex: "#0D9488").opacity(0.1), in: RoundedRectangle(cornerRadius: 10))

                if location.isActive {
                    Circle()
                        .fill(Color(hex: "#0D9488"))
                        .frame(width: 10, height: 10)
                        .overlay(Circle().stroke(Color(NSColor.windowBackgroundColor), lineWidth: 1.5))
                        .offset(x: 3, y: 3)
                }
            }

            // Label + city
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(location.label)
                        .font(.system(size: 13, weight: .semibold))

                    if location.isActive {
                        Text("ACTIVE")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(hex: "#0D9488"), in: Capsule())
                    }
                }

                Text("\(location.city), \(location.country)")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)

                Text(location.coordinates)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Color.secondary.opacity(0.4))
            }

            Spacer()

            // Star + select buttons
            HStack(spacing: 8) {
                Button(action: onStar) {
                    Image(systemName: location.isStarred ? "star.fill" : "star")
                        .font(.system(size: 13))
                        .foregroundStyle(location.isStarred ? Color(hex: "#F59E0B") : Color.secondary.opacity(0.4))
                }
                .buttonStyle(.plain)
                .help("Pin as default")

                if !location.isActive {
                    Button(action: onSelect) {
                        Text("Use")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color(hex: "#0D9488"))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color(hex: "#0D9488").opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(hex: "#0D9488").opacity(0.2), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.secondary.opacity(0.5))
                        .padding(6)
                        .background(Color(hex: "#DC2626").opacity(0.0), in: RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .help("Remove location")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(location.isActive ? Color(hex: "#0D9488").opacity(0.05) : Color.clear)
    }
}

// MARK: - Location View

struct LocationView: View {
    @State private var locations: [SavedLocation] = [
        SavedLocation(label: "Home",   city: "London",    country: "UK", coordinates: "51.5074° N, 0.1278° W", isActive: true,  isStarred: true,  icon: "house.fill"),
        SavedLocation(label: "Office", city: "London",    country: "UK", coordinates: "51.5155° N, 0.0922° W", isActive: false, isStarred: true,  icon: "building.2.fill"),
        SavedLocation(label: "Hostel", city: "Manchester",country: "UK", coordinates: "53.4808° N, 2.2426° W", isActive: false, isStarred: false, icon: "bed.double.fill"),
        SavedLocation(label: "Masjid", city: "Birmingham",country: "UK", coordinates: "52.4862° N, 1.8904° W", isActive: false, isStarred: false, icon: "building.columns.fill"),
    ]

    @State private var showAddSheet  = false
    @State private var searchText    = ""
    @State private var newLabel      = ""

    private var starredLocations: [SavedLocation] { locations.filter(\.isStarred) }
    private var otherLocations:   [SavedLocation] { locations.filter { !$0.isStarred } }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            Divider().opacity(0.4)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    if !starredLocations.isEmpty {
                        locationsCard(title: "Pinned", icon: "star.fill", iconColor: Color(hex: "#F59E0B"), items: starredLocations)
                    }
                    if !otherLocations.isEmpty {
                        locationsCard(title: "Saved", icon: "mappin.circle.fill", iconColor: Color(hex: "#2563EB"), items: otherLocations)
                    }
                    addCard
                }
                .padding(24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showAddSheet) { addSheet }
    }

    // MARK: Top bar
    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Location")
                    .font(.system(size: 16, weight: .bold))
                Text("Switch between your saved places")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button { showAddSheet = true } label: {
                Label("Add Location", systemImage: "plus")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Color(hex: "#0D9488"), in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
    }

    // MARK: Generic location card
    private func locationsCard(title: String, icon: String, iconColor: Color, items: [SavedLocation]) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundStyle(iconColor)
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(items.count) saved")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.secondary.opacity(0.4))
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 4)

            Divider().padding(.horizontal, 16).opacity(0.4)

            VStack(spacing: 0) {
                ForEach(items) { loc in
                    LocationRow(
                        location: loc,
                        onSelect: { setActive(loc) },
                        onStar:   { toggleStar(loc) },
                        onDelete: { delete(loc) }
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

            HStack(spacing: 12) {
                Image(systemName: "location.circle")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: "#2563EB"))
                    .frame(width: 28, height: 28)
                    .background(Color(hex: "#2563EB").opacity(0.12), in: RoundedRectangle(cornerRadius: 7))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Use current location")
                        .font(.system(size: 13, weight: .medium))
                    Text("Detect via GPS")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button { } label: {
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

            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: "#7C3AED"))
                    .frame(width: 28, height: 28)
                    .background(Color(hex: "#7C3AED").opacity(0.12), in: RoundedRectangle(cornerRadius: 7))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Search a city")
                        .font(.system(size: 13, weight: .medium))
                    Text("Find by city name or coordinates")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button { showAddSheet = true } label: {
                    Text("Search")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color(hex: "#7C3AED"))
                        .padding(.horizontal, 11)
                        .padding(.vertical, 6)
                        .background(Color(hex: "#7C3AED").opacity(0.1), in: RoundedRectangle(cornerRadius: 7))
                        .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color(hex: "#7C3AED").opacity(0.2), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .padding(.bottom, 4)
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.06), lineWidth: 1))
    }

    // MARK: Add sheet
    private var addSheet: some View {
        VStack(spacing: 20) {
            Text("Add Location")
                .font(.system(size: 16, weight: .bold))

            TextField("Label (e.g. Home, Office)", text: $newLabel)
                .textFieldStyle(.roundedBorder)

            HStack {
                Button("Cancel") { showAddSheet = false }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Add") { showAddSheet = false }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(hex: "#0D9488"))
            }
        }
        .padding(24)
        .frame(width: 340)
    }

    // MARK: Actions
    private func setActive(_ loc: SavedLocation) {
        withAnimation(.spring(duration: 0.2)) {
            for i in locations.indices { locations[i].isActive = false }
            if let i = locations.firstIndex(where: { $0.id == loc.id }) { locations[i].isActive = true }
        }
    }

    private func toggleStar(_ loc: SavedLocation) {
        if let i = locations.firstIndex(where: { $0.id == loc.id }) {
            withAnimation(.spring(duration: 0.2)) { locations[i].isStarred.toggle() }
        }
    }

    private func delete(_ loc: SavedLocation) {
        withAnimation { locations.removeAll { $0.id == loc.id } }
    }
}
