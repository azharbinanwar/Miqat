import Foundation

extension Notification.Name {
    static let locationDidChange = Notification.Name("MiqatLocationDidChange")
}

final class LocationRepository {
    private let listKey     = Keys.Defaults.locations
    private let activeIdKey = Keys.Defaults.activeLocationId

    init() {}

    // MARK: - List

    func load() -> [Location] {
        guard
            let data = UserDefaults.standard.data(forKey: listKey),
            let locations = try? JSONDecoder().decode([Location].self, from: data)
        else { return [] }
        return locations
    }

    func save(_ locations: [Location]) {
        guard let data = try? JSONEncoder().encode(locations) else { return }
        UserDefaults.standard.set(data, forKey: listKey)
    }

    func add(_ location: Location) {
        var all = load()
        all.append(location)
        save(all)
    }

    func delete(id: UUID) {
        var all = load()
        all.removeAll { $0.id == id && !isPreset($0) }
        save(all)
    }

    func isPreset(_ location: Location) -> Bool {
        Location.presetLabels.contains(location.label)
    }

    // MARK: - Active ID (single source of truth)

    func getActiveId() -> UUID? {
        guard let str = UserDefaults.standard.string(forKey: activeIdKey) else { return nil }
        return UUID(uuidString: str)
    }

    func setActiveId(_ id: UUID) {
        UserDefaults.standard.set(id.uuidString, forKey: activeIdKey)
        NotificationCenter.default.post(name: .locationDidChange, object: nil)
    }

    func getActiveLocation() -> Location? {
        guard let id = getActiveId() else { return nil }
        return load().first { $0.id == id }
    }

    // MARK: - Seed

    func seedIfEmpty() {
        var all = load()
        let seeds: [Location] = [.makkah, .madinah, .karachi]

        // Insert missing seeds at front in correct order: Makkah, Madinah, Karachi
        for seed in seeds.reversed() {
            if !all.contains(where: { $0.label == seed.label }) {
                all.insert(seed, at: 0)
            }
        }
        // Re-sort so seeds always appear first in declared order
        let seedOrder = seeds.map { $0.label }
        all.sort {
            let li = seedOrder.firstIndex(of: $0.label) ?? Int.max
            let ri = seedOrder.firstIndex(of: $1.label) ?? Int.max
            return li < ri
        }
        save(all)

        // Set Makkah as default active if none set yet
        if getActiveId() == nil, let first = load().first {
            setActiveId(first.id)
        }
    }
}
