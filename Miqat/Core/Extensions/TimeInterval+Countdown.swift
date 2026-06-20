import Foundation

extension TimeInterval {
    /// Always formats as HH:MM:SS regardless of duration.
    static func formatCountdown(_ interval: TimeInterval) -> String {
        let total = max(0, Int(interval))
        let hrs  = total / 3600
        let mins = (total % 3600) / 60
        let secs = total % 60
        return String(format: "%02d:%02d:%02d", hrs, mins, secs)
    }
}
