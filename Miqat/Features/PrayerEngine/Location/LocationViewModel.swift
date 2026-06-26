import SwiftUI
import CoreLocation
import Combine

@Observable
final class LocationViewModel {
    static let shared = LocationViewModel()

    // MARK: - GPS lifecycle state
    enum FetchState { case idle, requesting, fetching, done, denied, failed }
    var fetchState : FetchState = .idle
    var gpsStatus  : String     = ""

    // MARK: - Location data
    var locations        : [Location]   = []
    var activeLocationId : UUID?        = nil
    var searchResults    : [CityResult] = []
    var isSearching      : Bool         = false
    var searchQuery      : String       = "" {
        didSet {
            guard oldValue != searchQuery else { return }
            searchQuery.isEmpty ? clearSearch() : performSearch()
        }
    }

    private let repo: LocationRepository
    private let lm: LocationManager
    private let search: CitySearchService
    private var bag = Set<AnyCancellable>()
    private var coordCancellable : AnyCancellable?
    private var fetchTask        : Task<Void, Never>?

    private init(repo: LocationRepository = ServiceLocator.shared.resolve(LocationRepository.self),
                 lm: LocationManager       = ServiceLocator.shared.resolve(LocationManager.self),
                 search: CitySearchService = ServiceLocator.shared.resolve(CitySearchService.self)) {
        self.repo = repo
        self.lm = lm
        self.search = search
        repo.seedIfEmpty()
        locations        = repo.load()
        activeLocationId = repo.getActiveId() ?? locations.first?.id

        lm.$authStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.handleAuthChange($0) }
            .store(in: &bag)

        lm.$cityName
            .receive(on: DispatchQueue.main)
            .filter { !$0.isEmpty }
            .sink { [weak self] city in
                guard let self else { return }
                gpsStatus = city
                if let idx = locations.firstIndex(where: { $0.icon == "location.fill" }) {
                    locations[idx].city = city
                    repo.save(locations)
                }
            }
            .store(in: &bag)

        search.$results
            .receive(on: DispatchQueue.main)
            .sink { [weak self] results in
                self?.searchResults = results
                self?.isSearching   = false
            }
            .store(in: &bag)
    }

    // MARK: - GPS Entry Point

    func startGPS() {
        guard fetchState != .fetching else { return }
        gpsStatus = ""
        if lm.isDenied {
            fetchState = .denied
        } else if lm.isAuthorized {
            beginFetch()
        } else {
            fetchState = .requesting
            lm.requestPermission()
        }
    }

    private func handleAuthChange(_ status: CLAuthorizationStatus) {
        switch status {
        case .denied, .restricted:
            stopFetchWork()
            if fetchState != .denied { fetchState = .denied }
        case .authorized, .authorizedAlways:
            if fetchState == .requesting || fetchState == .denied { beginFetch() }
        default:
            break
        }
    }

    private func beginFetch() {
        fetchState = .fetching
        gpsStatus  = "Detecting..."

        if let old = locations.first(where: { $0.icon == "location.fill" }) {
            repo.delete(id: old.id)
            locations = repo.load()
        }

        lm.requestLocation()

        coordCancellable = lm.$coordinate
            .compactMap { $0 }
            .first()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] coord in self?.handleCoordinate(coord) }

        fetchTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(30))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard let self, self.fetchState == .fetching else { return }
                self.stopFetchWork()
                self.fetchState = .failed
            }
        }
    }

    private func handleCoordinate(_ coord: CLLocationCoordinate2D) {
        fetchTask?.cancel()
        fetchTask        = nil
        coordCancellable = nil
        lm.stopUpdatesOnly()

        guard (-90...90).contains(coord.latitude), (-180...180).contains(coord.longitude) else {
            gpsStatus  = "Invalid coordinates"
            fetchState = .failed
            return
        }

        let city = lm.cityName.isEmpty ? "Current Location" : lm.cityName
        let loc  = Location(label: "GPS", icon: "location.fill",
                            city: city,
                            latitude: coord.latitude, longitude: coord.longitude)
        repo.add(loc)
        repo.setActiveId(loc.id)
        locations        = repo.load()
        activeLocationId = loc.id
        gpsStatus        = city
        fetchState       = .done
    }

    private func stopFetchWork() {
        fetchTask?.cancel()
        fetchTask        = nil
        coordCancellable = nil
        lm.cancelAll()
        if !gpsStatus.isEmpty { gpsStatus = "" }
    }

    func cancelFetch() {
        stopFetchWork()
        if fetchState != .idle { fetchState = .idle }
    }

    func retryGPS() {
        fetchState = .idle
        startGPS()
    }

    // MARK: - Search

    func addFromSearch(_ result: CityResult, label: String = "") {
        let name = label.isEmpty ? result.name : label
        // If city already exists in list, just set it active — no duplicate
        if let existing = locations.first(where: { $0.label == name }) {
            repo.setActiveId(existing.id)
            activeLocationId = existing.id
            clearSearch()
            return
        }
        let loc = Location(
            label: name,
            icon:  "mappin.circle.fill",
            city:  result.city,
            latitude:  result.coordinate.latitude,
            longitude: result.coordinate.longitude,
            timezone:  result.timezone
        )
        repo.add(loc)
        repo.setActiveId(loc.id)
        locations        = repo.load()
        activeLocationId = loc.id
        clearSearch()
    }

    func performSearch() {
        guard !searchQuery.isEmpty else { searchResults = []; return }
        isSearching = true
        search.search(query: searchQuery)
    }

    func clearSearch() {
        searchQuery   = ""
        searchResults = []
        search.clear()
    }

    // MARK: - Location Management

    func setActive(_ location: Location) {
        repo.setActiveId(location.id)
        activeLocationId = location.id
    }

    func delete(_ location: Location) {
        guard !repo.isPreset(location) else { return }
        if activeLocationId == location.id {
            activeLocationId = locations.first(where: { $0.id != location.id })?.id
            if let id = activeLocationId { repo.setActiveId(id) }
        }
        repo.delete(id: location.id)
        locations = repo.load()
    }

    // MARK: - Derived

    var seedLocations    : [Location]              { locations.filter { repo.isPreset($0) } }
    var userLocations    : [Location]              { locations.filter { !repo.isPreset($0) } }
    var activeLocation   : Location?               { locations.first { $0.id == activeLocationId } ?? locations.first }
    var activeCoordinate : CLLocationCoordinate2D? { activeLocation?.coordinate }
    var activeCityName   : String                  { activeLocation?.city ?? "" }
}
