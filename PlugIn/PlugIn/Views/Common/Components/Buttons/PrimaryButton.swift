import SwiftUI

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var isLoading: Bool = false
    var isDisabled: Bool = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .foregroundColor(.white)
            .background(
                isDisabled ?
                    LinearGradient(colors: [Color.gray, Color.gray], startPoint: .leading, endPoint: .trailing) :
                    LinearGradient(colors: [Color.green, Color.green.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
            )
            .cornerRadius(12)
        }
        .disabled(isDisabled || isLoading)
    }
}

