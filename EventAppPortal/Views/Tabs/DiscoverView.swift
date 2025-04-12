import SwiftUI
import FirebaseFirestore
import MapKit

enum FilterType: String, CaseIterable, Identifiable {
    case all = "All"
    case concert = "Concert"
    case corporate = "Corporate"
    case marketing = "Marketing"
    case healthWellness = "Health & Wellness"
    case technology = "Technology"
    case artCulture = "Art & Culture"
    case charity = "Charity"
    case literature = "Literature"
    case lifestyle = "Lifestyle"
    case environmental = "Environmental"
    case entertainment = "Entertainment"
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .all: return "square.grid.2x2.fill"
        case .concert: return "figure.dance"
        case .corporate: return "building.2.fill"
        case .marketing: return "megaphone.fill"
        case .healthWellness: return "heart.fill"
        case .technology: return "desktopcomputer"
        case .artCulture: return "paintbrush.fill"
        case .charity: return "heart.circle.fill"
        case .literature: return "book.fill"
        case .lifestyle: return "leaf.fill"
        case .environmental: return "leaf.arrow.triangle.circlepath"
        case .entertainment: return "music.note.list"
        }
    }
}

class FilterModel: ObservableObject {
    @Published var filteredEvents: [Event] = []
    @Published var activeFilters: EventFilters = EventFilters()
    private var allEvents: [Event] = [] // Store all events
    
    func applyFilters(filters: EventFilters) {
        print("Applying filters: \(filters)")
        print("Total events before filtering: \(allEvents.count)")
        
        // Start with all events
        var filtered = allEvents
        
        // Apply type filter
        if filters.selectedType != "All" {
            print("Filtering by type: \(filters.selectedType)")
            filtered = filtered.filter { event in
                let matches = event.type == filters.selectedType
                if !matches {
                    print("Event '\(event.name)' filtered out due to type mismatch: \(event.type) != \(filters.selectedType)")
                }
                return matches
            }
            print("After type filter: \(filtered.count) events")
        }
        
        // Only apply other filters if we have events after type filtering
        if !filtered.isEmpty {
            // Apply location filter
            if filters.selectedLocation != "All" {
                filtered = filtered.filter { $0.location == filters.selectedLocation }
                print("After location filter: \(filtered.count) events")
            }
            
            // Apply price range filter
            filtered = filtered.filter { event in
                if event.price.lowercased() == "free" {
                    return true
                }
                if let price = Double(event.price) {
                    let isInRange = price >= filters.priceRange.lowerBound && price <= filters.priceRange.upperBound
                    if !isInRange {
                        print("Event '\(event.name)' filtered out due to price: \(price) not in range \(filters.priceRange)")
                    }
                    return isInRange
                }
                print("Event '\(event.name)' filtered out due to invalid price format: \(event.price)")
                return false
            }
            print("After price filter: \(filtered.count) events")
            
            // Apply date range filter
            filtered = filtered.filter { event in
                let eventStartsBeforeFilterEnds = event.startDate <= filters.endDate
                let eventEndsAfterFilterStarts = event.endDate >= filters.startDate
                let isInRange = eventStartsBeforeFilterEnds && eventEndsAfterFilterStarts
                
                if !isInRange {
                    print("Event '\(event.name)' filtered out due to date range")
                }
                return isInRange
            }
            print("After date filter: \(filtered.count) events")
            
            // Apply timed events filter
            if filters.showTimedEventsOnly {
                filtered = filtered.filter { $0.isTimed }
                print("After timed events filter: \(filtered.count) events")
            }
            
            // Apply participants filter
            if filters.minParticipants > 0 {
                filtered = filtered.filter { $0.participants.count >= filters.minParticipants }
                print("After participants filter: \(filtered.count) events")
            }
        }
        
        filteredEvents = filtered
        print("Final filtered events count: \(filteredEvents.count)")
        
        // Print details of remaining events
        if filteredEvents.isEmpty {
            print("No events remain after filtering. Original events:")
            for event in allEvents {
                print("- \(event.name): Type=\(event.type), Location=\(event.location), Price=\(event.price)")
            }
        }
    }
    
    // Update this method to store all events
    func updateEvents(_ events: [Event]) {
        allEvents = events
        filteredEvents = events
    }
}

struct EventFilters {
    var searchText: String = ""
    var selectedType: String = "All"
    var selectedLocation: String = "All"
    var priceRange: ClosedRange<Double> = 0...1000
    var startDate: Date = Date()
    var endDate: Date = Date().addingTimeInterval(30*24*60*60)
    var showTimedEventsOnly: Bool = false
    var minParticipants: Int = 0
}

struct DiscoverView: View {
    @StateObject private var filterModel = FilterModel()
    @State private var searchText = ""
    @State private var selectedLocation = "Lombok, Indonesia"
    @State private var selectedFilter: FilterType = .all
    @State private var showSearchView = false
    @State private var showFilterSheet = false
    @State private var showDatePicker = false
    @State private var showPriceFilter = false
    @State private var showCategoryFilter = false
    @State private var selectedDate: Date = Date()
    @State private var selectedDateFilter: DateFilter = .all
    @State private var selectedPriceRange: ClosedRange<Double> = 0...1000
    @State private var selectedCategory: String?
    @State private var filteredEvents: [Event] = []
    @State private var isSearching = false
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showLocationSettings = false
    @StateObject private var locationManager = LocationManager()
    @AppStorage("userID") private var userID: String = ""
    @State private var pageAppeared = false
    @State private var viewMode: ViewMode = .map
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var clickedEvent = false
    @State private var clickedData: Event?
    @State private var topbarPressed = false
    @FocusState private var searching: Bool
    @AppStorage("hideTab") private var hideTab = false
    @State private var bottomSheetPosition: BottomSheetPosition = .middle
    @State private var dragOffset: CGFloat = 0
    @State private var nearestEvents: [Event] = []
    
    enum ViewMode {
        case list
        case map
    }
    
    enum BottomSheetPosition: CGFloat {
        case bottom = 100
        case middle = 400
        case top = 700
        
        func nextPosition(dragDirection: DragDirection) -> BottomSheetPosition {
            switch (self, dragDirection) {
            case (.bottom, .up): return .middle
            case (.middle, .up): return .top
            case (.middle, .down): return .bottom
            case (.top, .down): return .middle
            default: return self
            }
        }
    }
    
    enum DragDirection {
        case up, down
    }
    
    // Add computed property for displayed events
    private var displayedEvents: [Event] {
        if searchText.isEmpty {
            // Show top 3 most viewed events
            return filterModel.filteredEvents
                .sorted { 
                    let views1 = Int($0.views) ?? 0
                    let views2 = Int($1.views) ?? 0
                    return views1 > views2 
                }
                .prefix(3)
                .map { $0 }
        } else {
            // Show search results
            return filteredEvents
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Map Background
                mainMapView
                    .offset(y: -180)
                
                // Top Bar
                topBar
                
                // Bottom Sheet with Closest Events
                if !showSearchView {
                    VStack(spacing: 0) {
                        Spacer()
                        
                        VStack(spacing: 0) {
                            // Handle
                            RoundedRectangle(cornerRadius: 2.5)
                                .fill(Color.gray.opacity(0.5))
                                .frame(width: 40, height: 5)
                                .padding(.top, 10)
                                .padding(.bottom, 10)
                            
                            // Title and Count
                    HStack {
                                Text("Nearby Events")
                                    .font(.title3)
                                    .bold()
                                
                                Spacer()
                                
                                Text("\(nearestEvents.count) found")
                            .foregroundColor(.gray)
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 10)
                            
                            // Events List
                            ScrollView {
                                LazyVStack(spacing: 15) {
                                    ForEach(nearestEvents) { event in
                                        EventListItem(event: event, isSelected: event.id == clickedData?.id)
                                            .onTapGesture {
                                                clickedData = event
                                                withAnimation(.spring()) {
                                                    zoomToEvent(event: event)
                                                    clickedEvent = true
                                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                                .padding(.bottom,80)
                            }
                        }
                        .frame(height: bottomSheetPosition.rawValue + dragOffset)
                        .background(
                            RoundedRectangle(cornerRadius: 0)
                                .fill(Color.dynamic)
                        )
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let translation = value.translation.height
                                    dragOffset = translation
                                }
                                .onEnded { value in
                                    dragOffset = 0
                                    let translation = value.translation.height
                                    let dragDirection: DragDirection = translation > 0 ? .down : .up
                                    
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        bottomSheetPosition = bottomSheetPosition.nextPosition(dragDirection: dragDirection)
                                    }
                                }
                        )
                    }
                    .edgesIgnoringSafeArea(.bottom)
                }
                
                
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showFilterSheet) {
                FilterView(filterModel: filterModel)
            }
            .sheet(isPresented: $showDatePicker) {
                DateFilterView(selectedFilter: $selectedDateFilter)
            }
            .sheet(isPresented: $showPriceFilter) {
                PriceFilterView(selectedFilter: .constant(.all))
            }
            .sheet(isPresented: $showCategoryFilter) {
                CategoryFilterView(selectedCategory: $selectedCategory, categories: FilterType.allCases.map { $0.rawValue })
            }
            .onChange(of: searchText) { newValue in
                filterEvents()
            }
            .onAppear {
                fetchDiscoverEvents()
                locationManager.fetchUserLocation(userId: userID)
                filteredEvents = filterModel.filteredEvents
                updateNearestEvents()
                
                if clickedEvent {
                    hideTab = true
                    } else {
                    hideTab = false
                }
            }
            .onChange(of: locationManager.location) { _ in
                updateNearestEvents()
            }
            .onChange(of: filterModel.filteredEvents) { _ in
                updateNearestEvents()
            }
        }
    }
    
    var mainMapView: some View {
        Map(coordinateRegion: $region,
            showsUserLocation: true,
            userTrackingMode: .constant(.follow),
            annotationItems: filterModel.filteredEvents) { event in
            MapAnnotation(coordinate: CLLocationCoordinate2D(
                latitude: event.coordinates[0],
                longitude: event.coordinates[1]
            )) {
                ZStack {
                    if clickedEvent && clickedData?.id == event.id {
                        PulsatingRingsView()
                            .frame(width: 10, height: 10)
                    }
                    
                    Image(systemName: "mappin.circle.fill")
                        .font(.title)
                        .foregroundColor(clickedData?.id == event.id ? .blue : .red)
                        .background(Circle().fill(Color.dynamic))
                        .scaleEffect(clickedData?.id == event.id && clickedEvent ? 1.7 : 1)
                        .animation(.spring(), value: clickedEvent)
                }
                .onTapGesture {
                    searching = false
                    clickedData = event
                    withAnimation(.spring()) {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            zoomToEvent(event: event)
                        }
                    }
                    withAnimation(.spring()) {
                        clickedEvent = true
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
    
    var topBar: some View {
        VStack {
                VStack {
                    HStack {
                        Image(systemName: "figure.walk")
                            .font(.title)
                            .foregroundColor(.blue)
                            .frame(width: 40, height: 60)
                            .cornerRadius(70)
                            .padding(.leading, 4)
                        
                        VStack(alignment: .leading) {
                            Text("Explore by:")
                                .font(.callout)
                                .bold()
                                .foregroundColor(.blue)
                            
                            Text(locationManager.locationString.split(separator: ",")[0] == "Not Set" ? "not logged in!" : locationManager.locationString.split(separator: ",")[0])
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        if !showSearchView && !clickedEvent {
                            Image(systemName: "magnifyingglass")
                                .font(.title)
                                .foregroundColor(.blue)
                                .onTapGesture {
                                    withAnimation(.spring()) {
                                        showSearchView = true
                                        hideTab = true
                                    }
                                }
                        }
                        
                        if clickedEvent {
                            Button(action: {
                                withAnimation(.spring()) {
                                    if !showSearchView {
                                        clickedEvent = false
                                        hideTab = false
                                        zoomOut()
                                    } else {
                                        withAnimation(.spring()) {
                                            showSearchView = false
                                            hideTab = false
                                        }
                                    }
                                }
                            }) {
                                Image(systemName: "xmark")
                                    .font(.title)
                                    .foregroundColor(.dynamic)
                                    .padding(10)
                                    .background(Circle().fill(.red))
                            }
                        }
                    }
                    
                    
                    // Search View Overlay
                    if showSearchView {
                        searchBox
                        VStack(spacing: 0) {
                            // Filter Buttons
//                            VStack {
//                                HStack(alignment: .center, spacing: 8) {
//                                    Button(action: {
//                                        showFilterSheet = true
//                                    }) {
//                                        HStack {
//                                            Text("Filters")
//                                                .foregroundColor(.blue)
//                                            Image(systemName: "line.3.horizontal.decrease.circle")
//                                                .foregroundColor(.blue)
//                                        }
//                                        .padding(.horizontal, 12)
//                                        .padding(.vertical, 8)
//                                        .background(Color.invert.opacity(0.8))
//                                        .cornerRadius(10)
//                                        .overlay(
//                                            RoundedRectangle(cornerRadius: 10)
//                                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
//                                        )
//                                    }
//
//                                    Text("|")
//                                        .foregroundColor(.gray.opacity(0.5))
//
//                                    Button(action: {
//                                        showDatePicker = true
//                                    }) {
//                                        Text("Date")
//                                            .padding(.horizontal, 12)
//                                            .padding(.vertical, 8)
//                                            .background(Color.invert.opacity(0.8))
//
//                                            .cornerRadius(10)
//                                            .overlay(
//                                                RoundedRectangle(cornerRadius: 10)
//                                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
//                                            )
//                                    }
//
//                                    Text("|")
//                                        .foregroundColor(.gray.opacity(0.5))
//
//                                    Button(action: {
//                                        showPriceFilter = true
//                                    }) {
//                                        Text("Price")
//                                            .padding(.horizontal, 12)
//                                            .padding(.vertical, 8)
//                                            .background(Color.invert.opacity(0.8))
//                                            .cornerRadius(10)
//                                            .overlay(
//                                                RoundedRectangle(cornerRadius: 10)
//                                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
//                                            )
//                                    }
//
//                                    Text("|")
//                                        .foregroundColor(.gray.opacity(0.5))
//
//                                    Button(action: {
//                                        showCategoryFilter = true
//                                    }) {
//                                        Text("Category")
//                                            .padding(.horizontal, 12)
//                                            .padding(.vertical, 8)
//                                            .background(Color.invert.opacity(0.8))
//                                            .cornerRadius(10)
//                                            .overlay(
//                                                RoundedRectangle(cornerRadius: 10)
//                                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
//                                            )
//                                    }
//
//                                    Spacer()
//                                }
//                                .padding(.horizontal)
//                                .padding(.top, 15)
//                                Divider()
//                            }
                            
                            // Search suggestions
                            ScrollView {
                                LazyVStack(spacing: 0) {
                                    if searchText.isEmpty {
                                        Text("Most Popular Events")
                                            .font(.headline)
                                            .foregroundColor(.gray)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                                            .padding(.vertical, 10)
                                    }
                                    
                                    ForEach(displayedEvents) { event in
                                        EventSearchResult(event: event) {
                                            withAnimation(.spring()) {
                                                showSearchView = false
                                                clickedData = event
                                                hideTab = false
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                    zoomToEvent(event: event)
                                                    clickedEvent = true
                                                }
                                            }
                                        }
                                        Divider()
                                            .background(Color.gray.opacity(0.3))
                                    }
                                    
                                    if searchText.isEmpty && !displayedEvents.isEmpty {
                                        Button(action: {
                                            withAnimation(.spring()) {
                                                showSearchView = false
                                                hideTab = false
                                            }
                                        }) {
                                            Text("View All Events")
                                                .foregroundColor(.blue)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 15)
                                        }
                                    }
                                }
                            }
                            .background(Color.dynamic)
                            
                            Spacer()
                        }
                        
                        .edgesIgnoringSafeArea(.bottom)
                        .safeAreaInset(edge: .top) {
                            Color.clear.frame(height: 0)
                        }
                        .transition(.move(edge: .bottom))
                    }
                }.padding(.horizontal)
                    .padding(.vertical, 5)
                    .background(Color.dynamic)
                    .cornerRadius(showSearchView ? 25 : 50)
                    .overlay(
                        RoundedRectangle(cornerRadius: showSearchView ? 25 : 50)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.dynamic, .red, .blue, Color.dynamic]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .scaleEffect(showSearchView ? 1 : topbarPressed ? 0.97 : 1)
                    .padding(.top, 20)
                    .padding(.horizontal)
                
            
            
            Spacer()
        }
    }
    
    var searchBox: some View {
       
            
                    HStack {
                TextField("Search event, party...", text: $searchText)
                    .padding()
                    .background(Color.dynamic)
                    .cornerRadius(12)
                    .foregroundColor(.invert)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                
               
            }
            .padding(.horizontal)
            .padding(.bottom)
          
        
    }
    
    var showEventCard: some View {
        VStack {
            if clickedEvent && !showSearchView, let event = clickedData {
                ZStack {
                    VStack {
                        Spacer()
                        NavigationLink(destination: ViewEventDetail(event: event)) {
                            RegularEventCard(event: event)
                                .frame(height: 200)
                                .padding(.horizontal)
                        }
                    }
                }
                .onChange(of: hideTab) { newValue in
                    if !newValue {
                        clickedEvent = false
                    }
                }
                .offset(y: !clickedEvent ? UIScreen.main.bounds.height * 0.5 : 0)
                .transition(.slide)
            }
        }
    }
    
    private func zoomToEvent(event: Event) {
        withAnimation {
            region.center = CLLocationCoordinate2D(
                latitude: event.coordinates[0],
                longitude: event.coordinates[1]
            )
            region.span = MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
        }
    }
    
    private func zoomOut() {
        withAnimation(.spring()) {
            region.span = MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
        }
    }
    
    private func fetchDiscoverEvents() {
        isLoading = true
        let db = Firestore.firestore()
        
        print("Starting to fetch events from Firebase...")
        
        db.collection("events")
            .whereField("status", isEqualTo: "active")
            .getDocuments { snapshot, error in
                isLoading = false
                
                if let error = error {
                    print("Error fetching events: \(error.localizedDescription)")
                    errorMessage = error.localizedDescription
                    showError = true
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No documents found in events collection")
                    errorMessage = "No events found"
                    showError = true
                    return
                }
                
                print("Found \(documents.count) documents in events collection")
                
                let fetchedEvents = documents.compactMap { document -> Event? in
                    let data = document.data()
                    
                    guard let name = data["name"] as? String,
                          let description = data["description"] as? String,
                          let type = data["type"] as? String,
                          let location = data["location"] as? String,
                          let price = data["price"] as? String,
                          let owner = data["owner"] as? String,
                          let organizerName = data["organizerName"] as? String,
                          let shareContactInfo = data["shareContactInfo"] as? Bool,
                          let startDate = (data["startDate"] as? Timestamp)?.dateValue(),
                          let endDate = (data["endDate"] as? Timestamp)?.dateValue(),
                          let images = data["images"] as? [String],
                          let isTimed = data["isTimed"] as? Bool,
                          let coordinates = data["coordinates"] as? [Double],
                          let status = data["status"] as? String else {
                        print("Failed to parse event data for document: \(document.documentID)")
                        return nil
                    }
                    
                    let maxParticipants = data["maxParticipants"] as? Int ?? 0
                    let participants = Array(repeating: "Participant", count: maxParticipants)
                    
                    return Event(
                        name: name,
                        description: description,
                        type: type,
                        views: data["views"] as? String ?? "0",
                        location: location,
                        price: price,
                        owner: owner,
                        organizerName: organizerName,
                        shareContactInfo: shareContactInfo,
                        startDate: startDate,
                        endDate: endDate,
                        images: images,
                        participants: participants,
                        maxParticipants: maxParticipants,
                        isTimed: isTimed,
                        createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                        coordinates: coordinates,
                        status: status
                    )
                }
                
                print("Successfully parsed \(fetchedEvents.count) events")
                print("Available event types: \(Set(fetchedEvents.map { $0.type }))")
                
                // Update the filter model with fetched events
                filterModel.updateEvents(fetchedEvents)
                
                // Create current filters
                let currentFilters = EventFilters(
                    searchText: searchText,
                    selectedType: selectedFilter.rawValue,
                    selectedLocation: filterModel.activeFilters.selectedLocation,
                    priceRange: filterModel.activeFilters.priceRange,
                    startDate: filterModel.activeFilters.startDate,
                    endDate: filterModel.activeFilters.endDate,
                    showTimedEventsOnly: filterModel.activeFilters.showTimedEventsOnly,
                    minParticipants: filterModel.activeFilters.minParticipants
                )
                
                // Apply filters
                filterModel.applyFilters(filters: currentFilters)
                
                print("Updated filter model with \(filterModel.filteredEvents.count) filtered events")
            }
    }
    
    private func filterEvents() {
        if searchText.isEmpty {
            filteredEvents = filterModel.filteredEvents
        } else {
            filteredEvents = filterModel.filteredEvents.filter { event in
                event.name.localizedCaseInsensitiveContains(searchText) ||
                event.description.localizedCaseInsensitiveContains(searchText) ||
                event.location.localizedCaseInsensitiveContains(searchText) ||
                event.type.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private func updateNearestEvents() {
        guard let userLocation = locationManager.location else {
            nearestEvents = filterModel.filteredEvents
            return
        }
        
        nearestEvents = filterModel.filteredEvents
            .sorted { event1, event2 in
                let location1 = CLLocation(
                    latitude: event1.coordinates[0],
                    longitude: event1.coordinates[1]
                )
                let location2 = CLLocation(
                    latitude: event2.coordinates[0],
                    longitude: event2.coordinates[1]
                )
                return location1.distance(from: userLocation) < location2.distance(from: userLocation)
            }
    }
}

struct PulsatingRingsView: View {
    @State private var expand = false
    
    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(Color.orange.opacity(0.98), lineWidth: 2)
                    .frame(width: expand ? CGFloat(20 + index * 40) : 0,
                           height: expand ? CGFloat(20 + index * 40) : 0)
                    .opacity(expand ? (1 - CGFloat(index) * 0.3) : 0)
                    .animation(
                        Animation.easeOut(duration: 3)
                            .repeatForever(autoreverses: false)
                            .delay(Double(index) * 0.5),
                        value: expand
                    )
            }
        }
        .onAppear {
            expand = true
            }
    }
}

// MARK: - Supporting Views

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search events...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct CategoryButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .dynamic : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(uiColor: .secondarySystemBackground))
                .cornerRadius(20)
        }
    }
}

struct CustomFilterButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(title)
                .font(.subheadline)
                    .fontWeight(.medium)
            }
                .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.dynamic)
            .cornerRadius(20)
            .shadow(color: Color.invert.opacity(0.1), radius: 3, x: 0, y: 1)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .foregroundColor(.primary)
    }
}

struct SearchResultRow: View {
    let event: Event
    
    var body: some View {
        NavigationLink(destination: ViewEventDetail(event: event)) {
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: event.images[0])) { image in
                    image
                .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(width: 60, height: 60)
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                    Text(event.name)
                    .font(.headline)
                
                    Text(event.location)
                        .font(.subheadline)
                    .foregroundColor(.gray)
                
                HStack {
                    Image(systemName: "calendar")
                            .foregroundColor(.blue)
                        Text(event.startDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                            .foregroundColor(.gray)
                        
                        Image(systemName: "person.2")
                            .foregroundColor(.blue)
                        Text("\(event.participants.count) going")
                        .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                Text(event.price)
                    .font(.headline)
                .foregroundColor(.blue)
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
}

struct DateFilterView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedFilter: DateFilter
    
    var body: some View {
        NavigationView {
            List {
                ForEach(DateFilter.allCases, id: \.self) { filter in
                    Button(action: {
                        selectedFilter = filter
                        dismiss()
                    }) {
                        HStack {
                            Text(filter.rawValue)
                            Spacer()
                            if selectedFilter == filter {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Date Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.dynamic)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct PriceFilterView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedFilter: PriceFilter
    
    var body: some View {
        NavigationView {
            List {
                ForEach(PriceFilter.allCases, id: \.self) { filter in
                    Button(action: {
                        selectedFilter = filter
                        dismiss()
                    }) {
                        HStack {
                            Text(filter.rawValue)
                            Spacer()
                            if selectedFilter == filter {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Price Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.dynamic)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct CategoryFilterView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCategory: String?
    let categories: [String]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(categories, id: \.self) { category in
                    Button(action: {
                        selectedCategory = category
                        dismiss()
                    }) {
                        HStack {
                            Text(category)
                            Spacer()
                            if selectedCategory == category {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Category Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.dynamic)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct LocationFilterView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedLocation: String?
    let locations: [String]
    
    var body: some View {
        NavigationView {
            List {
                Button(action: {
                    selectedLocation = nil
                    dismiss()
                }) {
                    HStack {
                        Text("All Locations")
                        Spacer()
                        if selectedLocation == nil {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                ForEach(locations, id: \.self) { location in
                    Button(action: {
                        selectedLocation = location
                        dismiss()
                    }) {
                        HStack {
                            Text(location)
                            Spacer()
                            if selectedLocation == location {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Location Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.dynamic)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SortOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedOption: SortOption
    
    var body: some View {
        NavigationView {
            List {
                ForEach(SortOption.allCases, id: \.self) { option in
                    Button(action: {
                        selectedOption = option
                        dismiss()
                    }) {
                        HStack {
                            Text(option.rawValue)
                            Spacer()
                            if selectedOption == option {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Sort By")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.dynamic)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

enum DateFilter: String, CaseIterable {
    case all = "All Dates"
    case today = "Today"
    case thisWeek = "This Week"
    case thisMonth = "This Month"
    case upcoming = "Upcoming"
}

enum PriceFilter: String, CaseIterable {
    case all = "All Prices"
    case free = "Free"
    case under10 = "Under $10"
    case under25 = "Under $25"
    case under50 = "Under $50"
}

enum SortOption: String, CaseIterable {
    case newest = "Newest First"
    case oldest = "Oldest First"
    case priceLowToHigh = "Price: Low to High"
    case priceHighToLow = "Price: High to Low"
    case mostPopular = "Most Popular"
}

let sampleEvent = sampleEvents[0] // Keep the original reference for backward compatibility

struct DiscoverView_Previews: PreviewProvider {
    static var previews: some View {
        DiscoverView()
    }
}

struct FilterView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedType = "All"
    @State private var selectedLocation = "All"
    @State private var priceRange: ClosedRange<Double> = 0...1000
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date().addingTimeInterval(30*24*60*60)
    @State private var showTimedEventsOnly = false
    @State private var minParticipants = 0
    
    @ObservedObject var filterModel: FilterModel

    let eventTypes = ["All", "Concert", "Corporate", "Marketing", "Health & Wellness", "Technology", "Art & Culture","Charity","Literature","Lifestyle","Environmental"]
    let locations = ["All", "New York", "Los Angeles", "Miami", "Chicago", "Houston"]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
              
                // Event Type Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Event Type")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(eventTypes, id: \.self) { type in
                                Button(action: {
                                    selectedType = type
                                }) {
                                    Text(type)
                                        .font(.subheadline)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(selectedType == type ? Color.blue : Color(UIColor.secondarySystemBackground))
                                        .foregroundColor(selectedType == type ? .dynamic : .primary)
                                        .cornerRadius(20)
                                }
                            }
                        }
                    }
                }
                
                // Location Section
                VStack(alignment: .leading, spacing: 12) {
                Text("Location")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(locations, id: \.self) { location in
                                Button(action: {
                                    selectedLocation = location
                                }) {
                                    Text(location)
                                        .font(.subheadline)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(selectedLocation == location ? Color.blue : Color(UIColor.secondarySystemBackground))
                                        .foregroundColor(selectedLocation == location ? .dynamic : .primary)
                                        .cornerRadius(20)
                                }
                            }
                        }
                    }
                }
                
                // Price Range Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Price range")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    RangeSlider(value: $priceRange, in: 0...2000)
                        .frame(height: 44)
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Minimum")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text("$\(Int(priceRange.lowerBound))")
                                .fontWeight(.medium)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("Maximum")
                    .font(.caption)
                    .foregroundColor(.gray)
                            Text("$\(Int(priceRange.upperBound))")
                                .fontWeight(.medium)
                        }
                    }
                }
                
                // Date Range Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Date Range")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    DatePicker("Start Date", selection: $startDate, displayedComponents: [.date])
                        .datePickerStyle(.compact)
                    
                    DatePicker("End Date", selection: $endDate, displayedComponents: [.date])
                        .datePickerStyle(.compact)
                }
                
                // Additional Filters
                VStack(alignment: .leading, spacing: 16) {
                    Text("Additional Filters")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Toggle("Show Timed Events Only", isOn: $showTimedEventsOnly)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Minimum Participants")
                            .font(.body)
                
                HStack {
                            Button(action: { if minParticipants > 0 { minParticipants -= 1 } }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.gray)
                            }
                            
                            Text("\(minParticipants)")
                                .frame(minWidth: 40)
                            
                            Button(action: { minParticipants += 1 }) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Filters")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.dynamic)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Apply") {
                    applyFilters()
                    dismiss()
                }
            }
        }
        .onDisappear {
            applyFilters()
        }
    }
    
    private func applyFilters() {
        let filters = EventFilters(
            searchText: searchText,
            selectedType: selectedType,
            selectedLocation: selectedLocation,
            priceRange: priceRange,
            startDate: startDate,
            endDate: endDate,
            showTimedEventsOnly: showTimedEventsOnly,
            minParticipants: minParticipants
        )
        filterModel.applyFilters(filters: filters)
    }
}

struct RangeSlider: View {
    @Binding var value: ClosedRange<Double>
    let bounds: ClosedRange<Double>
    
    init(value: Binding<ClosedRange<Double>>, in bounds: ClosedRange<Double>) {
        self._value = value
        self.bounds = bounds
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 4)
                
                Rectangle()
                    .fill(Color.brown)
                    .frame(width: CGFloat((value.upperBound - value.lowerBound) / (bounds.upperBound - bounds.lowerBound)) * geometry.size.width,
                           height: 4)
                    .offset(x: CGFloat((value.lowerBound - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound)) * geometry.size.width)
                
                HStack(spacing: 0) {
                    Circle()
                        .fill(Color.dynamic)
                        .frame(width: 24, height: 24)
                        .shadow(radius: 4)
                        .offset(x: CGFloat((value.lowerBound - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound)) * geometry.size.width)
                        .gesture(DragGesture()
                            .onChanged { gesture in
                                let newValue = bounds.lowerBound + Double(gesture.location.x / geometry.size.width) * (bounds.upperBound - bounds.lowerBound)
                                if newValue < value.upperBound {
                                    value = newValue...value.upperBound
                                }
                            })
                    
                    Circle()
                        .fill(Color.dynamic)
                        .frame(width: 24, height: 24)
                        .shadow(radius: 4)
                        .offset(x: CGFloat((value.upperBound - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound)) * geometry.size.width - 24)
                        .gesture(DragGesture()
                            .onChanged { gesture in
                                let newValue = bounds.lowerBound + Double(gesture.location.x / geometry.size.width) * (bounds.upperBound - bounds.lowerBound)
                                if newValue > value.lowerBound {
                                    value = value.lowerBound...newValue
                                }
                            })
                }
            }
        }
    }
}

// Add MapView component
struct MapView: View {
    let events: [Event]
    @StateObject private var locationManager = LocationManager()
    @State private var selectedEvent: Event?
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.3361, longitude: -122.0090),
        span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
    )
    @State private var locationStatus: String = "Waiting for location..."
    @State private var nearestEventDistance: Double = 0
    @State private var visibleEvents: [Event] = []
    @State private var isListExpanded = true
    @State private var lastRegionUpdate = Date()
    @State private var hasInitializedLocation = false
    
    // Add computed property to find nearest event
    private var nearestEvent: Event? {
        guard let userLocation = locationManager.location else { 
            print("User location not available")
            return nil 
        }
        
        print("User location: \(userLocation.coordinate.latitude), \(userLocation.coordinate.longitude)")
        
        let nearest = events.min { event1, event2 in
            let location1 = CLLocation(
                latitude: event1.coordinates.count >= 2 ? event1.coordinates[0] : 37.3361,
                longitude: event1.coordinates.count >= 2 ? event1.coordinates[1] : -122.0090
            )
            let location2 = CLLocation(
                latitude: event2.coordinates.count >= 2 ? event2.coordinates[0] : 37.3361,
                longitude: event2.coordinates.count >= 2 ? event2.coordinates[1] : -122.0090
            )
            
            return location1.distance(from: userLocation) < location2.distance(from: userLocation)
        }
        
        if let nearest = nearest {
            let eventLocation = CLLocation(
                latitude: nearest.coordinates.count >= 2 ? nearest.coordinates[0] : 37.3361,
                longitude: nearest.coordinates.count >= 2 ? nearest.coordinates[1] : -122.0090
            )
            nearestEventDistance = eventLocation.distance(from: userLocation)
            print("Nearest event: \(nearest.name) at distance: \(nearestEventDistance/1000) km")
        } else {
            print("No nearest event found")
        }
        
        return nearest
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Map View
            Map(coordinateRegion: $region,
                showsUserLocation: true,
                userTrackingMode: .constant(.follow),
                annotationItems: events) { event in
                MapAnnotation(coordinate: CLLocationCoordinate2D(
                    latitude: event.coordinates.count >= 2 ? event.coordinates[0] : 37.3361,
                    longitude: event.coordinates.count >= 2 ? event.coordinates[1] : -122.0090
                )) {
                    VStack(spacing: 0) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.title)
                            .foregroundColor(event.id == selectedEvent?.id ? .blue : .red)
                            .background(Circle().fill(Color.dynamic))
                            .padding(4)
                    }
                    .onTapGesture {
                        withAnimation {
                            selectedEvent = event
                        }
                    }
                }
            }
            .onChange(of: lastRegionUpdate) { _ in
                updateVisibleEvents()
            }
            
            // Map Controls
            VStack(spacing: 12) {
                // Location button
                Button(action: {
                    if let location = locationManager.location {
                        region.center = location.coordinate
                        print("Centered map on user location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
                    } else {
                        print("User location not available")
                        locationManager.requestLocation()
                    }
                }) {
                    Image(systemName: "location.fill")
                        .font(.title2)
                        .padding(8)
                        .background(Color.dynamic)
                        .clipShape(Circle())
                        .shadow(radius: 2)
                }
                
                // Zoom in button
                Button(action: {
                    withAnimation {
                        region.span = MKCoordinateSpan(
                            latitudeDelta: region.span.latitudeDelta / 2,
                            longitudeDelta: region.span.longitudeDelta / 2
                        )
                        lastRegionUpdate = Date()
                    }
                }) {
                    Image(systemName: "plus")
                        .font(.title2)
                        .padding(8)
                        .background(Color.dynamic)
                        .clipShape(Circle())
                        .shadow(radius: 2)
                }
                
                // Zoom out button
                Button(action: {
                    withAnimation {
                        region.span = MKCoordinateSpan(
                            latitudeDelta: region.span.latitudeDelta * 2,
                            longitudeDelta: region.span.longitudeDelta * 2
                        )
                        lastRegionUpdate = Date()
                    }
                }) {
                    Image(systemName: "minus")
                        .font(.title2)
                        .padding(8)
                        .background(Color.dynamic)
                        .clipShape(Circle())
                        .shadow(radius: 2)
                }
            }
            .padding()
            
            // Nearest event button
            if let nearest = nearestEvent {
                Button(action: {
                    selectedEvent = nearest
                    if nearest.coordinates.count >= 2 {
                        region.center = CLLocationCoordinate2D(
                            latitude: nearest.coordinates[0],
                            longitude: nearest.coordinates[1]
                        )
                        print("Centered map on nearest event: \(nearest.name)")
                    }
                }) {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("Nearest Event")
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                    .padding(8)
                    .background(Color.dynamic)
                    .cornerRadius(20)
                    .shadow(radius: 2)
                }
                .padding(.top, 60)
                .padding(.trailing)
            }
            
            // List View
            VStack(spacing: 0) {
                // List Header
                HStack {
                    Text("\(visibleEvents.count) Events")
                        .font(.headline)
                    Spacer()
                    Button(action: {
                        withAnimation {
                            isListExpanded.toggle()
                        }
                    }) {
                        Image(systemName: isListExpanded ? "chevron.up" : "chevron.down")
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color.dynamic)
                
                if isListExpanded {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(visibleEvents, id: \.id) { event in
                                EventListItem(event: event, isSelected: selectedEvent?.id == event.id)
                                    .onTapGesture {
                                        withAnimation {
                                            selectedEvent = event
                                            if event.coordinates.count >= 2 {
                                                region.center = CLLocationCoordinate2D(
                                                    latitude: event.coordinates[0],
                                                    longitude: event.coordinates[1]
                                                )
                                            }
                                        }
                                    }
                            }
                        }
                    }
                    .frame(height: 300)
                    .background(Color.dynamic)
                }
            }
            .background(Color.dynamic)
            .cornerRadius(12)
            .shadow(radius: 5)
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .onAppear {
            print("MapView appeared")
            locationManager.requestPermission()
            locationManager.requestLocation()
            
            // Use a timer to ensure location is available
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                updateLocationStatus()
                
                if let location = locationManager.location {
                    print("User location available: \(location.coordinate.latitude), \(location.coordinate.longitude)")
                    region.center = location.coordinate
                    
                    // Find and select the nearest event
                    if let nearest = nearestEvent {
                        print("Selecting nearest event: \(nearest.name)")
                        selectedEvent = nearest
                        
                        // Center map on the nearest event
                        if nearest.coordinates.count >= 2 {
                            region.center = CLLocationCoordinate2D(
                                latitude: nearest.coordinates[0],
                                longitude: nearest.coordinates[1]
                            )
                            print("Centered map on nearest event: \(nearest.name)")
                        }
                    } else {
                        print("No nearest event found")
                    }
                } else {
                    print("User location not available after delay")
                    locationStatus = "Location not available. Please check permissions."
                }
            }
        }
        .onChange(of: locationManager.location) { newLocation in
            if let location = newLocation {
                print("Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")
                updateLocationStatus()
                
                // Only update the map center if we haven't initialized it yet
                if !hasInitializedLocation {
                    region.center = location.coordinate
                    hasInitializedLocation = true
                    print("Initialized map center to user location")
                }
                
                // Update nearest event when location changes
                if let nearest = nearestEvent {
                    print("Nearest event updated: \(nearest.name)")
                    selectedEvent = nearest
                }
            }
        }
        .onReceive(Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()) { _ in
            // Update visible events periodically
            updateVisibleEvents()
        }
    }
    
    private func updateLocationStatus() {
        if let location = locationManager.location {
            locationStatus = "Location: \(String(format: "%.4f", location.coordinate.latitude)), \(String(format: "%.4f", location.coordinate.longitude))"
        } else {
            locationStatus = "Waiting for location..."
        }
    }
    
    private func updateVisibleEvents() {
        // Filter events that are within the current map region
        visibleEvents = events.filter { event in
            guard event.coordinates.count >= 2 else { return false }
            
            let eventLocation = CLLocationCoordinate2D(
                latitude: event.coordinates[0],
                longitude: event.coordinates[1]
            )
            
            let isInRegion = region.contains(eventLocation)
            return isInRegion
        }
        
        // Sort events by distance from user location if available
        if let userLocation = locationManager.location {
            visibleEvents.sort { event1, event2 in
                let location1 = CLLocation(
                    latitude: event1.coordinates[0],
                    longitude: event1.coordinates[1]
                )
                let location2 = CLLocation(
                    latitude: event2.coordinates[0],
                    longitude: event2.coordinates[1]
                )
                return location1.distance(from: userLocation) < location2.distance(from: userLocation)
            }
        }
    }
}

// Helper extension to check if a coordinate is within a region
extension MKCoordinateRegion {
    func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
        let latDelta = self.span.latitudeDelta / 2.0
        let lonDelta = self.span.longitudeDelta / 2.0
        
        let minLat = self.center.latitude - latDelta
        let maxLat = self.center.latitude + latDelta
        let minLon = self.center.longitude - lonDelta
        let maxLon = self.center.longitude + lonDelta
        
        return coordinate.latitude >= minLat && coordinate.latitude <= maxLat &&
               coordinate.longitude >= minLon && coordinate.longitude <= maxLon
    }
}

// Event List Item View
struct EventListItem: View {
    let event: Event
    let isSelected: Bool
    @StateObject private var locationManager = LocationManager()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: event.images[0])) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(width: 80, height: 80)
                .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.name)
                        .font(.headline)
                        .foregroundColor(.invert)
                        .lineLimit(1)
                    
                    Text(event.location)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                    
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.blue)
                        Text(event.startDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        if let userLocation = locationManager.location {
                            let eventLocation = CLLocation(
                                latitude: event.coordinates[0],
                                longitude: event.coordinates[1]
                            )
                            let distance = eventLocation.distance(from: userLocation)
                            Text(String(format: "%.1f km", distance / 1000))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Spacer()
                
                Text(event.price)
                    .font(.headline)
                    .foregroundColor(.blue)
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            .cornerRadius(12)
//            .overlay(
//                RoundedRectangle(cornerRadius: 12)
//                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
//            )
            Divider()
        }
    }
}

struct EventSearchResult: View {
    let event: Event
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: {
                    switch event.type {
                        case "Concert": return "figure.dance"
                        case "Corporate": return "building.2.fill"
                        case "Marketing": return "megaphone.fill"
                        case "Health & Wellness": return "heart.fill"
                        case "Technology": return "desktopcomputer"
                        case "Art & Culture": return "paintbrush.fill"
                        case "Charity": return "heart.circle.fill"
                        case "Literature": return "book.fill"
                        case "Lifestyle": return "leaf.fill"
                        case "Environmental": return "leaf.arrow.triangle.circlepath"
                        case "Entertainment": return "music.note.list"
                        default: return "calendar"
                    }
                }())
                .foregroundColor(.gray)
                    .font(.title2)
                    .padding(.top, 4)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.name)
                        .font(.headline)
                        .foregroundColor(.invert)
                    
                    Text(event.description)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                    
                    
                        HStack(spacing: 12) {
                            Label(event.location.split(separator: ",")[0], systemImage: "location")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                            
                            Label(event.price, systemImage: "dollarsign.circle")
                                .font(.caption)
                                .foregroundColor(.gray)
                                
                            Label("\(event.views) views", systemImage: "eye.fill")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
} 
