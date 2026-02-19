import SwiftUI

extension Color {
    static let theme = ColorTheme()
    
    struct ColorTheme {
        let primary = Color.blue
        let secondary = Color.gray
        let success = Color.green
        let warning = Color.orange
        let error = Color.red
        let background = Color(.systemGroupedBackground)
        let cardBackground = Color.white
    }
}
