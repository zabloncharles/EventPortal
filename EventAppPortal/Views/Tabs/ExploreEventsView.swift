import SwiftUI
import CoreLocation
import FirebaseFirestore

final class EventExploreFilterModel: ObservableObject {
    @Published var selectedCategory: String?
    @Published var maxPrice: ClosedRange<Double>
    @Published var radius: Double
    var categories: [String]

    init(
        selectedCategory: String? = nil,
        maxPrice: ClosedRange<Double> = 0...500,
        radius: Double = 50,
        categories: [String]
    ) {
        self.selectedCategory = selectedCategory
        self.maxPrice = maxPrice
        self.radius = radius
        self.categories = categories
    }
}

struct ExploreEventsView: View {
    @ObservedObject private var locationManager = LocationManager.shared
    @AppStorage("userID") private var userID: String = ""
    @State private var events: [Event] = []
    @State private var isLoading = true
    @State private var searchText = ""
    @State private var searchResults: [Event] = []
    @State private var isSearching = false
    @State private var searchTask: DispatchWorkItem?
    @StateObject private var filterModel = EventExploreFilterModel(categories: [
        "All", "Concert", "Corporate", "Marketing", "Health & Wellness",
        "Technology", "Art & Culture", "Charity", "Literature", "Lifestyle",
        "Environmental", "Entertainment"
    ])
    @State var showHorizontalCategory = false
    @State private var selectedCategoryForOverlay: String?
    @State var seeAllCategories = false
    @State private var showNotifications = false
    @State private var showError = false
    @State private var errorMessage: String?
    @EnvironmentObject private var firebaseManager: FirebaseManager

    private var filteredEvents: [Event] {
        if searchText.isEmpty && searchResults.isEmpty {
            return events
        }
        return searchResults
    }

    private var locationAreaHeadline: String {
        let raw = locationManager.locationString.trimmingCharacters(in: .whitespacesAndNewlines)
        if raw.isEmpty || raw == "Not Set" {
            return "Not Set"
        }
        let first = raw.split(separator: ",")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .first ?? ""
        if first.isEmpty || first == "Not Set" {
            return "Not Set"
        }
        return first
    }

    private var featuredEvent: Event? {
        let upcoming = events.filter { $0.startDate >= Date() }.sorted { $0.startDate < $1.startDate }
        return upcoming.first ?? events.first
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if isLoading && events.isEmpty {
                    ProgressView()
                        .padding(.top, 120)
                }
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        if !showHorizontalCategory && searchText.isEmpty, let event = featuredEvent {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Featured")
                                    .font(.headline)
                                    .padding(.horizontal)

                                NavigationLink(destination: ViewEventDetail(event: event)) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(Color.purple)

                                        HStack(alignment: .center) {
                                            VStack(alignment: .leading, spacing: 8) {
                                                Text(event.name)
                                                    .font(.title3)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(.white)
                                                    .multilineTextAlignment(.leading)
                                                Text(event.description)
                                                    .font(.subheadline)
                                                    .foregroundColor(.white.opacity(0.85))
                                                    .lineLimit(2)
                                                    .multilineTextAlignment(.leading)
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                HStack {
                                                    Image(systemName: "calendar")
                                                    Text(event.startDate, style: .date)
                                                    Image(systemName: "clock")
                                                    Text(event.startDate.formatted(date: .omitted, time: .shortened))
                                                }
                                                .font(.caption)
                                                .foregroundColor(.white.opacity(0.85))
                                            }
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            Spacer(minLength: 8)
                                            Image(systemName: "sparkles")
                                                .font(.system(size: 40))
                                                .foregroundColor(.white)
                                        }
                                        .padding()
                                    }
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal)
                            }
                        }

                        if searchText.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text("Event type")
                                        .font(.headline)
                                    Spacer()
                                    Button("See all") {
                                        withAnimation(.spring()) {
                                            seeAllCategories.toggle()
                                        }
                                    }
                                    .foregroundColor(.blue)
                                }
                                .padding(.horizontal)

                                eventTypeGrid
                            }
                        }

                        VStack(alignment: .leading, spacing: 16) {
                            Text(searchText.isEmpty ? (selectedCategoryForOverlay ?? "Popular") + " Events" : "Results")
                                .font(.headline)
                                .padding(.horizontal)

                            if filteredEvents.isEmpty {
                                HStack {
                                    Spacer()
                                    VStack(spacing: 12) {
                                        Image("hmm")
                                            .resizable()
                                            .renderingMode(.original)
                                            .aspectRatio(contentMode: .fit)
                                            .frame(height: 200)
                                        Text("Hmm! nothing yet..")
                                            .font(.subheadline)
                                            .fontWeight(.bold)
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                }
                            } else {
                                ForEach(filteredEvents.prefix(3)) { event in
                                    EventExploreCard(event: event)
                                }
                            }
                        }

                        if selectedCategoryForOverlay == nil || selectedCategoryForOverlay == "All" {
                            ForEach(filterModel.categories.filter { $0 != "All" }, id: \.self) { type in
                                ExploreEventCategorySection(eventType: type, events: events)
                            }
                        }
                    }
                    .padding(.top, 150)
                    .padding(.vertical)
                    .safeAreaInset(edge: .bottom) {
                        Color.clear.frame(height: 50)
                    }
                }
                .background(Color(.systemBackground))
                .navigationBarTitleDisplayMode(.inline)

                VStack(alignment: .leading) {
                    VStack {
                        HStack {
                            Button(action: {}) {
                                HStack {
                                    Text(locationAreaHeadline)
                                    Image(systemName: "chevron.down")
                                }
                            }
                            Spacer()
                        }
                        .padding(.horizontal)

                        HStack {
                            VStack(alignment: .leading) {
                                Text("Explore")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundStyle(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.purple, .blue]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                Text("find your next outing :)")
                                    .font(.headline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal)
                            Spacer()
                            HStack {
                                NavigationLink(destination: ChatHomeView()) {
                                    Image(systemName: "paperplane")
                                        .font(.title3)
                                        .foregroundColor(.blue)
                                }
                                Button(action: { showNotifications.toggle() }) {
                                    Image(systemName: "bell.fill")
                                        .font(.title3)
                                        .foregroundColor(.blue)
                                }
                                .padding(.trailing)
                            }
                        }
                        searchBar
                    }
                    .padding(.bottom, 15)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.dynamic, Color.dynamic, Color.dynamic.opacity(0.9)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    Spacer()
                }
            }
        }
        .onChange(of: searchText) { _ in
            searchEvents()
        }
        .onChange(of: filterModel.selectedCategory) { _ in
            searchEvents()
        }
        .onChange(of: filterModel.maxPrice) { _ in
            searchEvents()
        }
        .onChange(of: filterModel.radius) { _ in
            searchEvents()
        }
        .onChange(of: userID) { newId in
            if !newId.isEmpty {
                locationManager.fetchUserLocation(userId: newId)
            }
        }
        .onAppear {
            if filterModel.selectedCategory == nil {
                filterModel.selectedCategory = "All"
            }
            if !userID.isEmpty {
                locationManager.fetchUserLocation(userId: userID)
            }
            fetchEvents()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                searchEvents()
            }
        }
        .sheet(isPresented: $showNotifications) {
            ZStack {
                Color.dynamic.ignoresSafeArea()
                NotificationView()
                    .environmentObject(firebaseManager)
            }
        }
        .alert("Error", isPresented: $showError, presenting: errorMessage) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
        }
    }

    private var eventTypeGrid: some View {
        let cols = [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ]
        let list: [String] = {
            if showHorizontalCategory {
                return Array(filterModel.categories.prefix(seeAllCategories ? 8 : 4))
            }
            return filterModel.categories
        }()

        return LazyVGrid(columns: cols, spacing: 20) {
            ForEach(list, id: \.self) { category in
                eventTypeCell(category: category)
            }
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private func eventTypeCell(category: String) -> some View {
        VStack {
            Circle()
                .fill(eventTypeColor(category))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: eventTypeIcon(category))
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                )
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [.red, .orange, .yellow]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: selectedCategoryForOverlay == category ? 3 : 0
                        )
                )
            Text(category)
                .font(.caption)
                .multilineTextAlignment(.center)
        }
        .onTapGesture {
            withAnimation(.spring()) {
                selectedCategoryForOverlay = category
                showHorizontalCategory = true
                seeAllCategories = false
                filterModel.selectedCategory = category
                if let index = filterModel.categories.firstIndex(of: category) {
                    filterModel.categories.remove(at: index)
                    filterModel.categories.insert(category, at: category == "All" ? 0 : 1)
                }
            }
            searchEvents()
        }
    }

    private func eventTypeColor(_ type: String) -> Color {
        switch type {
        case "Concert": return .pink
        case "Corporate": return .blue
        case "Marketing": return .orange
        case "Health & Wellness": return .red
        case "Technology": return .cyan
        case "Art & Culture": return .purple
        case "Charity": return .green
        case "Literature": return .brown
        case "Lifestyle": return .mint
        case "Environmental": return .green.opacity(0.7)
        case "Entertainment": return .indigo
        default: return .gray
        }
    }

    private func eventTypeIcon(_ type: String) -> String {
        switch type {
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
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("Search events", text: $searchText)
            if isSearching {
                ProgressView()
                    .scaleEffect(0.8)
            }
            NavigationLink(
                destination: EventExploreFilterView(
                    selectedCategory: Binding(
                        get: { filterModel.selectedCategory },
                        set: { filterModel.selectedCategory = $0 }
                    ),
                    maxPrice: Binding(
                        get: { filterModel.maxPrice },
                        set: { filterModel.maxPrice = $0 }
                    ),
                    radius: Binding(
                        get: { filterModel.radius },
                        set: { filterModel.radius = $0 }
                    ),
                    categories: filterModel.categories
                )
            ) {
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
        .padding(.horizontal)
    }

    private func searchEvents() {
        searchTask?.cancel()
        let task = DispatchWorkItem {
            DispatchQueue.main.async {
                self.isSearching = true
            }

            var list = self.events

            if let cat = self.filterModel.selectedCategory, cat != "All" {
                list = list.filter { $0.type == cat }
            }

            if !self.searchText.isEmpty {
                let q = self.searchText
                list = list.filter {
                    $0.name.localizedCaseInsensitiveContains(q)
                        || $0.description.localizedCaseInsensitiveContains(q)
                        || $0.location.localizedCaseInsensitiveContains(q)
                        || $0.type.localizedCaseInsensitiveContains(q)
                }
            }

            list = list.filter { event in
                let priceVal = Self.parsedPrice(event.price)
                return priceVal >= self.filterModel.maxPrice.lowerBound && priceVal <= self.filterModel.maxPrice.upperBound
            }

            if let userLoc = self.locationManager.location {
                list = list.filter { event in
                    guard event.coordinates.count >= 2 else { return true }
                    let eloc = CLLocation(latitude: event.coordinates[0], longitude: event.coordinates[1])
                    let miles = userLoc.distance(from: eloc) / 1609.34
                    return miles <= self.filterModel.radius
                }
            }

            DispatchQueue.main.async {
                self.searchResults = list
                self.isSearching = false
            }
        }
        searchTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: task)
    }

    private static func parsedPrice(_ raw: String) -> Double {
        let s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.lowercased() == "free" { return 0 }
        let cleaned = s.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")
        return Double(cleaned) ?? 0
    }

    private func fetchEvents() {
        isLoading = true
        let db = Firestore.firestore()
        db.collection("events")
            .whereField("status", isEqualTo: "active")
            .limit(to: 80)
            .getDocuments { snapshot, error in
                DispatchQueue.main.async {
                    self.isLoading = false
                    if let error = error {
                        self.errorMessage = error.localizedDescription
                        self.showError = true
                        return
                    }
                    guard let docs = snapshot?.documents else {
                        self.events = []
                        self.searchEvents()
                        return
                    }
                    self.events = docs.compactMap { Self.parseEvent(document: $0) }
                    self.searchEvents()
                }
            }
    }

    private static func coordinatesFromEventData(_ data: [String: Any]) -> [Double] {
        if let arr = data["coordinates"] as? [Double], arr.count >= 2 {
            return [arr[0], arr[1]]
        }
        if let arr = data["coordinates"] as? [NSNumber], arr.count >= 2 {
            return [arr[0].doubleValue, arr[1].doubleValue]
        }
        if let lat = data["latitude"] as? Double, let lon = data["longitude"] as? Double {
            return [lat, lon]
        }
        if let lat = data["latitude"] as? NSNumber, let lon = data["longitude"] as? NSNumber {
            return [lat.doubleValue, lon.doubleValue]
        }
        return []
    }

    private static func priceStringFromFirestore(_ data: [String: Any]) -> String {
        if let s = data["price"] as? String { return s }
        if let n = data["price"] as? Int { return String(n) }
        if let n = data["price"] as? Double { return n == floor(n) ? String(format: "%.0f", n) : String(n) }
        if let n = data["price"] as? NSNumber { return n.stringValue }
        return "0"
    }

    private static func parseEvent(document: QueryDocumentSnapshot) -> Event? {
        let data = document.data()
        guard let name = data["name"] as? String,
              let startDate = (data["startDate"] as? Timestamp)?.dateValue(),
              let endDate = (data["endDate"] as? Timestamp)?.dateValue(),
              let status = data["status"] as? String else {
            return nil
        }
        let description = data["description"] as? String ?? ""
        let type = data["type"] as? String ?? "Other"
        let location = data["location"] as? String ?? ""
        let price = priceStringFromFirestore(data)
        let owner = data["owner"] as? String ?? ""
        let organizerName = data["organizerName"] as? String ?? ""
        let shareContactInfo = data["shareContactInfo"] as? Bool ?? false
        let isTimed = data["isTimed"] as? Bool ?? true
        let coordinates = coordinatesFromEventData(data)
        let images = data.firestoreEventImageStrings()
        let maxParticipants = data["maxParticipants"] as? Int ?? 0
        let participants = data["participants"] as? [String] ?? []
        let eventId = (data["id"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? document.documentID
        return Event(
            id: eventId,
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
            maxParticipants: max(1, maxParticipants),
            isTimed: isTimed,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
            coordinates: coordinates,
            status: status
        )
    }
}

struct EventExploreCard: View {
    let event: Event
    private let colors: [Color] = [.red, .blue, .green, .purple, .orange]

    var body: some View {
        NavigationLink(destination: ViewEventDetail(event: event)) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(event.name)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [colors.randomElement() ?? .blue, .purple]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    Text(event.description)
                        .font(.subheadline)
                        .foregroundColor(Color.invert.opacity(0.8))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                            Text(event.startDate, style: .date)
                        }
                        HStack(spacing: 4) {
                            Image(systemName: "dollarsign.circle")
                            Text(event.price)
                        }
                    }
                    .font(.caption)
                    .foregroundColor(Color.invert.opacity(0.8))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Spacer(minLength: 8)
                Image(systemName: iconName(for: event.type))
                    .font(.system(size: 30))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [colors.randomElement() ?? .blue, .purple]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            .padding()
        }
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.invert.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal)
    }

    private func iconName(for type: String) -> String {
        switch type {
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
    }
}

enum ExploreCategoryEventSortOption: String, CaseIterable, Identifiable, Hashable {
    case startDateAscending
    case startDateDescending
    case nameAscending
    case nameDescending
    case priceAscending
    case priceDescending

    var id: String { rawValue }

    var title: String {
        switch self {
        case .startDateAscending: return "Date · soonest first"
        case .startDateDescending: return "Date · latest first"
        case .nameAscending: return "Name · A to Z"
        case .nameDescending: return "Name · Z to A"
        case .priceAscending: return "Price · low to high"
        case .priceDescending: return "Price · high to low"
        }
    }

    func sorted(_ events: [Event]) -> [Event] {
        switch self {
        case .startDateAscending:
            return events.sorted { $0.startDate < $1.startDate }
        case .startDateDescending:
            return events.sorted { $0.startDate > $1.startDate }
        case .nameAscending:
            return events.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .nameDescending:
            return events.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedDescending }
        case .priceAscending:
            return events.sorted { Self.priceValue($0) < Self.priceValue($1) }
        case .priceDescending:
            return events.sorted { Self.priceValue($0) > Self.priceValue($1) }
        }
    }

    static func isEffectivelyFree(_ event: Event) -> Bool {
        priceValue(event) == 0
    }

    private static func priceValue(_ event: Event) -> Double {
        let s = event.price.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.lowercased() == "free" { return 0 }
        let cleaned = s.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")
        return Double(cleaned) ?? 0
    }
}

struct ExploreCategoryEventsSortView: View {
    @Binding var sortOption: ExploreCategoryEventSortOption
    @Binding var freeEventsOnly: Bool
    @State private var draftSort: ExploreCategoryEventSortOption = .startDateAscending
    @State private var draftFreeOnly = false

    var body: some View {
        Form {
            Section {
                Toggle("Free events only", isOn: $draftFreeOnly)
            }
            Section("Sort order") {
                Picker("Sort order", selection: $draftSort) {
                    ForEach(ExploreCategoryEventSortOption.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }
                .pickerStyle(.inline)
            }
        }
        .navigationTitle("Sort & filter")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.dynamic, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .scrollContentBackground(.hidden)
        .background(Color.dynamic)
        .onAppear {
            draftSort = sortOption
            draftFreeOnly = freeEventsOnly
        }
        .onDisappear {
            sortOption = draftSort
            freeEventsOnly = draftFreeOnly
        }
    }
}

struct ExploreCategoryEventsListView: View {
    let eventType: String
    let events: [Event]
    @State private var sortOption: ExploreCategoryEventSortOption = .startDateAscending
    @State private var freeEventsOnly = false

    private var displayedEvents: [Event] {
        let base = freeEventsOnly ? events.filter { ExploreCategoryEventSortOption.isEffectivelyFree($0) } : events
        return sortOption.sorted(base)
    }

    var body: some View {
        ZStack {
            Color.dynamic.ignoresSafeArea()
            if events.isEmpty {
                VStack(spacing: 12) {
                    Image("hmm")
                        .resizable()
                        .renderingMode(.original)
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 200)
                    Text("Hmm! nothing yet..")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if displayedEvents.isEmpty {
                VStack(spacing: 12) {
                    Image("hmm")
                        .resizable()
                        .renderingMode(.original)
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 200)
                    Text("No events match your filters")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(displayedEvents) { event in
                            NavigationLink(destination: ViewEventDetail(event: event)) {
                                PopularEventCard(event: event)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 10)
                    .padding(.horizontal)
                }
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("\(eventType) Events")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.dynamic, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    ExploreCategoryEventsSortView(sortOption: $sortOption, freeEventsOnly: $freeEventsOnly)
                } label: {
                    Image(systemName: "arrow.up.arrow.down.circle")
                        .foregroundStyle(.primary)
                }
            }
        }
    }
}

struct ExploreEventCategorySection: View {
    let eventType: String
    let events: [Event]

    private var filtered: [Event] {
        events.filter { $0.type == eventType }
    }

    var body: some View {
        if !filtered.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(eventType + " Events")
                        .font(.headline)
                    Spacer()
                    NavigationLink(destination: ExploreCategoryEventsListView(eventType: eventType, events: filtered)) {
                        Text("View All")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)

                ForEach(filtered.prefix(3)) { event in
                    EventExploreCard(event: event)
                }
            }
        }
    }
}

struct EventExploreFilterView: View {
    @Binding var selectedCategory: String?
    @Binding var maxPrice: ClosedRange<Double>
    @Binding var radius: Double
    let categories: [String]
    @Environment(\.presentationMode) var presentationMode
    @State private var showAllCategories = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Spacer()
                    Image("smilepov")
                        .resizable()
                        .renderingMode(.original)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 160, height: 160)
                    Spacer()
                }

                HStack {
                    Text("Event type")
                        .font(.headline)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 12) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(categories.prefix(showAllCategories ? categories.count : 5), id: \.self) { cat in
                                CategoryPill(text: cat, isSelected: selectedCategory == cat) {
                                    selectedCategory = cat
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)

                Button(showAllCategories ? "Show less" : "Show all types") {
                    showAllCategories.toggle()
                }
                .font(.subheadline)
                .foregroundColor(.blue)
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Ticket price range")
                            .font(.headline)
                        Spacer()
                        Text("$\(Int(maxPrice.lowerBound))–$\(Int(maxPrice.upperBound))")
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)
                    GroupRangeSlider(range: $maxPrice, in: 0...500)
                        .frame(height: 44)
                        .padding(.horizontal, 10)
                }

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Distance")
                            .font(.headline)
                        Spacer()
                        Text("\(Int(radius)) mi")
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)
                    Slider(value: $radius, in: 5...100, step: 1)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical, 24)
        }
        .background(Color.dynamic)
        .navigationTitle("Filters")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}

struct ExploreEventsView_Previews: PreviewProvider {
    static var previews: some View {
        ExploreEventsView()
            .environmentObject(FirebaseManager.shared)
    }
}
