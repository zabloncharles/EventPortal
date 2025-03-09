import SwiftUI

class FilterModel: ObservableObject {
    @Published var filteredEvents: [Event] = sampleEvents
    @Published var activeFilters: EventFilters = EventFilters()
    
    func applyFilters(filters: EventFilters) {
        activeFilters = filters
        filteredEvents = sampleEvents.filter { event in
            var matches = true
            
            // Type filter
            if filters.selectedType != "All" {
                matches = matches && event.type == filters.selectedType
            }
            
            // Location filter
            if filters.selectedLocation != "All" {
                matches = matches && event.location == filters.selectedLocation
            }
            
            // Price filter
            let price = Double(event.price.replacingOccurrences(of: "$", with: "")) ?? 0
            matches = matches && price >= filters.priceRange.lowerBound && price <= filters.priceRange.upperBound
            
            // Date filter
            if let eventDate = event.startDate {
                matches = matches && eventDate >= filters.startDate && eventDate <= filters.endDate
            }
            
            // Timed events
            if filters.showTimedEventsOnly {
                matches = matches && event.isTimed
            }
            
            // Participants
            matches = matches && event.participants.count >= filters.minParticipants
            
            // Search text
            if !filters.searchText.isEmpty {
                matches = matches && (
                    event.name.localizedCaseInsensitiveContains(filters.searchText) ||
                    event.location.localizedCaseInsensitiveContains(filters.searchText) ||
                    event.type.localizedCaseInsensitiveContains(filters.searchText)
                )
            }
            
            return matches
        }
    }
}

struct EventFilters {
    var searchText: String = ""
    var selectedType: String = "All"
    var selectedLocation: String = "All"
    var priceRange: ClosedRange<Double> = 200...1400
    var startDate: Date = Date()
    var endDate: Date = Date().addingTimeInterval(7*24*60*60)
    var showTimedEventsOnly: Bool = false
    var minParticipants: Int = 0
}

struct DiscoverView: View {
    @StateObject private var filterModel = FilterModel()
    @State private var searchText = ""
    @State private var selectedLocation = "Lombok, Indonesia"
    @State private var selectedFilter: FilterType = .all
    @State private var isSearching = false
    
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
                                // Location picker action
                            }) {
                                HStack {
                                    Text(selectedLocation)
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
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
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
                    } else {
                        // Regular Content
                        // Filters
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(FilterType.allCases) { filter in
                                    FilterButton(
                                        filter: filter,
                                        isSelected: selectedFilter == filter,
                                        action: { 
                                            selectedFilter = filter
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
                                            filterModel.applyFilters(filters: filters)
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                        
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
                                        RecommendedEventCard(event: event)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
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
                                    RegularEventCard(event: event)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
                .padding(.bottom,70) // keep views above tabbar
            }
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct SearchResultRow: View {
    let event: Event
    
    var body: some View {
        NavigationLink(destination: ViewEventDetail(event: event)) {
            HStack(spacing: 12) {
                Image(event.images[0])
                    .resizable()
                    .aspectRatio(contentMode: .fill)
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
                        Text(event.startDate?.formatted(date: .abbreviated, time: .omitted) ?? "No date")
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

enum FilterType: String, CaseIterable, Identifiable {
    case all = "All"
    case technology = "Technology"
    case music = "Music"
    case sports = "Sports"
    case art = "Art"
    case food = "Food"
    case business = "Business"
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .all: return "square.grid.2x2.fill"
        case .technology: return "laptopcomputer"
        case .music: return "music.note"
        case .sports: return "sportscourt.fill"
        case .art: return "paintpalette.fill"
        case .food: return "fork.knife"
        case .business: return "briefcase.fill"
        }
    }
}

struct FilterButton: View {
    let filter: FilterType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: filter.icon)
                    .foregroundColor(isSelected ? .white : .primary)
                Text(filter.rawValue)
                .font(.subheadline)
                .fontWeight(.medium)
            }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(uiColor: .secondarySystemBackground))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
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
    @State private var priceRange: ClosedRange<Double> = 200...1400
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date().addingTimeInterval(7*24*60*60)
    @State private var showTimedEventsOnly = false
    @State private var minParticipants = 0
    
    @ObservedObject var filterModel: FilterModel
    
    let eventTypes = ["All", "Technology", "Music", "Sports", "Art", "Food", "Business"]
    let locations = ["All", "New York", "Los Angeles", "Miami", "Chicago", "Houston"]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search events...", text: $searchText)
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
            
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
