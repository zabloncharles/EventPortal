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

struct TabPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

extension Color {
    static let dynamic = Color(uiColor: .systemBackground)
    static let invert = Color(uiColor: .systemBackground)
}

struct TabBar: View {
    @AppStorage("selectedTab") var selectedTab: Tab = .home
    @AppStorage("hideTab") var hideTab: Bool = false
    @State var color: Color = .teal
    @State var tabItemWidth: CGFloat = 0
    @State var animateClick = false
    
    var body: some View {
        HStack(alignment: .center) {
            buttons
        }
        .padding(.horizontal, 8)
        .padding(.top, 14)
        .frame(height: 78, alignment: .top)
        .background(Color.dynamic.opacity(0.90))
        .background(.ultraThinMaterial)
        .padding(.bottom,20)
        .cornerRadius(0)
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(Color.invert.opacity(0.00), lineWidth: 1)
        )
        .offset(y: hideTab ? 200 : 0)
        .animation(.spring(), value: hideTab)
        .frame(maxHeight: .infinity, alignment: .bottom)
        .onChange(of: selectedTab) { change in
            withAnimation(.spring()) {
                animateClick = true
                triggerLightVibration()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring()) {
                    animateClick = false
                }
            }
        }
        .ignoresSafeArea()
    }
    
    var buttons: some View {
        ForEach(tabItems) { item in
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedTab = item.tab
                    color = item.color
                }
            } label: {
                VStack(spacing: 0) {
                    Image(systemName: item.icon)
                        .symbolVariant(.fill)
                        .font(.body.bold())
                        .frame(width: 44, height: 29)
                    Text(item.text)
                        .font(.caption2)
                        .lineLimit(1)
                    Rectangle()
                        .fill(selectedTab == item.tab ? color : .clear)
                        .frame(width:18, height:2)
                        .cornerRadius(3)
                        .animation(.linear , value: selectedTab)
                        .offset(y:5)
                }
                .frame(maxWidth: .infinity)
            }
            .foregroundStyle(selectedTab == item.tab ? color : .secondary)
            .blendMode(selectedTab == item.tab ? .normal : .normal)
            .overlay(
                GeometryReader { proxy in
                    Color.clear.preference(key: TabPreferenceKey.self, value: proxy.size.width)
                }
            )
            .onPreferenceChange(TabPreferenceKey.self) { value in
                tabItemWidth = value
            }
        }
    }
    
    private func triggerLightVibration() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

struct TabBar_Previews: PreviewProvider {
    static var previews: some View {
        TabBar()
            .previewInterfaceOrientation(.portrait)
    }
} 