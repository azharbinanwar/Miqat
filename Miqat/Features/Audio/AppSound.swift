import Foundation

enum AppSound: String, CaseIterable, Codable {
    case adhanOmarHisham  = "adhan_omar_hisham"
    case hayyaAlasSalah   = "hayya_alas_salah"
    case hayyaAlasFalah   = "hayya_alas_falah"
    case bellRing         = "bell_ring"
    case systemDefault    = "system_default"
    case custom           = "custom"

    var displayName: String {
        switch self {
        case .adhanOmarHisham: return "Adhan — Omar Hisham"
        case .hayyaAlasSalah:  return "Hayya Alas-Salah"
        case .hayyaAlasFalah:  return "Hayya Alas-Falah"
        case .bellRing:        return "Bell Ring"
        case .systemDefault:   return "System Default"
        case .custom:          return "Custom"
        }
    }

    var folder: String? {
        switch self {
        case .adhanOmarHisham, .hayyaAlasSalah, .hayyaAlasFalah:
            return "Adhan"
        case .bellRing:
            return "Notification"
        case .systemDefault, .custom:
            return nil
        }
    }

    var filename: String? {
        guard self != .systemDefault else { return nil }
        return rawValue
    }

    var isAdhan: Bool {
        folder == "Adhan"
    }
}
