import Foundation

enum AppError: LocalizedError {
    case network
    case authentication
    case invalidData
    case notFound
    case unauthorized
    case custom(String)
    
    var errorDescription: String? {
        switch self {
        case .network:
            return "Network connection error. Please check your internet."
        case .authentication:
            return "Authentication failed. Please sign in again."
        case .invalidData:
            return "Invalid data received. Please try again."
        case .notFound:
            return "The requested resource was not found."
        case .unauthorized:
            return "You don't have permission to perform this action."
        case .custom(let message):
            return message
        }
    }
}
