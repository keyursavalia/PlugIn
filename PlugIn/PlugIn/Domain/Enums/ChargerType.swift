enum ChargerType: String, Codable, CaseIterable {
    case level1 = "Level 1"
    case level2 = "Level 2"
    case dcFast = "DC Fast Charge"
    
    var icon: String {
        switch self {
        case .level1: return "bolt.circle"
        case .level2: return "bolt.fill"
        case .dcFast: return "bolt.badge.a.fill"
        }
    }
}

