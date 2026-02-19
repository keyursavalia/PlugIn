import SwiftUI

struct FilterSheet: View {
    @ObservedObject var viewModel: DriverMapViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Availability Filter
                    filterSection(title: "Availability") {
                        VStack(spacing: 12) {
                            FilterOptionButton(
                                title: "Available Now",
                                subtitle: "Show chargers available right now",
                                isSelected: viewModel.availabilityFilter == .now
                            ) {
                                viewModel.availabilityFilter = .now
                                viewModel.applyFilters()
                            }

                            FilterOptionButton(
                                title: "Available at Time",
                                subtitle: "Find chargers available at a specific time",
                                isSelected: viewModel.availabilityFilter != .now
                            ) {
                                viewModel.availabilityFilter = .at(Date().addingTimeInterval(3600))
                                viewModel.applyFilters()
                            }

                            if case .at(let date) = viewModel.availabilityFilter {
                                DatePicker(
                                    "Select time",
                                    selection: Binding(
                                        get: { date },
                                        set: {
                                            viewModel.availabilityFilter = .at($0)
                                            viewModel.applyFilters()
                                        }
                                    ),
                                    in: Date()...,
                                    displayedComponents: [.date, .hourAndMinute]
                                )
                                .datePickerStyle(.compact)
                                .tint(.green)
                                .padding(.horizontal, 4)
                            }
                        }
                    }

                    Divider()

                    // Charger Type Filter
                    filterSection(title: "Charger Type") {
                        VStack(spacing: 12) {
                            ForEach([ChargerType.level1, ChargerType.level2, ChargerType.dcFast], id: \.self) { type in
                                FilterOptionButton(
                                    title: type.displayName,
                                    subtitle: type.description,
                                    isSelected: viewModel.selectedChargerTypes.contains(type)
                                ) {
                                    toggleChargerType(type)
                                }
                            }
                        }
                    }

                    Divider()

                    // Connector Type Filter
                    filterSection(title: "Connector Type") {
                        VStack(spacing: 12) {
                            ForEach([ConnectorType.teslaNACS, ConnectorType.j1772, ConnectorType.ccs, ConnectorType.chademo], id: \.self) { type in
                                FilterOptionButton(
                                    title: type.displayName,
                                    subtitle: type.description,
                                    isSelected: viewModel.selectedConnectorTypes.contains(type)
                                ) {
                                    toggleConnectorType(type)
                                }
                            }
                        }
                    }

                    Divider()

                    // Credits Per Hour Filter
                    filterSection(title: "Max Credits Per Hour") {
                        VStack(spacing: 16) {
                            HStack {
                                Text("Up to \(viewModel.maxCreditsPerHour ?? 20) credits/hour")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                if viewModel.maxCreditsPerHour != nil {
                                    Button(action: {
                                        viewModel.maxCreditsPerHour = nil
                                        viewModel.applyFilters()
                                    }) {
                                        Text("Clear")
                                            .font(.caption.weight(.medium))
                                            .foregroundColor(.green)
                                    }
                                }
                            }

                            Slider(
                                value: Binding(
                                    get: { Double(viewModel.maxCreditsPerHour ?? 20) },
                                    set: { viewModel.maxCreditsPerHour = Int($0) }
                                ),
                                in: 1...20,
                                step: 1
                            )
                            .tint(.green)
                            .onChange(of: viewModel.maxCreditsPerHour) { _, _ in
                                viewModel.applyFilters()
                            }

                            HStack {
                                Text("1")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("20")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear All") {
                        viewModel.clearFilters()
                    }
                    .foregroundColor(.green)
                    .disabled(!viewModel.hasActiveFilters)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.green)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Helper Views

    @ViewBuilder
    private func filterSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)

            content()
        }
    }

    // MARK: - Filter Actions

    private func toggleChargerType(_ type: ChargerType) {
        if viewModel.selectedChargerTypes.contains(type) {
            viewModel.selectedChargerTypes.remove(type)
        } else {
            viewModel.selectedChargerTypes.insert(type)
        }
        viewModel.applyFilters()
    }

    private func toggleConnectorType(_ type: ConnectorType) {
        if viewModel.selectedConnectorTypes.contains(type) {
            viewModel.selectedConnectorTypes.remove(type)
        } else {
            viewModel.selectedConnectorTypes.insert(type)
        }
        viewModel.applyFilters()
    }
}

// MARK: - Filter Option Button

struct FilterOptionButton: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? .green : .gray)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding()
            .background(isSelected ? Color.green.opacity(0.1) : Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.green : Color.clear, lineWidth: 2)
            )
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Extensions for Display Names

extension ChargerType {
    var displayName: String {
        switch self {
        case .level1: return "Level 1 (120V)"
        case .level2: return "Level 2 (240V)"
        case .dcFast: return "DC Fast Charging"
        }
    }

    var description: String {
        switch self {
        case .level1: return "Slow charging, overnight"
        case .level2: return "Medium speed, 4-8 hours"
        case .dcFast: return "Rapid charging, 20-60 min"
        }
    }
}

extension ConnectorType {
    var displayName: String {
        switch self {
        case .teslaNACS: return "Tesla NACS"
        case .j1772: return "J1772"
        case .ccs: return "CCS (Combined)"
        case .chademo: return "CHAdeMO"
        }
    }

    var description: String {
        switch self {
        case .teslaNACS: return "Tesla & compatible EVs"
        case .j1772: return "Most EVs in North America"
        case .ccs: return "European & many new EVs"
        case .chademo: return "Nissan Leaf & older EVs"
        }
    }
}
