import SwiftUI
import FirebaseFirestore

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
    @State private var isSearching = false
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showLocationSettings = false
    @StateObject private var locationManager = LocationManager()
    @AppStorage("userID") private var userID: String = ""
    @State private var pageAppeared = false
    
    var filteredSearchResults: [Event] {
        guard !searchText.isEmpty else { return [] }
        return filterModel.filteredEvents.filter { event in
            event.name.localizedCaseInsensitiveContains(searchText) ||
            event.location.localizedCaseInsensitiveContains(searchText) ||
            event.type.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    // Location Header
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Your Location")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Button(action: {
                                showLocationSettings = true
                            }) {
                                HStack {
                                    Text(locationManager.locationString.split(separator: ",")[0] == "Not Set" ? "loading.." : locationManager.locationString.split(separator: ",")[0])
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                    Image(systemName: "chevron.down")
                                        .font(.caption)
                                }
                            }
                        }
                        Spacer()
                        Button(action: {
                            // Notification action
                        }) {
                            Image(systemName: "bell")
                                .font(.title2)
                                .foregroundColor(.primary)
                        }
                        Button(action: {
                            // Settings action
                        }) {
                            NavigationLink(destination: FilterView(filterModel: filterModel)) {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.title2)
                                    .foregroundColor(.primary)
                                    .padding(.leading, 8)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .offset(y: !pageAppeared ? -UIScreen.main.bounds.height * 0.5 : 0)
                    
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Discover a city...", text: $searchText)
                            .onChange(of: searchText) { newValue in
                                isSearching = !newValue.isEmpty
                            }
                        if isSearching {
                            Button(action: {
                                searchText = ""
                                isSearching = false
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical,15)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .offset(y: !pageAppeared ? -UIScreen.main.bounds.height * 0.5 : 0)
                    
                    // Filters
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(FilterType.allCases) { filter in
                                FilterButton(
                                    filter: filter,
                                    isSelected: selectedFilter == filter,
                                    action: { 
                                        print("Selected filter: \(filter.rawValue)")
                                        selectedFilter = filter
                                        
                                        // Create new filters with the selected type
                                        let filters = EventFilters(
                                            searchText: searchText,
                                            selectedType: filter.rawValue,
                                            selectedLocation: filterModel.activeFilters.selectedLocation,
                                            priceRange: filterModel.activeFilters.priceRange,
                                            startDate: filterModel.activeFilters.startDate,
                                            endDate: filterModel.activeFilters.endDate,
                                            showTimedEventsOnly: filterModel.activeFilters.showTimedEventsOnly,
                                            minParticipants: filterModel.activeFilters.minParticipants
                                        )
                                        
                                        // Apply filters
                                        filterModel.applyFilters(filters: filters)
                                        
                                        // Print debug information
                                        print("Current filter state:")
                                        print("- Selected type: \(filter.rawValue)")
                                        print("- Total events: \(filterModel.filteredEvents.count)")
                                        print("- Available event types: \(Set(filterModel.filteredEvents.map { $0.type }))")
                                    }
                                )
                                //Give it a seamless look
                                Divider().padding(.vertical)
                            }
                        }
                        .padding(.horizontal)
                    } .offset(y: !pageAppeared ? UIScreen.main.bounds.height * 0.5 : 0)
                    
                    
                    if isSearching {
                        // Search Results Section
                        VStack(alignment: .leading, spacing: 16) {
                            if filteredSearchResults.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray)
                                    Text("No results found")
                                        .font(.headline)
                                    Text("Try adjusting your search terms")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top, 40)
                            } else {
                                Text("Search Results")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .padding(.horizontal)
                                
                                ForEach(filteredSearchResults, id: \.name) { event in
                                    SearchResultRow(event: event)
                                }
                            }
                        }
                        .padding(.top)
                        .offset(y: !pageAppeared ? UIScreen.main.bounds.height * 0.5 : 0)
                        
                        
                    } else {
                        if isLoading {
                            VStack(spacing: 20) {
                                ProgressView()
                                    .scaleEffect(1.5)
                                Text("Loading events...")
                                    .foregroundColor(isLoading ? .gray : Color.dynamic)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.top, 40)
                        } else if filterModel.filteredEvents.isEmpty {
                            VStack(spacing: 20) {
                                Image(systemName: "calendar.badge.exclamationmark")
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray)
                                Text("No Events Available")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text("Check back later for new events")
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.top, 40)
                            .offset(y: !pageAppeared ? UIScreen.main.bounds.height * 0.5 : 0)
                        } else {
                            // Regular Content
                          
                            // Nearby Destination
                            VStack(alignment: .leading) {
                                HStack {
                                    Text("Nearby Destination")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                    Spacer()
                                    Button("See all") {
                                        // See all action
                                    }
                                    .foregroundColor(.gray)
                    }
                    .padding(.horizontal)
                    
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(Array(filterModel.filteredEvents.prefix(3)), id: \.name) { event in
                                            
                                            
                                            NavigationLink {
                                                //Show event detail view
                                                ViewEventDetail(event: event)
                                            } label: {
                                                RecommendedEventCard(event: event)
                                            }

                                           
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            } .offset(y: !pageAppeared ? UIScreen.main.bounds.height * 0.5 : 0)
                            
                            // Recommendation
                            VStack(alignment: .leading) {
                                HStack {
                                    Text("Recommendation")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                    Spacer()
                                    Button("See all") {
                                        // See all action
                                    }
                                    .foregroundColor(.gray)
                                }
                                .padding(.horizontal)
                                
                                VStack(spacing: 16) {
                                    ForEach(Array(filterModel.filteredEvents.suffix(3)), id: \.name) { event in
                                        NavigationLink {
                                            //Show event detail view
                                            ViewEventDetail(event: event)
                                        } label: {
                                            RegularEventCard(event: event)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            } .offset(y: !pageAppeared ? UIScreen.main.bounds.height * 0.5 : 0)
                        }
                    }
                }
                .padding(.vertical)
                .padding(.bottom,70) // keep views above tabbar
            }
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.dynamic)
            .sheet(isPresented: $showLocationSettings) {
                LocationSettingsView(locationManager: locationManager, userId: userID)
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "An unknown error occurred")
            }
            .onAppear {
                withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
                    pageAppeared = true
                }
                fetchDiscoverEvents()
                locationManager.fetchUserLocation(userId: userID)
            }
            .refreshable {
                fetchDiscoverEvents()
            }
        }
    }
    
    var noeventsview: some View {
        
            VStack(alignment: .center, spacing: 10.0) {
                LottieView(filename: "Ghost", loop: true)
                    .frame(height: 220)
                    .padding(.top, 0)
                    .offset(y:30)
                
                Text("Opps! No events yet")
                    .font(.headline)
                
                Text("Nothing to see here. Events are more intentional on here so don't worry, They'll come in very soon.")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 25)
                
                Button {
                    //reload events
                    fetchDiscoverEvents()
                } label: {
                    HStack {
                        Text("Try Searching Again!")
                            .font(.body)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 15)
                    .padding(.vertical, 10)
                    .background(Color.gray.opacity(0.40))
                    .cornerRadius(30)
                }

            }
            .padding(.horizontal, 20)
            
        
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
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(uiColor: .secondarySystemBackground))
                .cornerRadius(20)
        }
    }
}

struct FilterButton: View {
    let filter: FilterType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(filter.rawValue)
                .font(.subheadline)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(isSelected ? Color.blue : Color(uiColor: .secondarySystemBackground))
                .cornerRadius(10)
        }
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
                                        .foregroundColor(selectedType == type ? .white : .primary)
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
                                        .foregroundColor(selectedLocation == location ? .white : .primary)
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
                        .fill(Color.white)
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
                        .fill(Color.white)
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
