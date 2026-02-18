import Foundation

enum BuildEnvironment {
    case development
    case production
    
    static var current: BuildEnvironment {
        #if DEBUG
        return .development
        #else
        return .production
        #endif
    }
}

struct Config {
    static let environment = BuildEnvironment.current
    
    static var isDebug: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    static var enableLogging: Bool {
        environment != .production
    }
}

