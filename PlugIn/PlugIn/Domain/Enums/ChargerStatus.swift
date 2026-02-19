import SwiftUI

enum ChargerStatus: String, Codable {
    case available = "available"
    case inUse = "in_use"
    case offline = "offline"
    
    var color: Color {
        switch self {
        case .available: return .green
        case .inUse: return .orange
        case .offline: return .gray
        }
    }
}

