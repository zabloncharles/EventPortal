import SwiftUI

// Import TabBar from Components
@_exported import struct EventAppPortal.TabBar

struct MainTabView: View {
    @AppStorage("selectedTab") var selectedTab: Tab = .home
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tag(Tab.home)
                
                DiscoverView()
                    .tag(Tab.discover)
                
                CreateEventView()
                    .tag(Tab.create)
                
                ProfileView()
                    .tag(Tab.profile)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            TabBar()
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
} 