import SwiftUI

struct CustomDropdown<T: RawRepresentable & CaseIterable & Hashable>: View where T.RawValue == String {
    let title: String
    @Binding var selection: T
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.secondary)
            
            Menu {
                ForEach(Array(T.allCases), id: \.self) { option in
                    Button(option.rawValue) {
                        selection = option
                    }
                }
            } label: {
                HStack {
                    Text(selection.rawValue)
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
    }
}

