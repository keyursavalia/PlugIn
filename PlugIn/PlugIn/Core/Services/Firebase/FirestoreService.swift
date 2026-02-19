import FirebaseFirestore

class FirestoreService {
    static let shared = FirestoreService()
    private let db = Firestore.firestore()
    
    private init() {}
    
    // MARK: - Collections
    private var usersCollection: CollectionReference {
        db.collection("users")
    }
    
    private var chargersCollection: CollectionReference {
        db.collection("chargers")
    }
    
    private var bookingsCollection: CollectionReference {
        db.collection("bookings")
    }
    
    // MARK: - User Operations
    func saveUser(_ user: User) async throws {
        guard let id = user.id else { throw FirestoreError.invalidData }
        try usersCollection.document(id).setData(from: user)
    }
    
    func getUser(uid: String) async throws -> User {
        let snapshot = try await usersCollection.document(uid).getDocument()
        return try snapshot.data(as: User.self)
    }
    
    func updateUser(_ user: User) async throws {
        guard let id = user.id else { throw FirestoreError.invalidData }
        try usersCollection.document(id).setData(from: user, merge: true)
    }

    func updateUserCredits(userId: String, creditsChange: Int) async throws {
        let userRef = usersCollection.document(userId)
        try await userRef.updateData([
            "greenCredits": FieldValue.increment(Int64(creditsChange))
        ])
    }
    
    // MARK: - Charger Operations
    func saveCharger(_ charger: Charger) async throws -> String {
        let docRef = try chargersCollection.addDocument(from: charger)
        return docRef.documentID
    }
    
    func getCharger(id: String) async throws -> Charger {
        let snapshot = try await chargersCollection.document(id).getDocument()
        return try snapshot.data(as: Charger.self)
    }
    
    func updateCharger(_ charger: Charger) async throws {
        guard let id = charger.id else { throw FirestoreError.invalidData }
        try chargersCollection.document(id).setData(from: charger)
    }
    
    func getChargersByHost(hostId: String) async throws -> [Charger] {
        let snapshot = try await chargersCollection
            .whereField("hostId", isEqualTo: hostId)
            .getDocuments()
        return snapshot.documents.compactMap { doc in
            (try? doc.data(as: Charger.self)).map { charger in
                var c = charger
                c.id = doc.documentID
                return c
            }
        }
    }
    
    /// Real-time listener for host's chargers - updates automatically when chargers are added/updated/deleted
    func listenToHostChargers(hostId: String, completion: @escaping ([Charger]) -> Void) -> ListenerRegistration {
        return chargersCollection
            .whereField("hostId", isEqualTo: hostId)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    completion([])
                    return
                }
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                let chargers = documents.compactMap { doc -> Charger? in
                    (try? doc.data(as: Charger.self)).map { charger in
                        var c = charger
                        c.id = doc.documentID
                        return c
                    }
                }
                completion(chargers)
            }
    }
    
    func deleteCharger(id: String) async throws {
        try await chargersCollection.document(id).delete()
    }
    
    // MARK: - Real-time Charger Listener
    func listenToAvailableChargers(completion: @escaping ([Charger]) -> Void) -> ListenerRegistration {
        return chargersCollection
            .whereField("status", isEqualTo: ChargerStatus.available.rawValue)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                let chargers = documents.compactMap { try? $0.data(as: Charger.self) }
                completion(chargers)
            }
    }
    
    // MARK: - Booking Operations
    func createBooking(_ booking: Booking) async throws -> String {
        let docRef = try bookingsCollection.addDocument(from: booking)
        return docRef.documentID
    }
    
    func updateBooking(_ booking: Booking) async throws {
        guard let id = booking.id else { throw FirestoreError.invalidData }
        try bookingsCollection.document(id).setData(from: booking, merge: true)
    }
    
    func getBooking(id: String) async throws -> Booking {
        let snapshot = try await bookingsCollection.document(id).getDocument()
        return try snapshot.data(as: Booking.self)
    }
    
    // Listen to single booking (request sent screen)
    func listenToBooking(id: String, completion: @escaping (Booking?) -> Void) -> ListenerRegistration {

        return bookingsCollection.document(id)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    completion(nil)
                    return
                }

                guard let snapshot = snapshot, snapshot.exists else {
                    completion(nil)
                    return
                }

                var booking = try? snapshot.data(as: Booking.self)
                booking?.id = id

                completion(booking)
            }
    }
    
    // Listen for incoming requests (Host)
    func listenToIncomingRequests(hostId: String, completion: @escaping ([Booking]) -> Void) -> ListenerRegistration {
        
        return bookingsCollection
            .whereField("hostId", isEqualTo: hostId)
            .whereField("status", isEqualTo: BookingStatus.pending.rawValue)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    completion([])
                    return
                }
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }

                let bookings = documents.compactMap { doc -> Booking? in
                    guard var booking = try? doc.data(as: Booking.self) else {
                        return nil
                    }
                    booking.id = doc.documentID
                    return booking
                }
                
                completion(bookings)
            }
    }

    // Get past bookings for user (both as host and driver)
    func getPastBookings(userId: String) async throws -> [Booking] {

        // Fetch bookings where user is HOST
        let hostSnapshot = try await bookingsCollection
            .whereField("hostId", isEqualTo: userId)
            .getDocuments()

        // Fetch bookings where user is DRIVER
        let driverSnapshot = try await bookingsCollection
            .whereField("driverId", isEqualTo: userId)
            .getDocuments()

        // Combine both
        let allDocs = hostSnapshot.documents + driverSnapshot.documents
        let bookings = allDocs.compactMap { doc -> Booking? in
            guard var booking = try? doc.data(as: Booking.self) else {
                return nil
            }
            booking.id = doc.documentID
            return booking
        }

        // Filter for past statuses and sort by date
        let pastStatuses: Set<BookingStatus> = [.accepted, .declined, .completed, .active]
        let filteredBookings = bookings
            .filter { pastStatuses.contains($0.status) }
            .sorted { $0.requestedAt.dateValue() > $1.requestedAt.dateValue() }

        return filteredBookings
    }
}

enum FirestoreError: Error {
    case invalidData
    case documentNotFound
}

