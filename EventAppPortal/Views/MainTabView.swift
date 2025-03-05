import SwiftUI

struct MainTabView: View {
    @AppStorage("selectedTab") var selectedTab: Tab = .home
    @AppStorage("hideTab") var hideTab: Bool = false
    var body: some View {
        ZStack{
            switch selectedTab {
                case .home:
                    HomeView()
                        .tabItem {
                            Label("Home", systemImage: "house.fill")
                        }
                case .explore:
                    DiscoverView()
                        .tabItem {
                            Label("Discover", systemImage: "magnifyingglass")
                        }
                case .notifications:
                    CreateEventView()
                        .tabItem {
                            Label("Create", systemImage: "plus.circle.fill")
                        }
                case .account:
                    ProfileView()
                        .tabItem {
                            Label("Profile", systemImage: "person.fill")
                        }
            }
            TabBar()
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
} 
