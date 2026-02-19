import SwiftUI

struct ChargerPinView: View {
    let charger: Charger
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "leaf.fill")
                .font(.caption)
            Text("\(charger.creditsPerHour)")
                .font(.caption.bold())
            Text("credits/hr")
                .font(.caption2)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(charger.status.color)
        .cornerRadius(20)
        .shadow(radius: 3)
        .contentShape(Rectangle())
        .onTapGesture {
            action()
        }
    }
}
