import SwiftUI


enum AppColor {
    // MARK: - Prayer colors (sky-matched)
    static let fajr    = Color(hex: "#6366F1")  // dark indigo — pre-dawn
    static let sunrise = Color(hex: "#FB923C")  // warm orange — first light
    static let dhuhr   = Color(hex: "#38BDF8")  // bright sky blue — high noon
    static let asr     = Color(hex: "#F59E0B")  // golden amber — afternoon sun
    static let maghrib = Color(hex: "#F43F5E")  // deep rose-red — burning sunset
    static let isha    = Color(hex: "#312E81")  // near-black indigo — full night

    // MARK: - Gradient backgrounds
    static let deepNavy    = Color(hex: "#020617")  // near black
    static let darkNavy    = Color(hex: "#1E1B4B")  // deep indigo night
    static let purple      = Color(hex: "#4C1D95")
    static let burntOrange = Color(hex: "#7C2D12")  // deep red-brown
    static let deepTeal    = Color(hex: "#0C4A6E")  // deep sky blue
    static let deepRed     = Color(hex: "#881337")  // deep crimson sunset

    // MARK: - Accent picker options
    static let accentTeal   = Color(hex: "#0D9488")
    static let accentPurple = Color(hex: "#7C3AED")
    static let accentGold   = Color(hex: "#D97706")
    static let accentBlue   = Color(hex: "#2563EB")
    static let accentGreen  = Color(hex: "#16A34A")  // Friday / Jumu'ah

    // MARK: - Status
    static let alert    = Color(hex: "#DC2626")
    static let upcoming = Color(hex: "#6B7280")

    // MARK: - Soft (text on dark backgrounds)
    static let softRed   = Color(hex: "#FCA5A5")
    static let softAmber = Color(hex: "#FCD34D")
    static let softGreen = Color(hex: "#4ADE80")

    // MARK: - Misc (onboarding, one-off UI)
    static let skyCyan = Color(hex: "#0284C7")
    static let green   = Color(hex: "#14532D")
    static let brown   = Color(hex: "#78350F")

    // MARK: - Accent picker
    static let accentOptions: [(name: String, color: Color)] = [
        ("Teal",   accentTeal),
        ("Purple", accentPurple),
        ("Gold",   accentGold),
        ("Blue",   accentBlue),
    ]


}
