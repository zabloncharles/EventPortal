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

// MARK: - Color Extensions
extension Color {
    static var randomizetextcolor: Color {
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
        return colors.randomElement() ?? .invert
    }
    
    static func randomtextco(excluding colors: [Color] = []) -> Color {
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
        return availableColors.randomElement() ?? .invert
    }
}
// Add this before the Color extension
struct HideTabOnAppear: ViewModifier {
    @StateObject private var tabBarManager = TabBarVisibilityManager.shared
    let hide: Bool
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                tabBarManager.hideTab = hide
            }
           
    }
}

// Add this extension to make it easy to use the modifier
extension View {
    func hideTabOnAppear(_ hide: Bool = true) -> some View {
        self.modifier(HideTabOnAppear(hide: hide))
    }
}

// Add this extension to make it easy to use the modifier
extension View {
    func showTabOnAppear(_ hide: Bool = false) -> some View {
        self.modifier(HideTabOnAppear(hide: hide))
    }
}
