import SwiftUI

// MARK: - ScrollableNavigationBar
struct ScrollableNavigationBar<Content: View>: View {
    // MARK: - Properties
    let title: String
    let icon: String
    let trailingTitle: String
    let trailingIcon: String
    let showNotification: Bool
    let content: Content
    
    @State private var isScrolled = false
    @State var animateScroll = false
    @State private var isRefreshing = false
    @State private var typewriterText = ""
    @State private var isTypewriterComplete = false
    
    // MARK: - Initialization
    init(
        title: String,
        icon: String = "",
        trailingTitle: String = "",
        trailingIcon: String = "",
        showNotification: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.trailingTitle = trailingTitle
        self.trailingIcon = trailingIcon
        self.showNotification = showNotification
        self.content = content()
    }
    
    // MARK: - Body
    var body: some View {
        ZStack(alignment: .top) {
            // Main Content
            ScrollView {
                VStack(spacing: 0) {
                    // Scroll detection
                    ScrollDetectionView(isScrolled: $isScrolled, isRefreshing: $isRefreshing)
                        .frame(height: 0)
                    
                    content
                }
            }
            .coordinateSpace(name: "scroll")
            
            // Navigation Bar
            if isScrolled {
                NavigationBarView(
                    title: title,
                    icon: icon,
                    trailingTitle: trailingTitle,
                    trailingIcon: trailingIcon,
                    showNotification: showNotification
                )
                .transition(.move(edge: .top).combined(with: .opacity))
                .offset(y: animateScroll ? 0 : -50)
                .onAppear{
                    withAnimation(.spring()) {
                        
                        animateScroll = true
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            startTypewriterAnimation()
        }
    }
    
    // MARK: - Helper Methods
    private func startTypewriterAnimation() {
        typewriterText = ""
        isTypewriterComplete = false
        
        var currentIndex = 0
        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if currentIndex < title.count {
                let index = title.index(title.startIndex, offsetBy: currentIndex)
                let character = title[index]
                
                DispatchQueue.main.async {
                    withAnimation(.easeIn) {
                        typewriterText += String(character)
                    }
                }
                
                currentIndex += 1
            } else {
                timer.invalidate()
                isTypewriterComplete = true
            }
        }
    }
}

// MARK: - NavigationBarView
struct NavigationBarView: View {
    let title: String
    let icon: String
    let trailingTitle: String
    let trailingIcon: String
    let showNotification: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: 8) {
                    if !icon.isEmpty {
                        Image(systemName: icon)
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                    
                    Text(title)
                        .font(.title)
                        .bold()
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.invert, .yellow]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                
                Spacer()
                
                if showNotification {
                    NotificationBadge(text: trailingTitle)
                } else if !trailingIcon.isEmpty {
                    TrailingIconButton(
                        icon: trailingIcon,
                        text: trailingTitle
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider()
                .foregroundColor(.secondary)
                .opacity(0.9)
        }
        .background(
            Rectangle()
                .fill(Color.dynamic)
                .frame(height:200)
                .offset(y:-72)
        )
    }
}

// MARK: - NotificationBadge
struct NotificationBadge: View {
    let text: String
    
    var body: some View {
        Text(text)
            .padding(5)
            .background(
                Circle()
                    .fill(.red)
                    .padding(-2)
            )
    }
}

// MARK: - TrailingIconButton
struct TrailingIconButton: View {
    let icon: String
    let text: String
    @AppStorage("currentPage") var selected = 0
    
    var body: some View {
        HStack(alignment: .center) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(selected == 4 ? Color("black") : .red)
            
            if !text.isEmpty {
                Text(text)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(
            Color.red.opacity(!icon.isEmpty ? text.isEmpty && !icon.isEmpty ? 0 : 0.8 : 0)
        )
        .cornerRadius(20)
    }
}

// MARK: - ScrollDetectionView
struct ScrollDetectionView: View {
    @Binding var isScrolled: Bool
    @Binding var isRefreshing: Bool
    
    var body: some View {
        Rectangle()
            .frame(width: 0, height: 0.0001)
            .scrollDetection(isScrolled: $isScrolled, isRefreshing: $isRefreshing)
    }
}

// MARK: - ScrollDetectionModifier
struct ScrollDetectionModifier: ViewModifier {
    @Binding var isScrolled: Bool
    @Binding var isRefreshing: Bool
    
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { proxy in
                    let offset = proxy.frame(in: .named("scroll")).minY
                    Color.clear.preference(key: ScrollPreferenceKey.self, value: offset)
                }
            )
            .onPreferenceChange(ScrollPreferenceKey.self) { offset in
                // Check for pull-to-refresh
                if offset > 155 {
                    withAnimation(.spring()) {
                        isRefreshing = true
                    }
                }
                
                // Check for scroll position to show/hide navigation bar
                if offset < -55 {
                    withAnimation(.spring()) {
                        isScrolled = true
                    }
                } else {
                    withAnimation(.spring()) {
                        isScrolled = false
                    }
                }
            }
    }
}

// MARK: - ScrollPreferenceKey
struct ScrollPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - View Extension
extension View {
    func scrollDetection(isScrolled: Binding<Bool>, isRefreshing: Binding<Bool>) -> some View {
        self.modifier(ScrollDetectionModifier(isScrolled: isScrolled, isRefreshing: isRefreshing))
    }
    
    func withScrollableNavigationBar(
        title: String,
        icon: String = "",
        trailingTitle: String = "",
        trailingIcon: String = "",
        showNotification: Bool = false
    ) -> some View {
        ScrollableNavigationBar(
            title: title,
            icon: icon,
            trailingTitle: trailingTitle,
            trailingIcon: trailingIcon,
            showNotification: showNotification
        ) {
            self
        }
    }
}

// MARK: - Preview
struct ScrollableNavigationBar_Previews: PreviewProvider {
    static var previews: some View {
        ScrollableNavigationBar(
            title: "Home",
            icon: "house.fill",
            trailingTitle: "3",
            trailingIcon: "bell.fill",
            showNotification: true
        ) {
            VStack(spacing: 20) {
                ForEach(0..<50) { index in
                    Text("Item \(index)")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                }
            }
            .padding()
        }
    }
}
