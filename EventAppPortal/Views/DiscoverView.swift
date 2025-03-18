import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreSwift

struct Event: Identifiable, Codable {
    @DocumentID var id: String?
    var title: String
    var description: String
    var date: Date
    var location: String
    var imageURLs: [String]
    var type: String
    var createdBy: String
    var participants: [String]
    var price: Double?
    var capacity: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case date
        case location
        case imageURLs
        case type
        case createdBy
        case participants
        case price
        case capacity
    }
}

struct EventFilters {
    var searchText: String = ""
    var selectedTypes: Set<String> = []
    var priceRange: ClosedRange<Double> = 0...1000
    var dateRange: ClosedRange<Date> = Date()...(Date().addingTimeInterval(31536000)) // One year from now
}

class EventViewModel: ObservableObject {
    @Published var events: [Event] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var filters = EventFilters()
    private var db = Firestore.firestore()
    
    var filteredEvents: [Event] {
        events.filter { event in
            let matchesSearch = filters.searchText.isEmpty || 
                event.title.localizedCaseInsensitiveContains(filters.searchText) ||
                event.description.localizedCaseInsensitiveContains(filters.searchText) ||
                event.type.localizedCaseInsensitiveContains(filters.searchText)
            
            let matchesType = filters.selectedTypes.isEmpty || 
                filters.selectedTypes.contains(event.type)
            
            let matchesPrice = event.price.map { filters.priceRange.contains($0) } ?? true
            
            let matchesDate = filters.dateRange.contains(event.date)
            
            return matchesSearch && matchesType && matchesPrice && matchesDate
        }
    }
    
    func fetchEvents() {
        isLoading = true
        print("Fetching events from Firebase...")
        
        db.collection("events")
            .order(by: "date", descending: true)
            .addSnapshotListener { [weak self] (querySnapshot, error) in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if let error = error {
                        print("Error fetching events: \(error.localizedDescription)")
                        self.errorMessage = error.localizedDescription
                        return
                    }
                    
                    guard let documents = querySnapshot?.documents else {
                        print("No documents found")
                        self.errorMessage = "No events found"
                        return
                    }
                    
                    print("Found \(documents.count) events")
                    
                    self.events = documents.compactMap { document -> Event? in
                        do {
                            var event = try document.data(as: Event.self)
                            if event.id == nil {
                                event.id = document.documentID
                            }
                            print("Successfully decoded event: \(event.title)")
                            return event
                        } catch {
                            print("Error decoding event: \(error)")
                            return nil
                        }
                    }
                    
                    if self.events.isEmpty {
                        print("No events were successfully decoded")
                        self.errorMessage = "No events available"
                    } else {
                        print("Successfully loaded \(self.events.count) events")
                        self.errorMessage = nil
                    }
                }
            }
    }
}

struct DiscoverView: View {
    @StateObject private var viewModel = EventViewModel()
    @State private var selectedEvent: Event?
    @State private var showEventDetail = false
    @State private var showFilters = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.clear.edgesIgnoringSafeArea(.all)
                
                VStack {
                    // Search and Filter Bar
                    HStack {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            
                            TextField("Search events...", text: $viewModel.filters.searchText)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        Button(action: { showFilters.toggle() }) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .foregroundColor(.blue)
                                .font(.title2)
                        }
                    }
                    .padding()
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(2)
                            .padding()
                    } else if viewModel.events.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "calendar.badge.exclamationmark")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            Text(viewModel.errorMessage ?? "No events available")
                                .foregroundColor(.gray)
                        }
                        .padding()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 20) {
                                ForEach(viewModel.filteredEvents) { event in
                                    EventCard(event: event)
                                        .onTapGesture {
                                            selectedEvent = event
                                            showEventDetail = true
                                        }
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Discover Events")
            .sheet(isPresented: $showEventDetail) {
                if let event = selectedEvent {
                    ViewEventDetail(event: event)
                }
            }
            .sheet(isPresented: $showFilters) {
                FilterView(filters: $viewModel.filters)
            }
        }
        .onAppear {
            if viewModel.events.isEmpty {
                viewModel.fetchEvents()
            }
        }
    }
}

struct FilterView: View {
    @Binding var filters: EventFilters
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Event Types")) {
                    // Add your event type toggles here
                    // Example:
                    // ForEach(eventTypes, id: \.self) { type in
                    //     Toggle(type, isOn: Binding(
                    //         get: { filters.selectedTypes.contains(type) },
                    //         set: { isSelected in
                    //             if isSelected {
                    //                 filters.selectedTypes.insert(type)
                    //             } else {
                    //                 filters.selectedTypes.remove(type)
                    //             }
                    //         }
                    //     ))
                    // }
                }
                
                Section(header: Text("Price Range")) {
                    // Add price range slider here
                }
                
                Section(header: Text("Date Range")) {
                    // Add date range picker here
                }
            }
            .navigationTitle("Filters")
            .navigationBarItems(
                leading: Button("Reset") {
                    filters = EventFilters()
                },
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

struct EventCard: View {
    let event: Event
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let imageURL = event.imageURLs.first {
                AsyncImage(url: URL(string: imageURL)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 200)
                            .clipped()
                    case .failure:
                        Image(systemName: "photo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 200)
                    @unknown default:
                        EmptyView()
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text(event.title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(event.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Image(systemName: "calendar")
                    Text(event.date, style: .date)
                    
                    Spacer()
                    
                    Image(systemName: "mappin.and.ellipse")
                    Text(event.location)
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding()
        }
        .background(Color.dynamic)
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .shadow(radius: 5)
    }
}

struct DiscoverView_Previews: PreviewProvider {
    static var previews: some View {
        DiscoverView()
    }
} 