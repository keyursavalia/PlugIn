import Combine
import Foundation

@MainActor
class HostDashboardViewModel: ObservableObject {
    @Published var chargers: [Charger] = []
    @Published var isLoading = true

    private let chargerRepository = ChargerRepository()
    private var cancellables = Set<AnyCancellable>()

    init() {
        chargerRepository.$myChargers
            .receive(on: DispatchQueue.main)
            .sink { [weak self] chargers in
                self?.chargers = chargers
                self?.isLoading = false
            }
            .store(in: &cancellables)
    }

    /// Start or restart the real-time listener. Call on appear and when sheet dismisses to ensure fresh data.
    func ensureListening(hostId: String) {
        chargerRepository.listenToMyChargers(hostId: hostId)
    }
    
    deinit {
        chargerRepository.stopListeningToMyChargers()
    }
    
    func toggleAvailability(for charger: Charger) async {
        var updated = charger
        updated.status = charger.status == .available ? .offline : .available
        
        do {
            try await chargerRepository.updateCharger(updated)
        } catch {
            print("Failed to toggle availability: \(error)")
        }
    }
    
    func deleteCharger(_ charger: Charger) async {
        guard let id = charger.id else { return }
        do {
            try await chargerRepository.deleteCharger(id: id)
        } catch {
            print("Failed to delete charger: \(error)")
        }
    }
}
