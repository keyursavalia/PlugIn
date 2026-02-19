import Foundation
import FirebaseFirestore

struct User: Codable, Identifiable {
    @DocumentID var id: String?
    let email: String
    var name: String = "Unknown User"
    var roles: [UserRole] = [.driver]
    var greenCredits: Int = 0
    var profileImageURL: String?
    var phoneNumber: String?
    var createdAt: Timestamp = Timestamp()

    // Host-specific
    var isVerified: Bool?
    var totalBookings: Int?
    var rating: Double?

    // Computed
    var isHost: Bool { roles.contains(.host) }
    var isDriver: Bool { roles.contains(.driver) }
    var hasSelectedRoles: Bool { !roles.isEmpty }

    init(id: String?, email: String, name: String = "Unknown User", roles: [UserRole] = [.driver], greenCredits: Int = 0, profileImageURL: String? = nil, phoneNumber: String? = nil, createdAt: Timestamp = Timestamp(), isVerified: Bool? = nil, totalBookings: Int? = nil, rating: Double? = nil) {
        self.id = id
        self.email = email
        self.name = name
        self.roles = roles
        self.greenCredits = greenCredits
        self.profileImageURL = profileImageURL
        self.phoneNumber = phoneNumber
        self.createdAt = createdAt
        self.isVerified = isVerified
        self.totalBookings = totalBookings
        self.rating = rating
    }
}

