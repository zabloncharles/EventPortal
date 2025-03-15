import SwiftUI
import FirebaseCore

@main
struct EventAppPortalApp: App {
    @StateObject private var firebaseManager = FirebaseManager.shared
    
    init() {
        // Configure Firebase on app launch
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(firebaseManager)
        }
    }
}

#if DEBUG
struct Previews_EventAppPortalApp_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(FirebaseManager.shared)
    }
}
#endif 