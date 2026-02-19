import Foundation

struct ValidationHelper {
    static func validateEmail(_ email: String) -> Bool {
        email.trimmed.isValidEmail
    }
    
    static func validatePassword(_ password: String) -> (isValid: Bool, message: String?) {
        let trimmed = password.trimmed
        
        if trimmed.isEmpty {
            return (false, "Password is required")
        }
        
        if trimmed.count < Constants.Validation.minPasswordLength {
            return (false, "Password must be at least \(Constants.Validation.minPasswordLength) characters")
        }
        
        return (true, nil)
    }
    
    static func validatePrice(_ price: String) -> (isValid: Bool, value: Double?) {
        guard let value = Double(price) else {
            return (false, nil)
        }
        
        if value < Constants.Pricing.minPricePerHour {
            return (false, nil)
        }
        
        if value > Constants.Pricing.maxPricePerHour {
            return (false, nil)
        }
        
        return (true, value)
    }
    
    static func validateAddress(_ address: String) -> Bool {
        !address.trimmed.isEmpty && address.trimmed.count >= 5
    }
}
