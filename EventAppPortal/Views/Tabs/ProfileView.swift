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
                    NavigationLink(destination: destinationView(for: item.title)) {
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
    
    @ViewBuilder
    private func destinationView(for title: String) -> some View {
        switch title {
        case "Edit Profile":
            EditProfileView()
        case "My Events":
            MyEventsView()
        case "Tickets":
            TicketsView()
        case "Bookmarked":
            BookmarkedView()
        case "Notifications":
            NotificationsView()
        case "Privacy":
            PrivacyView()
        case "Help Center":
            HelpCenterView()
        case "Contact Us":
            HelpCenterView()
        case "Rate App":
            Text("Rate App")
        default:
            Text(title)
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

// MARK: - Profile Related Views

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var fullName = "John Doe"
    @State private var email = "john.doe@example.com"
    @State private var bio = "iOS Developer & Event Enthusiast"
    @State private var showImagePicker = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Profile Image
                Button(action: { showImagePicker = true }) {
                    ZStack {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.blue)
                        
                        Circle()
                            .fill(Color.black.opacity(0.4))
                            .frame(width: 100, height: 100)
                            .overlay(
                                Image(systemName: "camera.fill")
                                    .foregroundColor(.white)
                            )
                    }
                }
                
                // Form Fields
                VStack(spacing: 15) {
                    ProfileTextField(title: "Full Name", text: $fullName)
                    ProfileTextField(title: "Email", text: $email)
                    ProfileTextEditor(title: "Bio", text: $bio)
                }
                .padding()
                
                Button(action: {
                    // Save changes
                    dismiss()
                }) {
                    Text("Save Changes")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding()
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct MyEventsView: View {
    @State private var selectedSegment = 0
    let segments = ["Upcoming", "Past", "Drafts"]
    
    var body: some View {
        VStack {
            // Custom Segment Control
            HStack {
                ForEach(0..<segments.count, id: \.self) { index in
                    Button(action: { selectedSegment = index }) {
                        Text(segments[index])
                            .fontWeight(selectedSegment == index ? .semibold : .regular)
                            .foregroundColor(selectedSegment == index ? .primary : .secondary)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(
                                selectedSegment == index ?
                                    Color.blue.opacity(0.1) :
                                    Color.clear
                            )
                            .cornerRadius(8)
                    }
                }
            }
            .padding()
            
            // Events List
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(0..<5) { _ in
                        EventCard()
                    }
                }
                .padding()
            }
        }
        .navigationTitle("My Events")
    }
}

struct TicketsView: View {
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(0..<5) { index in
                    TicketCard(
                        eventName: "Tech Conference 2024",
                        date: "Mar 15, 2024",
                        time: "10:00 AM",
                        ticketType: "VIP Pass",
                        ticketNumber: String(format: "T%04d", index + 1)
                    )
                }
            }
            .padding()
        }
        .navigationTitle("My Tickets")
    }
}

struct BookmarkedView: View {
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(0..<5) { _ in
                    SavedEventCard()
                }
            }
            .padding()
        }
        .navigationTitle("Bookmarked Events")
    }
}

struct NotificationsView: View {
    @State private var generalNotifications = true
    @State private var eventReminders = true
    @State private var newEvents = true
    @State private var messages = true
    
    var body: some View {
        List {
            Section(header: Text("General")) {
                Toggle("Push Notifications", isOn: $generalNotifications)
                Toggle("Event Reminders", isOn: $eventReminders)
                Toggle("New Events", isOn: $newEvents)
                Toggle("Messages", isOn: $messages)
            }
            
            Section(header: Text("Event Updates")) {
                NotificationSettingRow(title: "Upcoming Events", subtitle: "24 hours before")
                NotificationSettingRow(title: "Event Changes", subtitle: "Immediately")
                NotificationSettingRow(title: "Ticket Updates", subtitle: "Immediately")
            }
        }
        .navigationTitle("Notifications")
    }
}

struct PrivacyView: View {
    @State private var isProfilePublic = true
    @State private var showLocation = true
    @State private var allowMessages = true
    
    var body: some View {
        List {
            Section(header: Text("Profile Privacy")) {
                Toggle("Public Profile", isOn: $isProfilePublic)
                Toggle("Show Location", isOn: $showLocation)
                Toggle("Allow Messages", isOn: $allowMessages)
            }
            
            Section(header: Text("Data & Privacy")) {
                NavigationLink("Privacy Policy") {
                    PrivacyPolicyView()
                }
                NavigationLink("Terms of Service") {
                    TermsOfServiceView()
                }
                NavigationLink("Data Usage") {
                    DataUsageView()
                }
            }
        }
        .navigationTitle("Privacy Settings")
    }
}

struct HelpCenterView: View {
    @State private var searchText = ""
    
    var body: some View {
        VStack {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search help articles", text: $searchText)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding()
            
            List {
                Section(header: Text("Popular Topics")) {
                    HelpCenterRow(title: "How to create an event", icon: "calendar.badge.plus")
                    HelpCenterRow(title: "Ticket refund policy", icon: "ticket")
                    HelpCenterRow(title: "Account settings", icon: "person.circle")
                    HelpCenterRow(title: "Payment methods", icon: "creditcard")
                }
                
                Section(header: Text("Contact Support")) {
                    HelpCenterRow(title: "Send us a message", icon: "message")
                    HelpCenterRow(title: "Report a problem", icon: "exclamationmark.triangle")
                }
            }
        }
        .navigationTitle("Help Center")
    }
}

// MARK: - Helper Views

struct ProfileTextField: View {
    let title: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .foregroundColor(.secondary)
                .font(.subheadline)
            
            TextField(title, text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}

struct ProfileTextEditor: View {
    let title: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .foregroundColor(.secondary)
                .font(.subheadline)
            
            TextEditor(text: $text)
                .frame(height: 100)
                .padding(4)
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
    }
}

struct EventCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Tech Conference 2024")
                    .font(.headline)
                Spacer()
                Text("Upcoming")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.2))
                    .foregroundColor(.green)
                    .cornerRadius(4)
            }
            
            Text("Mar 15, 2024 • 10:00 AM")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("San Francisco Convention Center")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct TicketCard: View {
    let eventName: String
    let date: String
    let time: String
    let ticketType: String
    let ticketNumber: String
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Section
            VStack(alignment: .leading, spacing: 12) {
                Text(eventName)
                    .font(.headline)
                
                HStack {
                    Label(date, systemImage: "calendar")
                    Spacer()
                    Label(time, systemImage: "clock")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            
            // Divider with circles
            HStack {
                Circle()
                    .fill(Color(.systemBackground))
                    .frame(width: 20, height: 20)
                    .offset(x: -10)
                
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 1)
                
                Circle()
                    .fill(Color(.systemBackground))
                    .frame(width: 20, height: 20)
                    .offset(x: 10)
            }
            .padding(.horizontal, -10)
            
            // Bottom Section
            HStack {
                VStack(alignment: .leading) {
                    Text(ticketType)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(ticketNumber)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "qrcode")
                    .font(.title)
                    .foregroundColor(.blue)
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct SavedEventCard: View {
    var body: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "photo")
                        .foregroundColor(.gray)
                )
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Music Festival 2024")
                    .font(.headline)
                
                Text("Apr 20, 2024 • 7:00 PM")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Central Park, NY")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "bookmark.fill")
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct NotificationSettingRow: View {
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct HelpCenterRow: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)
            Text(title)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
    }
}

// Add these views after the last view in the file

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Group {
                    Text("Privacy Policy")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Last Updated: March 2024")
                        .foregroundColor(.secondary)
                    
                    Text("Information We Collect")
                        .font(.headline)
                    
                    Text("We collect information that you provide directly to us, including:")
                    
                    VStack(alignment: .leading, spacing: 10) {
                        BulletPoint(text: "Name and contact information")
                        BulletPoint(text: "Profile information")
                        BulletPoint(text: "Event preferences")
                        BulletPoint(text: "Device information")
                    }
                }
                
                Group {
                    Text("How We Use Your Information")
                        .font(.headline)
                        .padding(.top)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        BulletPoint(text: "Provide and improve our services")
                        BulletPoint(text: "Personalize your experience")
                        BulletPoint(text: "Send you updates about events")
                        BulletPoint(text: "Ensure platform security")
                    }
                }
                
                Group {
                    Text("Data Security")
                        .font(.headline)
                        .padding(.top)
                    
                    Text("We implement appropriate technical and organizational measures to protect your personal information.")
                }
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Group {
                    Text("Terms of Service")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Last Updated: March 2024")
                        .foregroundColor(.secondary)
                    
                    Text("1. Acceptance of Terms")
                        .font(.headline)
                    
                    Text("By accessing and using this application, you accept and agree to be bound by the terms and provision of this agreement.")
                }
                
                Group {
                    Text("2. User Responsibilities")
                        .font(.headline)
                        .padding(.top)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        BulletPoint(text: "Provide accurate information")
                        BulletPoint(text: "Maintain account security")
                        BulletPoint(text: "Comply with local laws")
                        BulletPoint(text: "Respect other users")
                    }
                }
                
                Group {
                    Text("3. Event Creation and Participation")
                        .font(.headline)
                        .padding(.top)
                    
                    Text("Users are responsible for events they create and must ensure all information is accurate and complies with our guidelines.")
                }
            }
            .padding()
        }
        .navigationTitle("Terms of Service")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DataUsageView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Group {
                    Text("Data Usage")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("App Data Usage")
                        .font(.headline)
                    
                    DataUsageRow(
                        title: "Profile Data",
                        size: "2.3 MB",
                        description: "Profile pictures, preferences, and settings"
                    )
                    
                    DataUsageRow(
                        title: "Event Cache",
                        size: "15.7 MB",
                        description: "Saved events and related images"
                    )
                    
                    DataUsageRow(
                        title: "Messages",
                        size: "5.1 MB",
                        description: "Event communications and notifications"
                    )
                }
                
                Group {
                    Text("Storage Management")
                        .font(.headline)
                        .padding(.top)
                    
                    Button(action: {}) {
                        HStack {
                            Text("Clear Cache")
                            Spacer()
                            Text("23.1 MB")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Data Usage")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// Helper Views
struct BulletPoint: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text("•")
                .padding(.trailing, 4)
            Text(text)
        }
    }
}

struct DataUsageRow: View {
    let title: String
    let size: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Text(size)
                    .foregroundColor(.secondary)
            }
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

