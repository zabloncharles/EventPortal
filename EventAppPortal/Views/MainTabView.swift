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
                case .notifications:
                    CreateEventView()
                case .account:
                    ProfileView()
            }
            
            // Tab Bar with animation
            VStack {
                Spacer()
                TabBar()
//                    .offset(y: hideTab ? 50 : 0) // Move down when hidden
//                    .animation(.spring(), value: hideTab)
            }
            .ignoresSafeArea(.keyboard)
        }
        .onAppear {
            tabBarManager.hideTab = true
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
} 
