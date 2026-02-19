import SwiftUI
import MapKit
import Combine
import FirebaseFirestore
import CoreLocation

@MainActor
class AddChargerViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var address = ""
    @Published var selectedLocation: CLLocationCoordinate2D?
    @Published var selectedType: ChargerType = .level2
    @Published var selectedConnector: ConnectorType = .j1772
    @Published var maxSpeed = "7.2"
    @Published var pricePerHour = "3.00"
    @Published var creditsPerHour = "3"
    @Published var hasTetheredCable = false
    @Published var isAvailable247 = true
    @Published var dailySchedule: [DayAvailability] = DayAvailability.defaultWeek()
    @Published var accessInstructions = ""
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showLocationPicker = false
    @Published var showSuccessAlert = false
    @Published var isLoadingLocation = false
    
    // MARK: - Dependencies
    private let chargerRepository = ChargerRepository()
    private let authService = AuthService()
    private let locationService = LocationService()
    private var cancellables = Set<AnyCancellable>()
    
    private let chargerToEdit: Charger?
    
    init(chargerToEdit: Charger? = nil) {
        self.chargerToEdit = chargerToEdit
        // Listen to location service updates
        locationService.$locationError
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.errorMessage = error
                self?.isLoadingLocation = false  // Stop loading when permission denied or location fails
            }
            .store(in: &cancellables)
        
        if let charger = chargerToEdit {
            address = charger.address
            selectedLocation = CLLocationCoordinate2D(latitude: charger.location.latitude, longitude: charger.location.longitude)
            selectedType = charger.type
            selectedConnector = charger.connectorType
            maxSpeed = String(format: "%.1f", charger.maxSpeed)
            pricePerHour = String(format: "%.2f", charger.pricePerHour)
            creditsPerHour = "\(charger.creditsPerHour)"
            hasTetheredCable = charger.hasTetheredCable
            accessInstructions = charger.accessInstructions ?? ""
            if let schedule = charger.availabilitySchedule {
                isAvailable247 = false
                dailySchedule = schedule
            }
        }
    }
    
    // MARK: - Computed Properties
    var isFormValid: Bool {
        !address.isEmpty &&
        selectedLocation != nil &&
        !maxSpeed.isEmpty &&
        !pricePerHour.isEmpty &&
        !creditsPerHour.isEmpty
    }
    
    var pricePerHourDouble: Double {
        Double(pricePerHour) ?? 0.0
    }
    
    var creditsPerHourInt: Int {
        Int(creditsPerHour) ?? 0
    }
    
    var maxSpeedDouble: Double {
        Double(maxSpeed) ?? 0.0
    }
    
    // MARK: - Methods
    
    func useCurrentLocation() {
        isLoadingLocation = true
        errorMessage = nil
        
        // 1. Use requestOneShotLocation() - uses requestLocation() API designed for one-shot,
        //    which responds faster than startUpdatingLocation()
        locationService.requestOneShotLocation()
        
        // 2. Subscribe to the first valid location with a timeout
        //    Use DispatchQueue.main for reliable timeout delivery during user interaction
        locationService.$currentLocation
            .compactMap { $0 }
            .first()
            .timeout(.seconds(15), scheduler: DispatchQueue.main)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure = completion {
                    self?.isLoadingLocation = false
                    self?.errorMessage = "Could not find your location. Please try again or select on map."
                }
            }, receiveValue: { [weak self] location in
                guard let self = self else { return }
                self.updateLocation(location.coordinate)
                self.isLoadingLocation = false
            })
            .store(in: &cancellables)
    }
    
    func selectLocationOnMap() {
        // Ensure we have permission before showing the picker
        locationService.requestPermission()
        showLocationPicker = true
    }
    
    func updateLocation(_ coordinate: CLLocationCoordinate2D) {
        selectedLocation = coordinate
        
        // Reverse geocode
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self else { return }
            
            Task { @MainActor in
                if let error = error {
                } else if let placemark = placemarks?.first {
                    let formatted = self.formatAddress(from: placemark)
                    self.address = formatted
                }
            }
        }
    }
    
    private func formatAddress(from placemark: CLPlacemark) -> String {
        var components: [String] = []
        
        if let streetNumber = placemark.subThoroughfare {
            components.append(streetNumber)
        }
        if let street = placemark.thoroughfare {
            components.append(street)
        }
        if let city = placemark.locality {
            components.append(city)
        }
        if let state = placemark.administrativeArea {
            components.append(state)
        }
        
        return components.joined(separator: ", ")
    }
    
    var isEditMode: Bool { chargerToEdit != nil }
    
    func saveCharger() async {
        guard isFormValid else {
            errorMessage = "Please fill all required fields"
            return
        }
        
        guard let hostId = authService.currentUser?.id else {
            errorMessage = "User not authenticated"
            return
        }
        
        guard let location = selectedLocation else {
            errorMessage = "Please select a location"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            if let existing = chargerToEdit {
                var charger = existing
                charger.location = GeoPoint(latitude: location.latitude, longitude: location.longitude)
                charger.address = address
                charger.type = selectedType
                charger.connectorType = selectedConnector
                charger.pricePerHour = pricePerHourDouble
                charger.creditsPerHour = creditsPerHourInt
                charger.maxSpeed = maxSpeedDouble
                charger.hasTetheredCable = hasTetheredCable
                charger.accessInstructions = accessInstructions.isEmpty ? nil : accessInstructions
                charger.availabilitySchedule = isAvailable247 ? nil : dailySchedule
                try await chargerRepository.updateCharger(charger)
            } else {
                let charger = Charger(
                    id: nil,
                    hostId: hostId,
                    location: GeoPoint(latitude: location.latitude, longitude: location.longitude),
                    address: address,
                    type: selectedType,
                    connectorType: selectedConnector,
                    pricePerHour: pricePerHourDouble,
                    creditsPerHour: creditsPerHourInt,
                    status: .available,
                    maxSpeed: maxSpeedDouble,
                    hasTetheredCable: hasTetheredCable,
                    accessInstructions: accessInstructions.isEmpty ? nil : accessInstructions,
                    currentBookingId: nil,
                    rating: 5.0,
                    totalBookings: 0,
                    createdAt: Timestamp(),
                    availabilitySchedule: isAvailable247 ? nil : dailySchedule
                )
                let chargerId = try await chargerRepository.createCharger(charger)

                // Add host role when user registers a charger
                try? await authService.addHostRole()
            }
            isLoading = false
            showSuccessAlert = true
        } catch {
            isLoading = false
            errorMessage = "Failed to save charger: \(error.localizedDescription)"
        }
    }
    
    func resetForm() {
        address = ""
        selectedLocation = nil
        selectedType = .level2
        selectedConnector = .j1772
        maxSpeed = "7.2"
        pricePerHour = "3.00"
        creditsPerHour = "3"
        hasTetheredCable = false
        isAvailable247 = true
        dailySchedule = DayAvailability.defaultWeek()
        accessInstructions = ""
        errorMessage = nil
    }
}
