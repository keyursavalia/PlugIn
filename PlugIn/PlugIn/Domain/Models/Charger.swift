import Foundation
import FirebaseFirestore
import CoreLocation

struct DayAvailability: Codable, Hashable {
    let day: Int
    var startHour: Int
    var endHour: Int
    var isAvailable: Bool

    var dayName: String {
        let names = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        return names[day]
    }

    var shortDayName: String {
        let names = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return names[day]
    }

    static func defaultWeek() -> [DayAvailability] {
        (0...6).map { DayAvailability(day: $0, startHour: 8, endHour: 22, isAvailable: true) }
    }
}

struct Charger: Codable, Identifiable, Hashable {
    @DocumentID var id: String?
    let hostId: String
    var location: GeoPoint
    var address: String
    var type: ChargerType
    var connectorType: ConnectorType
    var pricePerHour: Double
    var creditsPerHour: Int
    var status: ChargerStatus
    var maxSpeed: Double
    var hasTetheredCable: Bool
    var accessInstructions: String?
    var currentBookingId: String?
    var rating: Double = 0.0
    var totalBookings: Int = 0
    var createdAt: Timestamp = Timestamp()
    var availabilitySchedule: [DayAvailability]?  // nil means 24/7

    // Computed for map
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: location.latitude,
            longitude: location.longitude
        )
    }

    /// Check if the charger is available at a given date/time based on its weekly schedule
    func isAvailable(at date: Date) -> Bool {
        guard let schedule = availabilitySchedule else { return true }
        let calendar = Calendar.current
        let weekday = (calendar.component(.weekday, from: date) - 1) // 1=Sun -> 0=Sun
        let hour = calendar.component(.hour, from: date)
        guard let daySchedule = schedule.first(where: { $0.day == weekday }) else { return true }
        return daySchedule.isAvailable && hour >= daySchedule.startHour && hour < daySchedule.endHour
    }

    init(id: String?, hostId: String, location: GeoPoint, address: String, type: ChargerType, connectorType: ConnectorType, pricePerHour: Double, creditsPerHour: Int, status: ChargerStatus, maxSpeed: Double, hasTetheredCable: Bool, accessInstructions: String?, currentBookingId: String?, rating: Double = 0.0, totalBookings: Int = 0, createdAt: Timestamp = Timestamp(), availabilitySchedule: [DayAvailability]? = nil) {
        self.id = id
        self.hostId = hostId
        self.location = location
        self.address = address
        self.type = type
        self.connectorType = connectorType
        self.pricePerHour = pricePerHour
        self.creditsPerHour = creditsPerHour
        self.status = status
        self.maxSpeed = maxSpeed
        self.hasTetheredCable = hasTetheredCable
        self.accessInstructions = accessInstructions
        self.currentBookingId = currentBookingId
        self.rating = rating
        self.totalBookings = totalBookings
        self.createdAt = createdAt
        self.availabilitySchedule = availabilitySchedule
    }
}

// MARK: - Hashable Conformance
extension Charger {
    static func == (lhs: Charger, rhs: Charger) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

