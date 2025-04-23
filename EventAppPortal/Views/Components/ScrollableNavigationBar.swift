import SwiftUI

// MARK: - ScrollableNavigationBar
struct ScrollableNavigationBar<Content: View>: View {
    // MARK: - Properties
    var title: String
    var icon: String = ""
    var trailingicon: String = ""
    var isInline: Bool = false
    var showBackButton: Bool = false
    var onBackPressed: (() -> Void)? = nil
    var onTrailingPressed: (() -> Void)? = nil
    let content: Content
    
    @Environment(\.presentationMode) var presentationMode
    
    @State private var isScrolled = false
    @State var animateScroll = false
    @State private var isRefreshing = false
    @State private var typewriterText = ""
    @State private var isTypewriterComplete = false
    
    // MARK: - Initialization
    init(
        title: String,
        icon: String = "",
        trailingicon: String = "",
        isInline: Bool = false,
        showBackButton: Bool = false,
        onBackPressed: (() -> Void)? = nil,
        onTrailingPressed: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.isInline = isInline
        self.trailingicon = trailingicon
        self.showBackButton = showBackButton
        self.onBackPressed = onBackPressed
        self.onTrailingPressed = onTrailingPressed
        self.content = content()
    }
    
    // MARK: - Body
    var body: some View {
        ZStack(alignment: .top) {
            // Main Content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Scroll detection
                    ScrollDetectionView(isScrolled: $isScrolled, isRefreshing: $isRefreshing)
                        .frame(height: 0)
                    
                    content
                }
            }
            .coordinateSpace(name: "scroll")
            
            // Navigation Bar
            if isScrolled || isInline {
                NavigationBarView(
                    title: title,
                    icon: icon,
                    trailingicon: trailingicon,
                    isInline: isInline,
                    showBackButton: showBackButton,
                    onBackPressed: onBackPressed ?? { presentationMode.wrappedValue.dismiss() },
                    onTrailingPressed: onTrailingPressed ?? {}
                )
                .transition(.move(edge: .top).combined(with: .opacity))
                .offset(y: animateScroll ? 36 : -50)
                .onAppear{
                    withAnimation(.spring()) {
                        animateScroll = true
                    }
                }
            }
        }.edgesIgnoringSafeArea(.all)
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
    var icon: String
    var trailingicon: String = ""
    var isInline: Bool = false
    var showBackButton: Bool = false
    var onBackPressed: () -> Void
    var onTrailingPressed: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                if showBackButton && isInline {
                    Spacer()
                    Text(title)
                        .font(.headline)
                        .bold()
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.invert, Color.invert]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    Spacer()
                } else if isInline {
                    Spacer()
                    Text(title)
                        .font(.headline)
                        .bold()
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.invert, Color.invert]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    Spacer()
                } else {
                    Spacer()
                    Text(title)
                        .font(.headline)
                        .bold()
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.invert, Color.invert]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    Spacer()
                }
            }
            .overlay {
                if showBackButton {
                    HStack {
                        Button(action: onBackPressed) {
                            Image(systemName: "chevron.left")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.primary.opacity(0.70))
                        }
                        .padding(.trailing, 8)
                        Spacer()
                        if !trailingicon.isEmpty {
                            Button(action: onTrailingPressed) {
                                Image(systemName: trailingicon)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary.opacity(0.70))
                            }
                            .padding(.trailing, 8)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(
            Rectangle()
                .fill(Color.dynamic)
                .frame(height:200)
                .offset(y:-72)
        )
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
        isInline: Bool = false
    ) -> some View {
        ScrollableNavigationBar(
            title: title,
            icon: icon,
            isInline: isInline
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
            isInline: false
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
