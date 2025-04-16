import SwiftUI

struct BackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color(uiColor: .systemBackground))
    }
}

extension View {
    func appBackground() -> some View {
        modifier(BackgroundModifier())
    }
} 

// MARK: - Color Extensions
extension Color {
    static var randomize: Color {
        let colors: [Color] = [
            .red,
            .orange,
            .yellow,
            .green,
            .mint,
            .teal,
            .cyan,
            .blue,
            .indigo,
            .purple,
            .pink,
            .brown
        ]
        return colors.randomElement()?.opacity(0.30) ?? .blue
    }
    
    static func random(excluding colors: [Color] = []) -> Color {
        let allColors: [Color] = [
            .red,
            .orange,
            .yellow,
            .green,
            .mint,
            .teal,
            .cyan,
            .blue,
            .indigo,
            .purple,
            .pink,
            .brown
        ]
        
        let availableColors = allColors.filter { !colors.contains($0) }
        return availableColors.randomElement()?.opacity(0.30) ?? .blue
    }
}
