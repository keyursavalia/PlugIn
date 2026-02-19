import Foundation

struct FormattingHelper {
    static func formatDistance(_ distance: Double) -> String {
        if distance < 1 {
            return String(format: "%.1f ft", distance * 5280)
        } else {
            return String(format: "%.1f mi", distance)
        }
    }
    
    static func formatPower(_ kw: Double) -> String {
        return String(format: "%.1f kW", kw)
    }
    
    static func formatCredits(_ credits: Int) -> String {
        return "\(credits) credit" + (credits == 1 ? "" : "s")
    }
    
    static func formatRating(_ rating: Double) -> String {
        return String(format: "%.1f", rating)
    }
}
