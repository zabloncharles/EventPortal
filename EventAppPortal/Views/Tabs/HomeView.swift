import SwiftUI
import Firebase

struct HomeView: View {
    @State private var searchText = ""
    @State private var pageAppeared = false
    @State private var startPoint: UnitPoint = .leading
    @State private var endPoint: UnitPoint = .trailing
    @State private var searchResults: [Event] = []
    @State private var isSearching = false
    @State private var hasLoadedInitialContent = false
    @State private var hasAnimated = false
    
    // Firebase state
    @State private var popularEvents: [Event] = []
    @State private var nearbyEvents: [Event] = []
    @State private var recommendedEvents: [Event] = []
    @State private var recommendedGroups: [EventGroup] = []
    @State private var isLoadingPopular = true
    @State private var isLoadingNearby = true
    @State private var isLoadingRecommended = true
    @State private var isLoadingGroups = true
    @State private var errorMessage: String?
    @EnvironmentObject private var firebaseManager: FirebaseManager
    
    private var isLoading: Bool {
        isLoadingPopular || isLoadingNearby || isLoadingRecommended || isLoadingGroups
    }
    
    // Fetch events from Firestore
    private func fetchEvents() async {
        let db = Firestore.firestore()
        
        // Reset loading states
        isLoadingPopular = true
        isLoadingNearby = true
        isLoadingRecommended = true
        isLoadingGroups = true
        errorMessage = nil
        
        // Fetch popular events (sorted by views)
        do {
            let popularSnapshot = try await db.collection("events")
                .whereField("status", isEqualTo: "active")
                .order(by: "views", descending: true)
                .limit(to: 10)
                .getDocuments()
            
            popularEvents = popularSnapshot.documents.compactMap { document -> Event? in
                let data = document.data()
                guard let id = data["id"] as? String,let name = data["name"] as? String,
                      let description = data["description"] as? String,
                      let type = data["type"] as? String,
                      let location = data["location"] as? String,
                      let price = data["price"] as? String,
                      let owner = data["owner"] as? String,
                      let startDate = (data["startDate"] as? Timestamp)?.dateValue(),
                      let endDate = (data["endDate"] as? Timestamp)?.dateValue(),
                      let images = data["images"] as? [String],
                      let isTimed = data["isTimed"] as? Bool,
                      let coordinates = data["coordinates"] as? [Double]
                else { return nil }
                
                let maxParticipants = data["maxParticipants"] as? Int ?? 100
                let participants = Array(repeating: "Participant", count: maxParticipants)
                
                return Event(
                    id: id,
                    name: name,
                    description: description,
                    type: type,
                    views: data["views"] as? String ?? "0",
                    location: location,
                    price: price,
                    owner: owner,
                    organizerName: data["organizerName"] as? String ?? owner,
                    shareContactInfo: data["shareContactInfo"] as? Bool ?? false,
                    startDate: startDate,
                    endDate: endDate,
                    images: images,
                    participants: participants,
                    maxParticipants: maxParticipants,
                    isTimed: isTimed,
                    createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                    coordinates: coordinates,
                    status: data["status"] as? String ?? "active"
                )
            }
            isLoadingPopular = false
        } catch {
            print("Error fetching popular events: \(error.localizedDescription)")
            errorMessage = "Failed to load popular events"
            isLoadingPopular = false
        }
        
        // Fetch nearby events
        do {
            let nearbySnapshot = try await db.collection("events")
                .whereField("status", isEqualTo: "active")
                .order(by: "startDate")
                .limit(to: 5)
                .getDocuments()
            
            nearbyEvents = nearbySnapshot.documents.compactMap { document -> Event? in
                let data = document.data()
                guard let id = data["id"] as? String,
                      let name = data["name"] as? String,
                      let description = data["description"] as? String,
                      let type = data["type"] as? String,
                      let location = data["location"] as? String,
                      let price = data["price"] as? String,
                      let owner = data["owner"] as? String,
                      let startDate = (data["startDate"] as? Timestamp)?.dateValue(),
                      let endDate = (data["endDate"] as? Timestamp)?.dateValue(),
                      let images = data["images"] as? [String],
                      let isTimed = data["isTimed"] as? Bool,
                      let coordinates = data["coordinates"] as? [Double]
                else { return nil }
                
                let maxParticipants = data["maxParticipants"] as? Int ?? 100
                let participants = Array(repeating: "Participant", count: maxParticipants)
                
                return Event(
                    id: id,
                    name: name,
                    description: description,
                    type: type,
                    views: data["views"] as? String ?? "0",
                    location: location,
                    price: price,
                    owner: owner,
                    organizerName: data["organizerName"] as? String ?? owner,
                    shareContactInfo: data["shareContactInfo"] as? Bool ?? false,
                    startDate: startDate,
                    endDate: endDate,
                    images: images,
                    participants: participants,
                    maxParticipants: maxParticipants,
                    isTimed: isTimed,
                    createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                    coordinates: coordinates,
                    status: data["status"] as? String ?? "active"
                )
            }
            .filter { $0.startDate > Date() }
            .sorted { $0.startDate < $1.startDate }
            
            isLoadingNearby = false
        } catch {
            print("Error fetching nearby events: \(error.localizedDescription)")
            errorMessage = "Failed to load nearby events"
            isLoadingNearby = false
        }
        
        // Fetch recommended events
        do {
            let recommendedSnapshot = try await db.collection("events")
                .whereField("status", isEqualTo: "active")
                .limit(to: 10)
                .getDocuments()
            
            recommendedEvents = recommendedSnapshot.documents.compactMap { document -> Event? in
                let data = document.data()
                guard let id = data["id"] as? String,
                      let name = data["name"] as? String,
                      let description = data["description"] as? String,
                      let type = data["type"] as? String,
                      let location = data["location"] as? String,
                      let price = data["price"] as? String,
                      let owner = data["owner"] as? String,
                      let startDate = (data["startDate"] as? Timestamp)?.dateValue(),
                      let endDate = (data["endDate"] as? Timestamp)?.dateValue(),
                      let images = data["images"] as? [String],
                      let isTimed = data["isTimed"] as? Bool,
                      let coordinates = data["coordinates"] as? [Double]
                else { return nil }
                
                let maxParticipants = data["maxParticipants"] as? Int ?? 100
                let participants = Array(repeating: "Participant", count: maxParticipants)
                
                return Event(
                    id: id,
                    name: name,
                    description: description,
                    type: type,
                    views: data["views"] as? String ?? "0",
                    location: location,
                    price: price,
                    owner: owner,
                    organizerName: data["organizerName"] as? String ?? owner,
                    shareContactInfo: data["shareContactInfo"] as? Bool ?? false,
                    startDate: startDate,
                    endDate: endDate,
                    images: images,
                    participants: participants,
                    maxParticipants: maxParticipants,
                    isTimed: isTimed,
                    createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                    coordinates: coordinates,
                    status: data["status"] as? String ?? "active"
                )
            }
            isLoadingRecommended = false
        } catch {
            print("Error fetching recommended events: \(error.localizedDescription)")
            errorMessage = "Failed to load recommended events"
            isLoadingRecommended = false
        }
    }
    
    // Search events in Firestore
    private func searchEvents(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        let db = Firestore.firestore()
        
        // Create array of keywords from the search query
        let keywords = query.lowercased().split(separator: " ").map(String.init)
        
        // Search in events collection
        db.collection("events")
            .whereField("status", isEqualTo: "active")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error searching events: \(error.localizedDescription)")
                    errorMessage = "Failed to search events"
                    isSearching = false
                    return
                }
                
                // Filter and sort results based on relevance
                searchResults = snapshot?.documents.compactMap { document -> (Event, Int)? in
                    let data = document.data()
                    guard let id = data["id"] as? String,
                          let name = data["name"] as? String,
                          let description = data["description"] as? String,
                          let type = data["type"] as? String,
                          let location = data["location"] as? String,
                          let price = data["price"] as? String,
                          let owner = data["owner"] as? String,
                          let startDate = (data["startDate"] as? Timestamp)?.dateValue(),
                          let endDate = (data["endDate"] as? Timestamp)?.dateValue(),
                          let images = data["images"] as? [String],
                          let isTimed = data["isTimed"] as? Bool,
                          let coordinates = data["coordinates"] as? [Double]
                    else { return nil }
                    
                    // Calculate relevance score
                    let searchableText = "\(name) \(description) \(type) \(location)".lowercased()
                    let relevanceScore = keywords.reduce(0) { score, keyword in
                        score + (searchableText.contains(keyword) ? 1 : 0)
                    }
                    
                    // Only include results that match at least one keyword
                    guard relevanceScore > 0 else { return nil }
                    
                    let maxParticipants = data["maxParticipants"] as? Int ?? 100
                    let participants = Array(repeating: "Participant", count: maxParticipants)
                    
                    let event = Event(
                        id: id,
                        name: name,
                        description: description,
                        type: type,
                        views: data["views"] as? String ?? "0",
                        location: location,
                        price: price,
                        owner: owner,
                        organizerName: data["organizerName"] as? String ?? owner,
                        shareContactInfo: data["shareContactInfo"] as? Bool ?? false,
                        startDate: startDate,
                        endDate: endDate,
                        images: images,
                        participants: participants,
                        maxParticipants: maxParticipants,
                        isTimed: isTimed,
                        createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                        coordinates: coordinates,
                        status: data["status"] as? String ?? "active"
                    )
                    
                    return (event, relevanceScore)
                }
                .sorted { $0.1 > $1.1 } // Sort by relevance score
                .map { $0.0 } // Extract just the events
                ?? []
                
                isSearching = false
            }
    }
    
    // Add this function to fetch recommended groups
    private func fetchRecommendedGroups() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        do {
            // Get user's interests and location from their profile
            let userDoc = try await db.collection("users").document(userId).getDocument()
            let userData = userDoc.data() ?? [:]
            let userInterests = userData["interests"] as? [String] ?? []
            let userLocation = userData["location"] as? GeoPoint
            
            // Query groups based on user's interests and location
            var query = db.collection("groups")
                .whereField("isPrivate", isEqualTo: false)
                .limit(to: 10)
            
            // If user has interests, prioritize groups with matching categories
            if !userInterests.isEmpty {
                query = query.whereField("category", in: userInterests)
            }
            
            let snapshot = try await query.getDocuments()
            var groups = snapshot.documents.compactMap { document in
                EventGroup.fromFirestore(document)
            }
            
            // Sort groups by relevance (you can implement your own sorting logic)
            groups.sort { group1, group2 in
                // Example sorting: prioritize groups with more members
                return group1.memberCount > group2.memberCount
            }
            
            // Update the UI on the main thread
            await MainActor.run {
                self.recommendedGroups = groups
                self.isLoadingGroups = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to fetch recommended groups: \(error.localizedDescription)"
                self.isLoadingGroups = false
            }
        }
    }
    
    private func EmptyStateView(title: String, message: String) -> some View {
        VStack(alignment: .center, spacing: 10) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    private func SectionLoadingView() -> some View {
        HStack {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack {
            HStack {
                Text("LinkedUp Event Expectations.")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top, 20)
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.invert, .randomizetextcolor, Color.invert]),
                            startPoint: startPoint,
                            endPoint: endPoint
                        )
                    )
                    .onAppear {
                        if !hasAnimated {
                            withAnimation(.linear(duration: 2)) {
                                startPoint = .trailing
                                endPoint = .leading
                            }
                            hasAnimated = true
                        }
                    }
                
                Spacer()
                
                NavigationLink(destination: CreateView()) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .medium))
                        .frame(width: 36, height: 36)
                        .background(Color.dynamic)
                        .cornerRadius(60)
                        .overlay(
                            RoundedRectangle(cornerRadius: 60)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                }
                
                NavigationLink(destination: NotificationView()) {
                    Image(systemName: "calendar")
                        .renderingMode(.original)
                        .font(.system(size: 16, weight: .medium))
                        .frame(width: 36, height: 36)
                        .background(Color.dynamic)
                        .cornerRadius(60)
                        .overlay(
                            RoundedRectangle(cornerRadius: 60)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Search Section
    private var searchSection: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .blur(radius: 570)
            
            VStack {
                HStack {
                    TextField("Search event, party...", text: $searchText)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.dynamic, lineWidth: 2)
                        )
                        .onChange(of: searchText) { query in
                            if !query.isEmpty {
                                searchEvents(query: query)
                            } else {
                                searchResults = []
                                isSearching = false
                            }
                        }
                }
                .padding(10)
                .padding(.top, 0)
                
                if searchText.isEmpty {
                    if isLoadingRecommended {
                        ProgressView()
                            .padding()
                    } else if !recommendedEvents.isEmpty {
                        ForEach(recommendedEvents.shuffled().prefix(3)) { event in
                            NavigationLink(destination: ViewEventDetail(event: event)) {
                                VStack {
                                    Divider()
                                    HStack {
                                        Image(systemName: {
                                            switch event.type {
                                            case "Concert": return "figure.dance"
                                            case "Corporate": return "building.2.fill"
                                            case "Marketing": return "megaphone.fill"
                                            case "Health & Wellness": return "heart.fill"
                                            case "Technology": return "desktopcomputer"
                                            case "Art & Culture": return "paintbrush.fill"
                                            case "Charity": return  "heart.circle.fill"
                                            case "Literature": return "book.fill"
                                            case "Lifestyle": return "leaf.fill"
                                            case "Environmental": return "leaf.arrow.triangle.circlepath"
                                            case "Entertainment": return "music.note.list"
                                            default: return "calendar"
                                            }
                                        }())
                                            .foregroundColor(.gray)
                                        Text(event.name)
                                            .font(.callout)
                                            .foregroundColor(.primary)
                                        Spacer()
                                    }
                                    .padding(.vertical, 7)
                                    .padding(.horizontal, 10)
                                    .cornerRadius(9)
                                    .padding(.horizontal)
                                }
                                .animation(.spring(), value: searchText.isEmpty)
                            }
                        }
                    }
                }
                Spacer()
               
            }.padding(.horizontal)
        }
    }

    // MARK: - Popular Events Section
    private var popularEventsSection: some View {
        VStack {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading) {
                    Text("Popular Events")
                        .font(.headline)
                    Text("Trending events in your area")
                        .font(.callout)
                }
                .padding(.top, 30)
                Spacer()
                VStack(alignment: .center) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                }
            }
            .padding(.horizontal)
            if isLoadingPopular {
                SectionLoadingView()
            } else if popularEvents.isEmpty {
                EmptyStateView(
                    title: "No Popular Events",
                    message: "Be the first to create an exciting event!"
                )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 16) {
                        ForEach(popularEvents) { event in
                            NavigationLink(destination: ViewEventDetail(event: event)) {
                                PopularEventCard(event: event)
                                    .frame(width: 280)
                            }
                        }
                    }.padding(.leading)
                        .padding(.trailing, 10)
                }
            }
        }
    }

    // MARK: - Nearby Events Section
    private var nearbyEventsSection: some View {
        VStack {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading) {
                    Text("Nearby Events")
                        .font(.headline)
                    Text("Events happening close to you")
                        .font(.callout)
                }
                .padding(.top, 30)
                Spacer()
                VStack(alignment: .center) {
                    Image(systemName: "location.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            if isLoadingNearby {
                SectionLoadingView()
            } else if nearbyEvents.isEmpty {
                VStack {
                    EmptyStateView(
                        title: "No Nearby Events",
                        message: "There are no upcoming events in your area yet."
                    )
                }
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 16) {
                        ForEach(nearbyEvents) { event in
                            NavigationLink(destination: ViewEventDetail(event: event)) {
                                RegularEventCard(event: event, showdescription: false)
                            }
                        }
                    }.padding(.horizontal)
                }
            }
        }
        .padding(.bottom)
    }

    // MARK: - Recommended Events Section
    private var recommendedEventsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading) {
                    Text("Recommended Events")
                        .font(.headline)
                    Text("Events you might like")
                        .font(.callout)
                }
                .padding(.top, 30)
                Spacer()
                VStack(alignment: .center) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                }
            }
            .padding(.horizontal)
            
            if isLoadingRecommended {
                SectionLoadingView()
            } else if recommendedEvents.isEmpty {
                EmptyStateView(
                    title: "No Recommendations",
                    message: "Check back later for personalized event recommendations!"
                )
            } else {
              
                ForEach(recommendedEvents.prefix(3)) { event in
                        NavigationLink(destination: ViewEventDetail(event: event)) {
                            EventListItem(event: event, isSelected: false, userLocation: nil)
                                .frame(width: UIScreen.main.bounds.width - 32, height: 160)
                                .padding(.horizontal)
                        }
                    }
                
               
              
               
            }
        }
    }

    // MARK: - Recommended Groups Section
    private var recommendedGroupsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading) {
                    Text("Recommended Groups")
                        .font(.headline)
                    Text("Groups that match your interests")
                        .font(.callout)
                }
                .padding(.top, 30)
                Spacer()
                VStack(alignment: .center) {
                    Image(systemName: "person.3.fill")
                        .foregroundColor(.green)
                }
            }
            .padding(.horizontal)
            
            if isLoadingGroups {
                SectionLoadingView()
            } else if recommendedGroups.isEmpty {
                EmptyStateView(
                    title: "No Recommended Groups",
                    message: "Join groups to get personalized recommendations!"
                )
            } else {
                
                ForEach(recommendedGroups.prefix(3)) { group in
                        GroupCard(group: group)
                           
                    }
                
            }
        }
        .padding(.bottom, 70)
    }

    var body: some View {
        NavigationView {
            ScrollableNavigationBar(
                title: "Home",
                icon: "house.fill"
                
            ) {
                VStack(alignment: .leading, spacing: 30) {
                    VStack {
                        headerSection
                        searchSection
                        if !popularEvents.isEmpty {
                            popularEventsSection
                        }
                        if !nearbyEvents.isEmpty {
                            nearbyEventsSection
                        }
                        if !recommendedEvents.isEmpty {
                            recommendedEventsSection
                        }
                        if !recommendedGroups.isEmpty {
                            recommendedGroupsSection
                        }
                        Spacer()
                    }
                    
                }
                .padding(.bottom,50).padding(.top,50)
            }
            .background(Color.dynamic)
            .onAppear {
                if !hasLoadedInitialContent {
                    withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
                        pageAppeared = true
                    }
                    
                    Task {
                        await fetchEvents()
                        await fetchRecommendedGroups()
                        hasLoadedInitialContent = true
                    }
                }
            }
            .refreshable {
                isLoadingPopular = true
                isLoadingNearby = true
                isLoadingRecommended = true
                isLoadingGroups = true
                await fetchEvents()
                await fetchRecommendedGroups()
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            }message: {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }
    
    struct ErrorWrapper: Identifiable {
        let id = UUID()
        let error: String
    }
}

struct PopularEventCard: View {
    var event: Event = sampleEvent
    let colors: [Color] = [.red, .blue, .green, .orange]
    
    var body: some View {
        VStack {
            ZStack {
                // Replace single image with CompactImageViewer
                CompactImageViewer(imageUrls: event.images, height: 180)
                    .overlay(
                        LinearGradient(colors: [.black, .clear], 
                                     startPoint: .bottomLeading, 
                                     endPoint: .topTrailing)
                    )
                
                ZStack {
                    VStack(alignment: .leading) {
                        HStack {
                            if event.endDate == nil {
                                Text("Ongoing")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text("Event")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)
                            } else {
                                Text(returnMonthOrDay(from: event.startDate ?? Date(), getDayNumber: false).capitalized)
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                Text(returnMonthOrDay(from: event.startDate ?? Date(), getDayNumber: true))
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.top, 10)
                        Spacer()
                        
                        HStack(alignment: .bottom) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(event.name)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.clear)
                                    .overlay(
                                        LinearGradient(
                                            gradient: Gradient(colors: [colors.randomElement() ?? .blue, .purple]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                        .mask(
                                            Text(event.name)
                                                .font(.title2)
                                                .fontWeight(.bold)
                                        )
                                    )
                                Text(event.location.components(separatedBy: ",")[0])
                            }
                            .multilineTextAlignment(.leading)
                            Spacer()
                            VStack {
                                ZStack {
                                    ForEach(0..<colors.count, id: \.self) { index in
                                        Circle()
                                            .fill(colors[index])
                                            .frame(width: 15, height: 15)
                                            .offset(x: CGFloat(index * 10 - 0))
                                    }
                                }.padding(.trailing)
                                Text("\(Int((Double(event.views) ?? 0).rounded())) \(Int(event.views) ?? 0 > 1 ? "Views" : "View")")
                                    .font(.footnote)
                            }
                        }
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    }
                    .padding()
                }
            }
            .background(
                Image(event.images[0])
                    .resizable()
                    .scaledToFill()
            )
            .cornerRadius(20)
        }
    }
    
    func returnMonthOrDay(from date: Date, getDayNumber: Bool) -> String {
        let calendar = Calendar.current
        if getDayNumber {
            let day = calendar.component(.day, from: date)
            return "\(day)"
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM"
            return dateFormatter.string(from: date)
        }
    }
}

struct RegularEventCard: View {
    var event: Event = sampleEvent
    var showdescription = true
    let colors: [Color] = [.red, .blue, .green, .orange]
    
    var body: some View {
        VStack {
            ZStack {
                // Replace single image with CompactImageViewer
                CompactImageViewer(imageUrls: event.images, height: 200, scroll: false)
                    .overlay(
                        LinearGradient(colors: [.black, .black.opacity(0.40), .black.opacity(0.60)], 
                                     startPoint: .bottomLeading, 
                                     endPoint: .topTrailing)
                    )
                
                ZStack {
                    VStack(alignment: .leading) {
                        HStack {
                            if event.endDate == nil {
                                Text("Ongoing")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text("Event")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)
                            } else {
                                Text(returnMonthOrDay(from: event.startDate ?? Date(), getDayNumber: false).capitalized)
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                Text(returnMonthOrDay(from: event.startDate ?? Date(), getDayNumber: true))
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.top, 10)
                        
                        Spacer()
                        HStack(alignment: .bottom) {
                            Spacer()
                            VStack(alignment: .leading, spacing: 3) {
                                    Text(event.description.split(separator: ".")[0] + ".")
                                        .font(.callout)
                                        .foregroundColor(.white)
                                        .padding(.leading)
                                        .lineLimit(2)
                                    .opacity(showdescription ? 1 : 0)
                                
                            }.multilineTextAlignment(.trailing)
                        }
                        HStack(alignment: .bottom) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(event.name)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.clear)
                                    .overlay(
                                        LinearGradient(
                                            gradient: Gradient(colors: [colors.randomElement() ?? .blue, .purple]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                        .mask(
                                            Text(event.name)
                                                .font(.title2)
                                                .fontWeight(.bold)
                                        )
                                    )
                                Text(event.location.components(separatedBy: ",")[0])
                            }.multilineTextAlignment(.leading)
                            Spacer()
                            VStack {
                                ZStack {
                                    ForEach(0..<colors.count, id: \.self) { index in
                                        Circle()
                                            .fill(colors[index])
                                            .frame(width: 15, height: 15)
                                            .offset(x: CGFloat(index * 10 - 0))
                                    }
                                }.padding(.trailing)
                                Text("\(Int((Double(event.views) ?? 0).rounded())) \(Int(event.views) ?? 0 > 1 ? "Views" : "View")")
                                    .font(.footnote)
                            }
                        }
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    }
                    .padding()
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.dynamic.opacity(0.20), lineWidth: 1)
            )
            .cornerRadius(20)
        }.frame(height: 200)
        
    }
    
    func returnMonthOrDay(from date: Date, getDayNumber: Bool) -> String {
        let calendar = Calendar.current
        if getDayNumber {
            let day = calendar.component(.day, from: date)
            return "\(day)"
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM"
            return dateFormatter.string(from: date)
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}

