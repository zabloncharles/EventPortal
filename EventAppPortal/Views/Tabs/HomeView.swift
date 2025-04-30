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
    @State private var currentPage = 1
    @State private var hasMoreResults = false
    private let pageSize = 10
    
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
    @Binding var showlogo: Bool
    
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
        showlogo = true

        do {
            // Single query to fetch all events with appropriate filters
            let eventsQuery = db.collection("events")
                .whereField("status", isEqualTo: "active")
                .order(by: "views", descending: true)
                .limit(to: 20) // Fetch more than needed to cover all sections
            
            let snapshot = try await eventsQuery.getDocuments()
            let allEvents = snapshot.documents.compactMap { document -> Event? in
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
            
            // Process events for different sections
            popularEvents = Array(allEvents.prefix(10))
            nearbyEvents = Array(allEvents
                .filter { $0.startDate > Date() }
                .sorted { $0.startDate < $1.startDate }
                .prefix(5))
            recommendedEvents = Array(allEvents.shuffled().prefix(10))
            
            if !showlogo {
                isLoadingPopular = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isLoadingPopular = false
                showlogo = false
            }
            isLoadingNearby = false
            isLoadingRecommended = false
        } catch {
            print("Error fetching events: \(error.localizedDescription)")
            errorMessage = "Failed to load events"
            isLoadingPopular = false
            isLoadingNearby = false
            isLoadingRecommended = false
        }
    }
    
    // Search events in Firestore with pagination
    private func searchEvents(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            isSearching = false
            currentPage = 1
            hasMoreResults = false
            return
        }
        
        isSearching = true
        let db = Firestore.firestore()
        
        // Create array of keywords from the search query
        let keywords = query.lowercased().split(separator: " ").map(String.init)
        
        // Build the query with proper pagination
        var searchQuery = db.collection("events")
            .whereField("status", isEqualTo: "active")
            .limit(to: pageSize)
        
        // If not first page, use startAfter for pagination
        if currentPage > 1, let lastDocument = searchResults.last {
            searchQuery = searchQuery.start(after: [lastDocument.name, lastDocument.startDate])
        }
        
        // Execute the query
        searchQuery.getDocuments { snapshot, error in
            if let error = error {
                print("Error searching events: \(error.localizedDescription)")
                self.errorMessage = "Failed to search events"
                self.isSearching = false
                return
            }
            
            guard let snapshot = snapshot else {
                self.isSearching = false
                return
            }
            
            // Process results
            let newResults = snapshot.documents.compactMap { document -> Event? in
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
            
            // Update results
            if currentPage == 1 {
                self.searchResults = newResults
            } else {
                self.searchResults.append(contentsOf: newResults)
            }
            
            // Update pagination state
            self.hasMoreResults = newResults.count == self.pageSize
            self.isSearching = false
        }
    }
    
    private func loadMoreResults() {
        currentPage += 1
        searchEvents(query: searchText)
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
            let _ = userData["location"] as? GeoPoint
            
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
            Image("hmm")
                .resizable()
                .renderingMode(.original)
                .aspectRatio(contentMode: .fit)
                .frame(height:200)
            
              
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .padding(.top,50)
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
                            gradient: Gradient(colors: [Color.invert, .yellow, Color.purple]),
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
                        .font(.system(size: 26, weight: .medium))
                        .frame(width: 36, height: 36)
                        .shadow(radius: 0.5)
                }
                
                NavigationLink(destination: NotificationView()) {
                    Image(systemName: "calendar")
                        .renderingMode(.original)
                        .font(.system(size: 26, weight: .medium))
                        .frame(width: 25, height: 36)
                        .shadow(radius: 0.5)
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
                        .background(Color.dynamic)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.30), lineWidth: 1)
                        )
                        .onChange(of: searchText) { query in
                            searchEvents(query: query)
                        }
                    
                   
                }.overlay(alignment:.trailing, content: {
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            searchResults = []
                            isSearching = false
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                                .padding(.trailing)
                        }
                    }
                })
                .padding(.vertical,10)
                .padding(.top, 0)
            }
            .padding(.horizontal)
        }
    }

    private var searchList: some View {
        VStack {
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
                        }
                    }
                } else {
                    EmptyStateView(
                        title: "No Events Available",
                        message: "Check back later for new events"
                    )
                }
            }
        }
    }

    // MARK: - Search Results Section
    private var searchResultsSection: some View {
        VStack {
            if !searchText.isEmpty {
                if isSearching {
                    ProgressView()
                        .padding()
                } else if searchResults.isEmpty {
                    EmptyStateView(
                        title: "No Results Found",
                        message: "Try searching with different keywords"
                    )
                } else {
                    VStack {
                        HStack {
                            Text("Results (\(searchResults.count))")
                                .foregroundColor(.gray)
                                .font(.headline)
                            Spacer()
                        }.padding(.horizontal)
                        
                        LazyVStack(spacing: 16) {
                            ForEach(searchResults) { event in
                                NavigationLink(destination: ViewEventDetail(event: event)) {
                                    PopularEventCard(event: event)
                                }
                            }
                            
                            if hasMoreResults {
                                Button(action: loadMoreResults) {
                                    HStack {
                                        Text("View More")
                                            .font(.headline)
                                            .foregroundColor(.blue)
                                        Image(systemName: "chevron.down")
                                            .foregroundColor(.blue)
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(10)
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.leading)
                        .padding(.trailing, 10)
                    }
                }
            }
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
             
                    LazyVStack(spacing: 16) {
                        ForEach(popularEvents.prefix(5)) { event in
                            NavigationLink(destination: ViewEventDetail(event: event)) {
                                PopularEventCard(event: event)
                                   
                            }
                        }
                    }.padding(.leading)
                        .padding(.trailing, 10)
                
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
        VStack(alignment: .leading, spacing: 0) {
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
                                .frame(width: UIScreen.main.bounds.width - 32, height: 135)
                                .padding(.horizontal)
                        }
                    }.padding(.top, 10)
                
               
              
               
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
                        if !isLoading {
                            if searchText.isEmpty {
                                searchList
                            }
                            searchResultsSection
                            
                            if searchText.isEmpty {
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
                            }
                            Spacer()
                        }
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
                VStack(alignment: .leading) {
                    HStack {
                        if event.endDate == Date.distantFuture {
                            Text("Ongoing")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("Event")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                        } else {
                            Text(returnMonthOrDay(from: event.startDate, getDayNumber: false).capitalized)
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Text(returnMonthOrDay(from: event.startDate, getDayNumber: true))
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                        }
                        Spacer()
                    }
                    .padding(.top, 0)
                    Spacer()
                    HStack {
                        Group{
                            Image(systemName: "map")
                            Text(event.location.components(separatedBy: ",")[0])
                                .multilineTextAlignment(.leading)
                                .lineLimit(2)
                        } .font(.subheadline)
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.white]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        Spacer()
                    }
                }
                .padding()
            }
            .background(
                CompactImageViewer(imageUrls: event.images, scroll: false)
            )
            .cornerRadius(16)
            
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(event.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.purple, Color.randomizetextcolor]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        Spacer()
                        Text("\(Int((Double(event.views) ?? 0).rounded())) \(Int(event.views) ?? 0 > 1 ? "Views" : "View")")
                            .font(.footnote)
                            .padding(.horizontal,6)
                            .padding(.vertical, 3)
                            .background(Color.randomizetextcolor)
                            .cornerRadius(10)
                            .foregroundColor(.dynamic)
                    }
                    Text(event.description)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .foregroundColor(.gray)
                        .font(.subheadline)
                }
                .multilineTextAlignment(.leading)
            }
            .padding(.horizontal, 5)
        }
        .frame(height:250)
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
                CompactImageViewer(imageUrls: event.images, scroll: false)
                    .overlay(
                        LinearGradient(colors: [.black, .black.opacity(0.40), .black.opacity(0.60)], 
                                     startPoint: .bottomLeading, 
                                     endPoint: .topTrailing)
                    )
                
                ZStack {
                    VStack(alignment: .leading) {
                        HStack {
                            if event.endDate == Date.distantFuture {
                                Text("Ongoing")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text("Event")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)
                            } else {
                                Text(returnMonthOrDay(from: event.startDate, getDayNumber: false).capitalized)
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                Text(returnMonthOrDay(from: event.startDate, getDayNumber: true))
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
                            }
                            .multilineTextAlignment(.trailing)
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
                                }
                                .padding(.trailing)
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
        }
        .frame(height: 200)
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
       // HomeView(showlogo: .constant(false))
        ScrollView{
            LazyVStack(spacing: 16) {
                ForEach(sampleEvents) { event in
                    NavigationLink(destination: ViewEventDetail(event: event)) {
                        PopularEventCard(event: event)
                        
                    }
                }
            }.padding(.leading)
                .padding(.trailing, 10)
        }.preferredColorScheme(.dark)
    }
}

