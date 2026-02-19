import Combine
import FirebaseFirestore

class ChargerRepository: ObservableObject {
    @Published var chargers: [Charger] = []
    @Published var myChargers: [Charger] = []
    
    private let firestoreService = FirestoreService.shared
    private var chargersListener: ListenerRegistration?
    private var hostChargersListener: ListenerRegistration?
    
    func loadAvailableChargers() {
        chargersListener = firestoreService.listenToAvailableChargers { [weak self] chargers in
            self?.chargers = chargers
        }
    }
    
    /// Real-time listener for host's chargers - automatically updates when data changes in Firestore
    func listenToMyChargers(hostId: String) {
        hostChargersListener?.remove()
        hostChargersListener = firestoreService.listenToHostChargers(hostId: hostId) { [weak self] chargers in
            DispatchQueue.main.async {
                self?.myChargers = chargers
            }
        }
    }
    
    func stopListeningToMyChargers() {
        hostChargersListener?.remove()
        hostChargersListener = nil
    }
    
    func createCharger(_ charger: Charger) async throws -> String {
        return try await firestoreService.saveCharger(charger)
    }
    
    func updateCharger(_ charger: Charger) async throws {
        try await firestoreService.updateCharger(charger)
    }
    
    func deleteCharger(id: String) async throws {
        try await firestoreService.deleteCharger(id: id)
    }
    
    deinit {
        chargersListener?.remove()
        hostChargersListener?.remove()
    }
}

