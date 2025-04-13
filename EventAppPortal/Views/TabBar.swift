//
//  TabBar.swift
//  DesignCodeiOS15
//
//  Created by Meng To on 2021-11-05.
//

import SwiftUI
// Add TabBar visibility manager
class TabBarVisibilityManager: ObservableObject {
    static let shared = TabBarVisibilityManager()
    @AppStorage("hideTab") var hideTab: Bool = false {
        didSet {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isVisible = !hideTab
            }
        }
    }
    @Published var isVisible: Bool = true
}

// Add TabBar visibility modifier
struct TabBarModifier: ViewModifier {
    let isVisible: Bool
    
    func body(content: Content) -> some View {
        content
            .offset(y: isVisible ? 0 : UIScreen.main.bounds.height)
    }
}
struct TabBar: View {
    @AppStorage("selectedTab") var selectedTab: Tab = .home
    @AppStorage("hideTab") var hideTab: Bool = false
    @State var color: Color = .teal
    @State var tabItemWidth: CGFloat = 0
    @State var animateClick = false
    @State private var showCreateSheet = false
    
    var body: some View {
        HStack(alignment: .center) {
            buttons
        }
        .padding(.horizontal, 8)
        .padding(.top, 14)
       
        .frame(height: 178, alignment: .top)
        
        .background(Color.dynamic)
        .padding(.bottom,10)
       
        .cornerRadius(0)
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(Color.invert.opacity(0.00), lineWidth: 1)
        )
       // .scaleEffect(animateClick ? 0.97 : 1)
        
        .offset(y: hideTab ? 200 : 100) // Move the tab downwards when hideTab is true
        .animation(.spring(), value: hideTab) // Animate the offset change
        .frame(maxHeight: .infinity, alignment: .bottom)
        
        .onChange(of: selectedTab, perform: { change in
            withAnimation(.spring()) {
                animateClick = true
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.prepare()
                generator.impactOccurred()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring()) {
                    animateClick = false
                }
            }
        })
        .sheet(isPresented: $showCreateSheet) {
            NavigationView {
                CreateView()
                    .navigationBarItems(
                        trailing: Button("Done") {
                            showCreateSheet = false
                        }
                    )
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .ignoresSafeArea()
    }
    
    var buttons: some View {
        ForEach(tabItems) { item in
            Button {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.prepare()
                generator.impactOccurred()
                if item.tab == .create {
                    showCreateSheet = true
                    color = item.color
                } else {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = item.tab
                        color = item.color
                        
                    }
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
//                            Text("\(proxy.size.width)")
                    Color.clear.preference(key: TabPreferenceKey.self, value: proxy.size.width)
                }
            )
            .onPreferenceChange(TabPreferenceKey.self) { value in
                tabItemWidth = value
            }
        }
    }
    
   
    
   
}

struct TabBar_Previews: PreviewProvider {
    static var previews: some View {
        TabBar()
.previewInterfaceOrientation(.portrait)
    }
}


struct TabItem: Identifiable {
    var id = UUID()
    var text: String
    var icon: String
    var tab: Tab
    var color: Color
}

var tabItems = [
    TabItem(text: "Home", icon: "house", tab: .home, color: .teal),
    TabItem(text: "Explore", icon: "magnifyingglass", tab: .explore, color: .blue),
    TabItem(text: "Create", icon: "plus", tab: .create, color: .purple),
    TabItem(text: "Groups", icon: "person.3", tab: .groups, color: .green),
    TabItem(text: "Account", icon: "person", tab: .account, color: .pink)
]

enum Tab: String {
    case home
    case explore
    case create
    case groups
    case account
}

struct TabPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
