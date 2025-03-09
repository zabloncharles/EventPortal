import SwiftUI

struct ProfileView: View {
    @State private var isEditingProfile = false
    @State private var showingLogoutAlert = false
    @State private var selectedTab = "Created"
    
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Profile Header
                    ZStack(alignment: .top) {
                        // Cover Image
//                        LinearGradient(
//                            colors: [.purple.opacity(0.8), .blue.opacity(0.8)],
//                            startPoint: .topLeading,
//                            endPoint: .bottomTrailing
//                        )
                      
                        
                        HStack {
                            // Profile Image
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .foregroundStyle(.white)
                                .background(Circle().fill(.white.opacity(0.2)).blur(radius: 10))
                                .overlay(
                                    Circle()
                                        .stroke(.white.opacity(0.6), lineWidth: 4)
                                )
                                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                            
                            Spacer()
                            // Profile Info
                            VStack {
                                Text("John Doe")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                
                                Text("john.doe@example.com")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                // Stats
                                HStack(spacing: 40) {
                                    StatView(number: "24", title: "Events")
                                    StatView(number: "1.2K", title: "Followers")
                                    StatView(number: "284", title: "Following")
                                }
                                .padding(.top, 10)
                            }
                            
                        }
                        .padding(.top, 10)
                        .padding(.bottom, 10)
                        .padding(.horizontal,25)
                    }
                    
                    Divider()
                        .padding(.horizontal,25)
                    // Settings Cards
                    VStack(spacing: 16) {
                        SettingsCard(title: "Account Settings", items: [
                            SettingsItem(icon: "person.fill", title: "Edit Profile", color: .blue),
                            SettingsItem(icon: "calendar.badge.clock", title: "My Events", color: .green),
                            SettingsItem(icon: "ticket.fill", title: "Tickets", color: .green),
                            SettingsItem(icon: "bookmark.circle.fill", title: "Bookmarked", color: .green),
                            SettingsItem(icon: "bell.fill", title: "Notifications", color: .purple),
                            SettingsItem(icon: "lock.fill", title: "Privacy", color: .green)
                        ])
                        
                        SettingsCard(title: "Support", items: [
                            SettingsItem(icon: "questionmark.circle.fill", title: "Help Center", color: .orange),
                            SettingsItem(icon: "envelope.fill", title: "Contact Us", color: .pink),
                            SettingsItem(icon: "star.fill", title: "Rate App", color: .yellow)
                        ])
                        
                        // Sign Out Button
                        Button(action: { showingLogoutAlert = true }) {
                            HStack {
                                Image(systemName: "arrow.right.square.fill")
                                Text("Sign Out")
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(colors: [.red.opacity(0.8), .orange.opacity(0.8)],
                                             startPoint: .leading,
                                             endPoint: .trailing)
                            )
                            .cornerRadius(12)
                        }
                        .padding(.top)
                    }
                    .padding()
                }.padding(.bottom, 70) //to not hide the tabbar
            }.navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            
            .alert("Sign Out", isPresented: $showingLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    // TODO: Implement sign out
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
}

struct StatView: View {
    let number: String
    let title: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(number)
                .font(.title3)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct SettingsCard: View {
    let title: String
    let items: [SettingsItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                ForEach(items) { item in
                    NavigationLink(destination: Text(item.title)) {
                        HStack(spacing: 16) {
                            Image(systemName: item.icon)
                                .foregroundColor(item.color)
                                .frame(width: 24, height: 24)
                            
                            Text(item.title)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    }
                    
                    if item.id != items.last?.id {
                        Divider()
                            .padding(.leading, 56)
                    }
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
}

struct SettingsItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let color: Color
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}

