import CoreLocation
import Combine

class LocationService: NSObject, ObservableObject {
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var locationError: String?
    
    private let locationManager = CLLocationManager()
    
    /// When true, we'll call requestLocation() once permission is granted (for one-shot "Current Location" button)
    private var pendingOneShotRequest = false
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10  // Update every 10 meters
        
        // Check current authorization status
        authorizationStatus = locationManager.authorizationStatus
        
        // If already authorized, start updating (for continuous tracking in map views)
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            startUpdating()
        }
    }
    
    func requestPermission() {
        let status = locationManager.authorizationStatus

        switch status {
        case .notDetermined:
            // This triggers the alert ONLY if the Info.plist key is present
            locationManager.requestWhenInUseAuthorization()
            
        case .authorizedWhenInUse, .authorizedAlways:
            startUpdating()
            
        case .denied, .restricted:
            locationError = "Location access is denied. Please enable it in Settings."
            
        @unknown default:
            break
        }
    }
    
    /// Request a single location update - ideal for "Current Location" button. Uses requestLocation()
    /// which is designed for one-shot and typically responds faster than startUpdatingLocation().
    func requestOneShotLocation() {
        let status = locationManager.authorizationStatus
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            pendingOneShotRequest = false
            locationManager.requestLocation()
            
        case .notDetermined:
            pendingOneShotRequest = true
            locationManager.requestWhenInUseAuthorization()
            
        case .denied, .restricted:
            pendingOneShotRequest = false
            locationError = "Location access is denied. Please enable it in Settings."
            
        @unknown default:
            break
        }
    }
    
    func startUpdating() {
        locationManager.startUpdatingLocation()
    }
    
    func stopUpdating() {
        locationManager.stopUpdatingLocation()
    }
    
    func calculateDistance(to coordinate: CLLocationCoordinate2D) -> Double? {
        guard let current = currentLocation else { return nil }
        let destination = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return current.distance(from: destination) / 1609.34  // Convert to miles
    }
    
    private var authorizationStatusString: String {
        switch locationManager.authorizationStatus {
        case .notDetermined: return "Not Determined"
        case .restricted: return "Restricted"
        case .denied: return "Denied"
        case .authorizedAlways: return "Authorized Always"
        case .authorizedWhenInUse: return "Authorized When In Use"
        @unknown default: return "Unknown"
        }
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        DispatchQueue.main.async { [weak self] in
            self?.currentLocation = location
            self?.locationError = nil
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.locationError = error.localizedDescription
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.authorizationStatus = status
            
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                self.locationError = nil
                if self.pendingOneShotRequest {
                    self.pendingOneShotRequest = false
                    manager.requestLocation()
                } else {
                    self.startUpdating()
                }
            case .denied, .restricted:
                self.pendingOneShotRequest = false
                self.locationError = "Location access denied. Please enable it in Settings."
            case .notDetermined:
                print("Location permission not determined")
            @unknown default:
                break
            }
        }
    }
}
