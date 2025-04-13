import SwiftUI

struct MainTabView: View {
    @AppStorage("selectedTab") var selectedTab: Tab = .home
    @StateObject private var tabBarManager = TabBarVisibilityManager.shared
    
    var body: some View {
        ZStack {
            switch selectedTab {
            case .home:
                HomeView()
            case .explore:
                DiscoverView()
            case .groups:
                GroupsView()
            case .create:
                EmptyView() // This is handled by the sheet in TabBar
            case .account:
                ProfileView()
            }
            
            // Tab Bar with animation
            VStack {
                Spacer()
                TabBar()
            }
            .ignoresSafeArea(.keyboard)
        }
        .onAppear {
            tabBarManager.hideTab = false
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
} 
