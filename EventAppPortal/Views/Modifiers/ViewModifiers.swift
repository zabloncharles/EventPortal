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