import SwiftUI

struct MainTabView: View {
    @AppStorage("selectedTab") var selectedTab: Tab = .home
    @StateObject private var tabBarManager = TabBarVisibilityManager.shared
    @Binding var showLogo : Bool
    var body: some View {
        ZStack {
            switch selectedTab {
            case .home:
                    HomeView(showlogo:$showLogo)
            case .explore:
                DiscoverView()
                    
            case .groups:
                GroupsView()
            case .create:
                    // Tab Bar with animation
                    CreateView()
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
            selectedTab = .home
        
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView(showLogo: .constant(false))
    }
} 
