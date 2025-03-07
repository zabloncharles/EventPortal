//
//  EventAppPortalApp.swift
//  EventAppPortal
//
//  Created by Zablon Charles on 3/3/25.
//

import SwiftUI

@main
struct EventAppPortalApp: App {
    @State private var isAuthenticated = true
    
    var body: some Scene {
        WindowGroup {
            if isAuthenticated {
                MainTabView()
            } else {
                LoginView()
            }
        }
    }
}
