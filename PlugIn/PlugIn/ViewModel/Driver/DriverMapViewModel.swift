import SwiftUI
import MapKit
import Combine

@MainActor
class DriverMapViewModel: ObservableObject {
    @Published var position: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    ))
    @Published var chargers: [Charger] = []
    @Published var selectedCharger: Charger?
    @Published var selectedChargerDistance: String?
    @Published var showChargerDetail = false
    @Published var isLoading = true
    @Published var searchText = ""
    @Published var searchResults: [MKMapItem] = []
    @Published var isSearching = false
    @Published var showFilterSheet = false
    @Published var selectedChargerTypes: Set<ChargerType> = []
    @Published var selectedConnectorTypes: Set<ConnectorType> = []
    @Published var maxCreditsPerHour: Int? = nil
    @Published var availabilityFilter: AvailabilityFilter = .now

    private let chargerRepository = ChargerRepository()
    private let locationService = LocationService()
    private var cancellables = Set<AnyCancellable>()
    private var allChargers: [Charger] = [] // Unfiltered chargers
    var currentUserId: String? // To filter out own chargers

    init() {
        setupBindings()
        loadChargers()
    }
    
    private func setupBindings() {
        // center when user taps the button
        locationService.$currentLocation
            .compactMap { $0 }
            .sink { _ in
                // Location updated, but don't auto-center
            }
            .store(in: &cancellables)

        // Listen to chargers and apply filters
        chargerRepository.$chargers
            .sink { [weak self] chargers in
                self?.allChargers = chargers
                self?.applyFilters()
                self?.isLoading = false
            }
            .store(in: &cancellables)
    }

    // MARK: - Filter Methods

    func applyFilters() {
        var filtered = allChargers

        // Filter out own chargers
        if let userId = currentUserId {
            filtered = filtered.filter { $0.hostId != userId }
        }

        // Filter by charger type
        if !selectedChargerTypes.isEmpty {
            filtered = filtered.filter { selectedChargerTypes.contains($0.type) }
        }

        // Filter by connector type
        if !selectedConnectorTypes.isEmpty {
            filtered = filtered.filter { selectedConnectorTypes.contains($0.connectorType) }
        }

        // Filter by max credits per hour
        if let maxCredits = maxCreditsPerHour {
            filtered = filtered.filter { $0.creditsPerHour <= maxCredits }
        }

        // Filter by availability schedule
        switch availabilityFilter {
        case .now:
            filtered = filtered.filter { $0.isAvailable(at: Date()) }
        case .at(let date):
            filtered = filtered.filter { $0.isAvailable(at: date) }
        }

        chargers = filtered
    }

    func clearFilters() {
        selectedChargerTypes.removeAll()
        selectedConnectorTypes.removeAll()
        maxCreditsPerHour = nil
        availabilityFilter = .now
        applyFilters()
    }

    var hasActiveFilters: Bool {
        !selectedChargerTypes.isEmpty || !selectedConnectorTypes.isEmpty || maxCreditsPerHour != nil || availabilityFilter != .now
    }
    
    func loadChargers() {
        chargerRepository.loadAvailableChargers()
        locationService.requestPermission()
    }
    
    func selectCharger(_ charger: Charger) {
        selectedCharger = charger
        selectedChargerDistance = calculateDistance(to: charger)
        showChargerDetail = true
    }
    
    func dismissChargerDetail() {
        selectedCharger = nil
        selectedChargerDistance = nil
        showChargerDetail = false
    }
    
    func centerOnLocation(_ coordinate: CLLocationCoordinate2D) {
        withAnimation {
            position = .region(MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            ))
        }
    }
    
    func centerOnUserLocation() {
        if let location = locationService.currentLocation {
            centerOnLocation(location.coordinate)
        }
    }
    
    func calculateDistance(to charger: Charger) -> String? {
        guard let distance = locationService.calculateDistance(to: charger.coordinate) else {
            return nil
        }
        return String(format: "%.1f mi", distance)
    }
}

// MARK: - Availability Filter

enum AvailabilityFilter: Equatable {
    case now
    case at(Date)

    static func == (lhs: AvailabilityFilter, rhs: AvailabilityFilter) -> Bool {
        switch (lhs, rhs) {
        case (.now, .now): return true
        case (.at(let a), .at(let b)): return a == b
        default: return false
        }
    }
}
