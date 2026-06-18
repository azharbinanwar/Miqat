import CoreLocation
import Combine

struct CityResult: Identifiable {
    let id         = UUID()
    let name       : String
    let city       : String
    let coordinate : CLLocationCoordinate2D
}

final class CitySearchService: ObservableObject {
    @Published var results    : [CityResult] = []
    @Published var isSearching = false

    private var allCities    : [CityEntry]  = []
    private var loaded        = false
    private var debounceTask  : Task<Void, Never>?

    private struct CityEntry {
        let name      : String
        let nameLower : String
        let lat       : Double
        let lng       : Double
        let country   : String
    }

    func search(query: String) {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { results = []; isSearching = false; return }
        isSearching = true
        debounceTask?.cancel()
        debounceTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled else { return }
            await self?.run(query: q)
        }
    }

    func clear() {
        debounceTask?.cancel()
        results     = []
        isSearching = false
    }

    @MainActor
    private func run(query: String) async {
        if !loaded { await load() }
        let q = query.lowercased()
        let matches = allCities
            .filter { $0.nameLower.hasPrefix(q) }
            .prefix(20)
            .map { e -> CityResult in
                let country = Self.countries[e.country] ?? e.country
                return CityResult(
                    name: e.name,
                    city: "\(e.name), \(country)",
                    coordinate: CLLocationCoordinate2D(latitude: e.lat, longitude: e.lng)
                )
            }
        results     = Array(matches)
        isSearching = false
    }

    private func load() async {
        loaded = true
        guard let url = Bundle.main.url(forResource: "cities", withExtension: "txt"),
              let raw = try? String(contentsOf: url, encoding: .utf8) else { return }
        allCities = raw
            .split(separator: "\n", omittingEmptySubsequences: true)
            .compactMap { line -> CityEntry? in
                let p = line.split(separator: "\t", omittingEmptySubsequences: false)
                guard p.count >= 4, let lat = Double(p[1]), let lng = Double(p[2]) else { return nil }
                let name = String(p[0])
                return CityEntry(name: name, nameLower: name.lowercased(),
                                 lat: lat, lng: lng, country: String(p[3]))
            }
    }

    private static let countries: [String: String] = [
        "PK": "Pakistan",      "IN": "India",          "SA": "Saudi Arabia",
        "AE": "UAE",           "US": "United States",  "GB": "United Kingdom",
        "TR": "Turkey",        "EG": "Egypt",          "ID": "Indonesia",
        "MY": "Malaysia",      "BD": "Bangladesh",     "NG": "Nigeria",
        "IR": "Iran",          "IQ": "Iraq",           "MA": "Morocco",
        "DZ": "Algeria",       "TN": "Tunisia",        "LY": "Libya",
        "SD": "Sudan",         "AF": "Afghanistan",    "PH": "Philippines",
        "DE": "Germany",       "FR": "France",         "IT": "Italy",
        "ES": "Spain",         "CA": "Canada",         "AU": "Australia",
        "CN": "China",         "JP": "Japan",          "RU": "Russia",
        "BR": "Brazil",        "ZA": "South Africa",   "KE": "Kenya",
        "UZ": "Uzbekistan",    "KZ": "Kazakhstan",     "SY": "Syria",
        "JO": "Jordan",        "LB": "Lebanon",        "KW": "Kuwait",
        "QA": "Qatar",         "BH": "Bahrain",        "OM": "Oman",
        "YE": "Yemen",         "PS": "Palestine",      "NL": "Netherlands",
        "SE": "Sweden",        "NO": "Norway",         "NP": "Nepal",
        "LK": "Sri Lanka",     "TH": "Thailand",       "SG": "Singapore",
        "SO": "Somalia",       "ET": "Ethiopia",       "MX": "Mexico",
    ]
}
