import SwiftUI

struct ChargerDetailView: View {
    let charger: Charger
    let distance: String?
    @EnvironmentObject var coordinator: AppCoordinator
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Charger type
                HStack(spacing: 4) {
                    Image(systemName: charger.type.icon)
                    Text(charger.type.rawValue)
                    Text("•")
                    Text(charger.connectorType.rawValue)
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                // Location and distance
                HStack {
                    Text(charger.address)
                        .font(.title3.bold())
                        .lineLimit(2)
                    if let distance = distance {
                        Text("• \(distance) away")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Price
                VStack(alignment: .leading, spacing: 4) {
                    Text("$\(String(format: "%.2f", charger.pricePerHour))/hour")
                        .font(.title2.bold())
                    Text("or \(charger.creditsPerHour) Green Credits")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                PrimaryButton(title: "Request Charge") {
                    coordinator.push(.bookingRequest(charger))
                }
            }
            .padding()
        }
        .navigationTitle("Charger Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}
