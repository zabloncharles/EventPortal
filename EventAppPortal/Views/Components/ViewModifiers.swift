import SwiftUI

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

// ... existing Color extension ... 