import SwiftUI
import FirebaseFirestore

struct ProfileView: View {
    @State private var isEditingProfile = false
    @State private var showingLogoutAlert = false
    @State private var selectedTab = "Created"
    @EnvironmentObject private var firebaseManager: FirebaseManager
    @State private var userData: [String: Any]? = nil
    @AppStorage("userID") private var userID: String = ""
    @State private var isResettingEvents = false
    
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
                                Text(userData?["name"] as? String ?? "Loading...")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                
                                Text(firebaseManager.currentUser?.email ?? "")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                // Stats
                                HStack(spacing: 40) {
                                    StatView(number: "\(userData?["eventsCreated"] as? Int ?? 0)", title: "Events")
                                    StatView(number: "0", title: "Followers")
                                    StatView(number: "0", title: "Following")
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
                    firebaseManager.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: resetAndPopulateEvents) {
                        if isResettingEvents {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                        }
                    }
                    .disabled(isResettingEvents)
                }
            }
        }
        .onAppear {
            loadUserData()
        }
    }
    
    private func loadUserData() {
        firebaseManager.getUserData { data, error in
            if let data = data {
                self.userData = data
            }
        }
    }
    
    private func resetAndPopulateEvents() {
        let db = Firestore.firestore()
        isResettingEvents = true
        
        // First, delete all existing events
        db.collection("events").getDocuments(source: .default) { (snapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
                return
            }
            
            // Create a dispatch group to track all deletions
            let deleteGroup = DispatchGroup()
            
            // Delete all existing documents
            snapshot?.documents.forEach { document in
                deleteGroup.enter()
                document.reference.delete { error in
                    if let error = error {
                        print("Error deleting document: \(error)")
                    }
                    deleteGroup.leave()
                }
            }
            
            // After all deletions are complete, add new events
            deleteGroup.notify(queue: .main) {
                // Create a dispatch group for adding new events
                let addGroup = DispatchGroup()
                
                // Sample events with coordinates
                let eventsWithCoordinates = [
                    Event(
                        id: UUID().uuidString,
                        name: "Sample Team Building Retreat",
                        description: "A weekend retreat to improve team dynamics and collaboration. Join us for an unforgettable day of music, food, and fun at the Summer Music Festival! Enjoy live performances from top artists, great food trucks, and plenty of activities for all ages.",
                        type: "Corporate",
                        views: "3434",
                        location: "Soho House, New York",
                        price: "12",
                        owner: userID,
                        startDate: Calendar.current.date(byAdding: .day, value: 10, to: Date()) ?? Date(),
                        endDate: Calendar.current.date(byAdding: .day, value: 45, to: Date()) ?? Date(),
                        images: ["bg1","bg2"],
                        participants: ["Alice", "Bob", "Charlie", "Dana"],
                        isTimed: true,
                        createdAt: Date(),
                        coordinates: [40.7247, -73.9973],
                        status: "active"
                    ),
                    Event(
                        id: UUID().uuidString,
                        name: "Product Launch",
                        description: "Launching the latest version of our flagship product.",
                        type: "Marketing",
                        views: "544",
                        location: "The Library, New York",
                        price: "5",
                        owner: userID,
                        startDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date(),
                        endDate: Calendar.current.date(byAdding: .day, value: 45, to: Date()) ?? Date(),
                        images: ["bg3","bg6"],
                        participants: ["Eve", "Frank", "Grace"],
                        isTimed: true,
                        createdAt: Date(),
                        coordinates: [40.7532, -73.9822],
                        status: "active"
                    ),
                    Event(
                        id: UUID().uuidString,
                        name: "Yoga Workshop",
                        description: "An introductory yoga workshop for beginners.",
                        type: "Health & Wellness",
                        views: "6564",
                        location: "The Wing, New York",
                        price: "65",
                        owner: userID,
                        startDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date(),
                        endDate: Calendar.current.date(byAdding: .day, value: 45, to: Date()) ?? Date(),
                        images: ["bg4","bg5"],
                        participants: ["Hank", "Ivy", "Jack"],
                        isTimed: false,
                        createdAt: Date(),
                        coordinates: [40.7398, -73.9934],
                        status: "active"
                    ),
                    Event(
                        id: UUID().uuidString,
                        name: "Hackathon 2025",
                        description: "A 48-hour coding marathon to develop innovative solutions.",
                        type: "Technology",
                        views: "23",
                        location: "NeueHouse, New York",
                        price: "29.99",
                        owner: userID,
                        startDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date(),
                        endDate: Calendar.current.date(byAdding: .day, value: 45, to: Date()) ?? Date(),
                        images: ["bg6","bg4"],
                        participants: ["Kate", "Leo", "Mona", "Nina"],
                        isTimed: true,
                        createdAt: Date(),
                        coordinates: [40.7401, -73.9969],
                        status: "active"
                    ),
                    Event(
                        id: UUID().uuidString,
                        name: "Art Exhibition",
                        description: "Showcasing local artists' work for the year 2025.",
                        type: "Art & Culture",
                        views: "3444",
                        location: "The Strand Bookstore, New York",
                        price: "0",
                        owner: userID,
                        startDate: Calendar.current.date(byAdding: .day, value: 20, to: Date()) ?? Date(),
                        endDate: Calendar.current.date(byAdding: .day, value: 45, to: Date()) ?? Date(),
                        images: ["bg1","bg4"],
                        participants: ["Olivia", "Paul"],
                        isTimed: false,
                        createdAt: Date(),
                        coordinates: [40.7332, -73.9907],
                        status: "active"
                    ),
                    Event(
                        id: UUID().uuidString,
                        name: "Charity Gala",
                        description: "An annual gala to raise funds for underprivileged children.",
                        type: "Charity",
                        views: "23232",
                        location: "The Soho Grand Hotel, New York",
                        price: "6",
                        owner: userID,
                        startDate: Calendar.current.date(byAdding: .day, value: 60, to: Date()) ?? Date(),
                        endDate: Calendar.current.date(byAdding: .day, value: 45, to: Date()) ?? Date(),
                        images: ["bg8","bg6"],
                        participants: ["Quincy", "Rachel", "Sam", "Tina"],
                        isTimed: true,
                        createdAt: Date(),
                        coordinates: [40.7403, -74.0028],
                        status: "active"
                    ),
                    Event(
                        id: UUID().uuidString,
                        name: "Book Club Meeting",
                        description: "Monthly book discussion on contemporary literature.",
                        type: "Literature",
                        views: "233",
                        location: "New York Public Library",
                        price: "66",
                        owner: userID,
                        startDate: Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date(),
                        endDate: Calendar.current.date(byAdding: .day, value: 45, to: Date()) ?? Date(),
                        images: ["bg1","bg4"],
                        participants: ["Uma", "Victor", "Wendy"],
                        isTimed: true,
                        createdAt: Date(),
                        coordinates: [40.7128, -74.0060],
                        status: "active"
                    ),
                    Event(
                        id: UUID().uuidString,
                        name: "Cooking Class",
                        description: "Learn how to prepare Italian dishes from a professional chef.",
                        type: "Lifestyle",
                        views: "12",
                        location: "La Scuola di Eataly, New York",
                        price: "44",
                        owner: userID,
                        startDate: Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date()) ?? Date(),
                        endDate: Calendar.current.date(byAdding: .day, value: 45, to: Date()) ?? Date(),
                        images: ["bg6","bg7"],
                        participants: ["Xander", "Yara"],
                        isTimed: true,
                        createdAt: Date(),
                        coordinates: [40.7377, -73.9933],
                        status: "active"
                    ),
                    Event(
                        id: UUID().uuidString,
                        name: "Community Cleanup",
                        description: "Join us in cleaning up the neighborhood park.",
                        type: "Environmental",
                        views: "65",
                        location: "Bryant Park, New York",
                        price: "89",
                        owner: userID,
                        startDate: Calendar.current.date(byAdding: .day, value: 45, to: Date()) ?? Date(),
                        endDate: Calendar.current.date(byAdding: .day, value: 45, to: Date()) ?? Date(),
                        images: ["bg3","bg5"],
                        participants: ["Zara", "Alex", "Bella"],
                        isTimed: false,
                        createdAt: Date(),
                        coordinates: [40.7549, -73.9840],
                        status: "active"
                    ),
                    Event(
                        id: UUID().uuidString,
                        name: "Music Festival",
                        description: "An outdoor festival featuring local and international artists.",
                        type: "Entertainment",
                        views: "98",
                        location: "Brooklyn Bowl, New York",
                        price: "5",
                        owner: userID,
                        startDate: Calendar.current.date(byAdding: .day, value: 15, to: Date()) ?? Date(),
                        endDate: Calendar.current.date(byAdding: .day, value: 45, to: Date()) ?? Date(),
                        images: ["bg7","bg1"],
                        participants: ["Chris", "Diane", "Eli"],
                        isTimed: true,
                        createdAt: Date(),
                        coordinates: [40.7110, -73.9573],
                        status: "active"
                    )
                ]
                
                // Add all events with coordinates
                for event in eventsWithCoordinates {
                    addGroup.enter()
                    
                    var eventData = event.toDictionary()
                    let docRef = db.collection("events").document()
                    eventData["id"] = docRef.documentID // Use Firestore's document ID
                    eventData["coordinates"] = event.coordinates // Add coordinates to the dictionary
                    
                    docRef.setData(eventData) { error in
                        if let error = error {
                            print("Error adding event: \(error)")
                        }
                        addGroup.leave()
                    }
                }
                
                // When all events are added, update UI
                addGroup.notify(queue: .main) {
                    isResettingEvents = false
                    print("All events have been reset and repopulated")
                }
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

//struct ProfileView_Previews: PreviewProvider {
//    static var previews: some View {
//        ProfileView()
//    }
//}

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
    @State private var events: [Event] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showError = false
    let segments = ["Upcoming", "Past", "Drafts"]
    @EnvironmentObject private var firebaseManager: FirebaseManager
    
    var filteredEvents: [Event] {
        let now = Date()
        switch selectedSegment {
        case 0: // Upcoming
            return events.filter { $0.startDate > now }
                .sorted { $0.startDate < $1.startDate }
        case 1: // Past
            return events.filter { $0.startDate <= now }
                .sorted { $0.startDate > $1.startDate }
        case 2: // Drafts (if you implement draft functionality)
            return []
        default:
            return []
        }
    }
    
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
            
            if isLoading {
                ProgressView()
                    .scaleEffect(1.2)
                    .frame(maxHeight: .infinity)
            } else if filteredEvents.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.purple, .blue]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("No \(segments[selectedSegment]) Events")
                                .font(.title2)
                                .fontWeight(.bold)
                    
                    Text(selectedSegment == 0 ? "Create an event to get started!" : "Check back later for \(segments[selectedSegment].lowercased()) events.")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxHeight: .infinity)
            } else {
                // Events List
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredEvents) { event in
                            EventCard(event: event)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
        }
        .navigationTitle("My Events")
        .onAppear {
            fetchUserEvents()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }
    
    private func fetchUserEvents() {
        guard let currentUser = firebaseManager.currentUser else {
            errorMessage = "Please sign in to view your events"
            showError = true
            isLoading = false
            return
        }
        
        firebaseManager.fetchUserEvents { result in
            isLoading = false
            switch result {
            case .success(let fetchedEvents):
                events = fetchedEvents
            case .failure(let error):
                errorMessage = error.localizedDescription
                showError = true
            }
        }
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
    @State private var bookmarkedEvents: [Event] = []
    @State private var isLoading = true
    @AppStorage("userID") private var userID: String = ""
    
    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView()
                    .padding()
            } else if bookmarkedEvents.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "bookmark.slash")
                        .font(.system(size: 50))
                                .foregroundColor(.gray)
                    Text("No Bookmarked Events")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Events you bookmark will appear here")
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(bookmarkedEvents) { event in
                        NavigationLink(destination: ViewEventDetail(event: event)) {
                            BookmarkedEventCard(event: event)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Bookmarked Events")
        .onAppear {
            fetchBookmarkedEvents()
        }
    }
    
    private func fetchBookmarkedEvents() {
        isLoading = true
        let db = Firestore.firestore()
        
        guard !userID.isEmpty else {
            isLoading = false
            return
        }
        
        // First get the user's bookmarked event IDs
        db.collection("users").document(userID).getDocument { document, error in
            if let error = error {
                print("Error fetching user document: \(error)")
                isLoading = false
                return
            }
            
            guard let document = document,
                  document.exists,
                  let bookmarkedEventIds = document.get("bookmarkedEvents") as? [String] else {
                isLoading = false
                return
            }
            
            if bookmarkedEventIds.isEmpty {
                isLoading = false
                return
            }
            
            // Create a dispatch group to handle multiple async requests
            let group = DispatchGroup()
            var fetchedEvents: [Event] = []
            
            // Fetch each event document by its ID
            for eventId in bookmarkedEventIds {
                group.enter()
                
                let eventRef = db.collection("events").document(eventId)
                eventRef.getDocument { (document, error) in
                    defer { group.leave() }
                    
                    if let error = error {
                        print("Error fetching event \(eventId): \(error)")
                        return
                    }
                    
                    guard let document = document,
                          document.exists,
                          let data = document.data() else {
                        print("No document found for event \(eventId)")
                        return
                    }
                    
                    guard let name = data["name"] as? String,
                          let description = data["description"] as? String,
                          let type = data["type"] as? String,
                          let location = data["location"] as? String,
                          let price = data["price"] as? String,
                          let owner = data["owner"] as? String,
                          let startDate = (data["startDate"] as? Timestamp)?.dateValue(),
                          let endDate = (data["endDate"] as? Timestamp)?.dateValue(),
                          let images = data["images"] as? [String],
                          let isTimed = data["isTimed"] as? Bool,
                          let coordinates = data["coordinates"] as? [Double] else {
                        print("Invalid event data for \(eventId)")
                        return
                    }
                    
                    let maxParticipants = data["maxParticipants"] as? Int ?? 0
                    let participants = Array(repeating: "Participant", count: maxParticipants)
                    
                    let event = Event(
                        id: document.documentID,
                        name: name,
                        description: description,
                        type: type,
                        views: data["views"] as? String ?? "0",
                        location: location,
                        price: price,
                        owner: owner,
                        startDate: startDate,
                        endDate: endDate,
                        images: images,
                        participants: participants,
                        isTimed: isTimed,
                        createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                        coordinates: coordinates
                    )
                    
                    DispatchQueue.main.async {
                        fetchedEvents.append(event)
                    }
                }
            }
            
            // When all events are fetched, update the UI
            group.notify(queue: .main) {
                self.bookmarkedEvents = fetchedEvents.sorted { $0.startDate < $1.startDate }
                self.isLoading = false
            }
        }
    }
}

struct BookmarkedEventCard: View {
    let event: Event
    
    var body: some View {
        HStack(spacing: 16) {
            // Event Image
            Image(event.images[0])
                .resizable()
                .scaledToFill()
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(event.name)
                    .font(.headline)
                    .foregroundStyle(.linearGradient(colors: [.pink, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                
                Text(event.type)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.gray)
                    Text(formatDate(event.startDate))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
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
    var event: Event
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(event.name)
                    .font(.headline)
                Spacer()
                Text(event.startDate > Date() ? "Upcoming" : "Ongoing")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.2))
                    .foregroundColor(.green)
                    .cornerRadius(4)
            }
            
            Text(formatDate(event.startDate))
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(event.location)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            ZStack {
                if !event.images.isEmpty {
                    Image(event.images[0])
                        .resizable()
                        .scaledToFill()
                }
                LinearGradient(colors: [.black.opacity(0.7), .clear], 
                             startPoint: .bottom, 
                             endPoint: .top)
            }
        )
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "TBD" }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy • h:mm a"
        return dateFormatter.string(from: date)
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

