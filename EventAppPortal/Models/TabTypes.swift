import SwiftUI

enum Tab: String, CaseIterable, Identifiable {
    case home
    case discover
    case create
    case profile
    
    var id: String { self.rawValue }
}

struct TabItem: Identifiable {
    let id = UUID()
    let text: String
    let icon: String
    let tab: Tab
    let color: Color
}

let tabItems: [TabItem] = [
    TabItem(text: "Home", icon: "house.fill", tab: .home, color: .blue),
    TabItem(text: "Discover", icon: "magnifyingglass", tab: .discover, color: .green),
    TabItem(text: "Create", icon: "plus.circle.fill", tab: .create, color: .orange),
    TabItem(text: "Profile", icon: "person.fill", tab: .profile, color: .purple)
] 