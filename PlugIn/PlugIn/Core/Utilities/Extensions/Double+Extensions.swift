import Foundation

extension Double {
    func toCurrency() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: self)) ?? "$0.00"
    }
    
    func toCredits() -> String {
        return String(format: "%.1f credits", self)
    }
}
