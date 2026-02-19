enum ConnectorType: String, Codable, CaseIterable {
    case teslaNACS = "Tesla NACS"
    case j1772 = "J1772 (Type 1)"
    case ccs = "CCS"
    case chademo = "CHAdeMO"
    
    var icon: String {
        switch self {
        case .teslaNACS: return "bolt.fill"
        case .j1772: return "powerplug.fill"
        case .ccs: return "bolt.fill"
        case .chademo: return "powerplug.fill"
        }
    }
}

