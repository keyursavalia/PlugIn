import SwiftUI
import MapKit

struct AddChargerView: View {
    let chargerToEdit: Charger?
    @StateObject private var viewModel: AddChargerViewModel
    @Environment(\.dismiss) var dismiss
    
    init(chargerToEdit: Charger? = nil) {
        self.chargerToEdit = chargerToEdit
        self._viewModel = StateObject(wrappedValue: AddChargerViewModel(chargerToEdit: chargerToEdit))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Map Preview Section
                    locationSection
                    
                    // Hardware Section
                    hardwareSection
                    
                    // Pricing Section
                    pricingSection
                    
                    // Availability Section
                    availabilitySection
                    
                    // Access Instructions
                    accessInstructionsSection
                    
                    // Error Message
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    // Save Button
                    PrimaryButton(
                        title: viewModel.isEditMode ? "Update Charger" : "Save Charger",
                        action: { Task { await viewModel.saveCharger() } },
                        isLoading: viewModel.isLoading,
                        isDisabled: !viewModel.isFormValid
                    )
                    .padding(.bottom, 32)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(viewModel.isEditMode ? "Edit Charger" : "Add Charger")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $viewModel.showLocationPicker) {
                LocationPickerView(selectedLocation: $viewModel.selectedLocation) { coordinate in
                    viewModel.updateLocation(coordinate)
                }
            }
            .alert("Success!", isPresented: $viewModel.showSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text(viewModel.isEditMode ? "Your charger has been updated." : "Your charger has been added and is now visible to drivers.")
            }
        }
    }
    
    // MARK: - Location Section
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Location Details", icon: "mappin.circle.fill")
            
            VStack(spacing: 12) {
                // Map preview or placeholder
                if let location = viewModel.selectedLocation {
                    MapPreview(coordinate: location)
                        .frame(height: 200)
                        .cornerRadius(12)
                } else {
                    MapPlaceholder()
                        .frame(height: 200)
                }
                
                // Address field
                CustomTextField(
                    title: "Street Address",
                    placeholder: "1600 Holloway Ave",
                    text: $viewModel.address
                )
                
                // Location buttons (Task 12: Match SecondaryButton style)
                HStack(spacing: 12) {
                    Button(action: { viewModel.useCurrentLocation() }) {
                        HStack {
                            if viewModel.isLoadingLocation {
                                ProgressView()
                                    .tint(.green)
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "location.fill")
                            }
                            Text("Current Location")
                        }
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .foregroundColor(.green)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.green, lineWidth: 2)
                        )
                    }
                    .disabled(viewModel.isLoadingLocation)

                    Button(action: { viewModel.selectLocationOnMap() }) {
                        HStack {
                            Image(systemName: "map.fill")
                            Text("Select on Map")
                        }
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .foregroundColor(.green)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.green, lineWidth: 2)
                        )
                    }
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
        }
    }
    
    // MARK: - Hardware Section
    private var hardwareSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Hardware", icon: "bolt.fill")
            
            VStack(spacing: 16) {
                CustomDropdown(title: "Type", selection: $viewModel.selectedType)
                
                HStack(spacing: 12) {
                    CustomTextField(
                        title: "Max Speed (kW)",
                        placeholder: "7.2",
                        text: $viewModel.maxSpeed,
                        keyboardType: .decimalPad
                    )
                    
                    Text("kW")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 28)
                }
                
                CustomDropdown(title: "Connector Type", selection: $viewModel.selectedConnector)
                
                Toggle(isOn: $viewModel.hasTetheredCable) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Tethered Cable")
                            .font(.subheadline.weight(.medium))
                        Text("Cable is attached to charger")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
        }
    }
    
    // MARK: - Pricing Section
    private var pricingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Pricing", icon: "leaf.fill")

            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: "leaf.fill")
                        .font(.title3)
                        .foregroundColor(.green)

                    CustomTextField(
                        title: "Green Credits per Hour",
                        placeholder: "3",
                        text: $viewModel.creditsPerHour,
                        keyboardType: .numberPad
                    )

                    Text("credits/hr")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 28)
                }

                Text("Set how many green credits drivers will pay per hour")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
        }
    }
    
    // MARK: - Availability Section
    private var availabilitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Availability", icon: "clock.fill")

            VStack(spacing: 12) {
                Toggle(isOn: Binding(
                    get: { viewModel.isAvailable247 },
                    set: { newValue in
                        withAnimation(.easeInOut(duration: 0.25)) {
                            viewModel.isAvailable247 = newValue
                        }
                    }
                )) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Available 24/7")
                            .font(.subheadline.weight(.medium))
                        Text("Recommended for home chargers")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .tint(.green)

                if !viewModel.isAvailable247 {
                    Divider()

                    Text("Set your available hours")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    ForEach(0..<viewModel.dailySchedule.count, id: \.self) { index in
                        DayScheduleRow(day: $viewModel.dailySchedule[index])
                    }
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
        }
    }
    
    // MARK: - Access Instructions Section
    private var accessInstructionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Access Instructions", icon: "info.circle.fill")
            
            VStack(spacing: 8) {
                Text("Help drivers find your charger")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                TextEditor(text: $viewModel.accessInstructions)
                    .frame(height: 100)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .overlay(
                        Group {
                            if viewModel.accessInstructions.isEmpty {
                                Text("e.g. Code is 1234, charger is on left wall...")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding(12)
                                    .allowsHitTesting(false)
                            }
                        },
                        alignment: .topLeading
                    )
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
        }
    }
}

// MARK: - Supporting Views

struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.green)
            Text(title)
                .font(.headline)
        }
    }
}

struct MapPreview: View {
    let coordinate: CLLocationCoordinate2D
    @State private var region: MKCoordinateRegion
    
    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        _region = State(initialValue: MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }
    
    var body: some View {
        Map(coordinateRegion: .constant(region),
            annotationItems: [MapLocation(coordinate: coordinate)]) { location in
            MapMarker(coordinate: location.coordinate, tint: .green)
        }
    }
}

struct MapLocation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

struct MapPlaceholder: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color(.systemGray6))

            VStack(spacing: 8) {
                Image(systemName: "map")
                    .font(.system(size: 40))
                    .foregroundColor(.secondary)
                Text("No location selected")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .cornerRadius(12)
    }
}

// MARK: - Day Schedule Row

struct DayScheduleRow: View {
    @Binding var day: DayAvailability

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Toggle(isOn: $day.isAvailable) {
                    Text(day.shortDayName)
                        .font(.subheadline.weight(.medium))
                        .frame(width: 40, alignment: .leading)
                }
                .tint(.green)
            }

            if day.isAvailable {
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Text("From")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Picker("", selection: $day.startHour) {
                            ForEach(0..<24, id: \.self) { hour in
                                Text(formatHour(hour)).tag(hour)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.green)
                    }

                    HStack(spacing: 4) {
                        Text("To")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Picker("", selection: $day.endHour) {
                            ForEach((day.startHour + 1)...24, id: \.self) { hour in
                                Text(formatHour(hour == 24 ? 0 : hour)).tag(hour == 24 ? 0 : hour)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.green)
                    }

                    Spacer()
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, 4)
        .animation(.easeInOut(duration: 0.2), value: day.isAvailable)
    }

    private func formatHour(_ hour: Int) -> String {
        if hour == 0 { return "12 AM" }
        if hour == 12 { return "12 PM" }
        if hour < 12 { return "\(hour) AM" }
        return "\(hour - 12) PM"
    }
}
