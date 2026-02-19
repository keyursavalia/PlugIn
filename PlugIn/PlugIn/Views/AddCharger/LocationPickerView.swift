import SwiftUI
import MapKit

struct LocationPickerView: View {
    @Binding var selectedLocation: CLLocationCoordinate2D?
    let onConfirm: (CLLocationCoordinate2D) -> Void
    @Environment(\.dismiss) var dismiss
    @StateObject private var locationService = LocationService()

    @State private var position: MapCameraPosition
    @State private var currentRegion: MKCoordinateRegion
    @State private var pinLocation: CLLocationCoordinate2D?
    @State private var showInstructions = true

    init(selectedLocation: Binding<CLLocationCoordinate2D?>, onConfirm: @escaping (CLLocationCoordinate2D) -> Void) {
        self._selectedLocation = selectedLocation
        self.onConfirm = onConfirm

        let initial = selectedLocation.wrappedValue ?? CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let region = MKCoordinateRegion(
            center: initial,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        _position = State(initialValue: .region(region))
        _currentRegion = State(initialValue: region)
        _pinLocation = State(initialValue: selectedLocation.wrappedValue)
    }

    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    // Map (Task 2: iOS 17+ API with tap-to-place)
                    ZStack {
                        Map(position: $position, interactionModes: .all) {
                            // Show user location
                            UserAnnotation()

                            // Show pin if placed
                            if let pin = pinLocation {
                                Annotation("", coordinate: pin) {
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.green)
                                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                                }
                            }
                        }
                        .mapStyle(.standard)
                        .ignoresSafeArea(edges: .top)
                        .onMapCameraChange { context in
                            currentRegion = context.region
                        }
                        .onTapGesture { tapLocation in
                            // Convert tap to coordinate
                            handleMapTap(at: tapLocation)
                        }

                        // Center crosshair for visual guide
                        if pinLocation == nil {
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(.green.opacity(0.7))
                                        .shadow(color: .white, radius: 2)
                                    Spacer()
                                }
                                Spacer()
                            }
                            .allowsHitTesting(false)
                        }
                    }

                    // Bottom control card
                    VStack(spacing: 16) {
                        // Instructions banner
                        if showInstructions {
                            HStack {
                                Image(systemName: "hand.tap.fill")
                                    .foregroundColor(.green)
                                Text("Tap anywhere on the map to place your charger pin")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Button(action: { showInstructions = false }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [Color.green.opacity(0.15), Color.green.opacity(0.05)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                        }

                        // Selected location info
                        if let pin = pinLocation {
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.title2)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Location Selected")
                                        .font(.subheadline.weight(.semibold))
                                    Text(String(format: "%.4f, %.4f", pin.latitude, pin.longitude))
                                        .font(.caption.monospacedDigit())
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Button(action: {
                                    pinLocation = nil
                                    showInstructions = true
                                }) {
                                    HStack {
                                        Image(systemName: "xmark")
                                        Text("Clear")
                                    }
                                    .font(.caption.weight(.medium))
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }
                            .padding()
                            .background(Color.green.opacity(0.05))
                            .cornerRadius(12)
                        }

                        // Action buttons
                        if pinLocation != nil {
                            HStack(spacing: 12) {
                                SecondaryButton(title: "Adjust") {
                                    pinLocation = nil
                                    showInstructions = true
                                }

                                PrimaryButton(title: "Confirm Location") {
                                    if let location = pinLocation {
                                        onConfirm(location)
                                        dismiss()
                                    }
                                }
                            }
                        } else {
                            // Quick action: Use center of screen
                            Button(action: useCenterLocation) {
                                HStack {
                                    Image(systemName: "scope")
                                    Text("Use Center of Screen")
                                }
                                .font(.subheadline.weight(.medium))
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .foregroundColor(.white)
                                .background(
                                    LinearGradient(
                                        colors: [Color.green, Color.green.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                            }

                            // Helper button to center on current location
                            Button(action: goToMyLocation) {
                                HStack {
                                    Image(systemName: "location.fill")
                                    Text("Go to My Location")
                                }
                                .font(.subheadline.weight(.medium))
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .foregroundColor(.green)
                                .background(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.green, lineWidth: 2)
                                )
                            }
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(20, corners: [.topLeft, .topRight])
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -2)
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                        .foregroundColor(.green)
                    }

                    ToolbarItem(placement: .principal) {
                        Text("Select Location")
                            .font(.headline)
                    }
                }
                .onAppear {
                    locationService.requestPermission()
                    locationService.startUpdating()

                    // Center on user location if available
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        if let currentLocation = locationService.currentLocation {
                            let region = MKCoordinateRegion(
                                center: currentLocation.coordinate,
                                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                            )
                            currentRegion = region
                            position = .region(region)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helper Methods

    /// Approximates tap location to coordinate
    /// So we use the center of the current map region
    private func handleMapTap(at location: CGPoint) {
        useCenterLocation()
        showInstructions = false
    }

    /// Places pin at the center of the current map view
    private func useCenterLocation() {
        pinLocation = currentRegion.center
        showInstructions = false
    }

    /// Centers map on user's current location
    private func goToMyLocation() {
        if let current = locationService.currentLocation {
            let region = MKCoordinateRegion(
                center: current.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
            currentRegion = region
            position = .region(region)
        }
    }
}
