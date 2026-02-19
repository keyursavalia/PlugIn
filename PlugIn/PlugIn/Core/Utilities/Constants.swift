import SwiftUI
import Combine
import MapKit

enum Constants {
    // MARK: - App Info
    enum App {
        static let name = "PlugIn"
        static let tagline = "Share chargers. Drive green."
        static let version = "1.0.0"
    }
    
    // MARK: - Colors
    enum Colors {
        static let primary = Color.blue
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        static let background = Color(.systemGroupedBackground)
    }
    
    // MARK: - Spacing
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }
    
    // MARK: - Dimensions
    enum Dimensions {
        static let buttonHeight: CGFloat = 56
        static let cornerRadius: CGFloat = 12
        static let iconSize: CGFloat = 24
        static let avatarSize: CGFloat = 40
    }
    
    // MARK: - Map
    enum Map {
        static let defaultCenter = CLLocationCoordinate2D(
            latitude: 37.7749,
            longitude: -122.4194
        )
        static let defaultSpan = MKCoordinateSpan(
            latitudeDelta: 0.05,
            longitudeDelta: 0.05
        )
        static let maxPinDisplayDistance: Double = 10000 // meters
    }
    
    // MARK: - Pricing
    enum Pricing {
        static let defaultPricePerHour: Double = 3.00
        static let defaultCreditsPerHour: Int = 3
        static let minPricePerHour: Double = 0.50
        static let maxPricePerHour: Double = 20.00
    }
    
    // MARK: - API
    enum API {
        static let timeout: TimeInterval = 30
        static let maxRetries = 3
    }
    
    // MARK: - Validation
    enum Validation {
        static let minPasswordLength = 6
        static let maxChargerDistance: Double = 50 // miles
    }
}

