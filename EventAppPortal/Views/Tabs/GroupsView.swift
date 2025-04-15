import SwiftUI
import CoreLocation
import FirebaseFirestore
import FirebaseAuth

// Add this before the GroupsView struct
class GroupFilterModel: ObservableObject {
    @Published var selectedCategory: String?
    @Published var memberCountRange: ClosedRange<Double>
    @Published var radius: Double
    let categories: [String]
    
    init(selectedCategory: String? = nil,
         memberCountRange: ClosedRange<Double> = 0...500,
         radius: Double = 50,
         categories: [String]) {
        self.selectedCategory = selectedCategory
        self.memberCountRange = memberCountRange
        self.radius = radius
        self.categories = categories
    }
}

struct GroupsView: View {
    @StateObject private var locationManager = LocationManager.shared
    @State private var groups: [EventGroup] = []
    @State private var isLoading = true
    @State private var selectedGroup: EventGroup?
    @State private var showingJoinConfirmation = false
    @State private var searchText = ""
    @StateObject private var filterModel = GroupFilterModel(categories: ["All", "Sports", "Music", "Art", "Technology", "Food", "Travel", "Other"])
    @State private var isUploading = false
    @State private var showUploadAlert = false
    @State private var uploadMessage = ""
    @State private var showingFilterSheet = false
    
    private let radiusInMiles: Double = 50
    
    // Preview initializer
    init(previewGroups: [EventGroup]? = nil) {
        if let previewGroups = previewGroups {
            _groups = State(initialValue: previewGroups)
            _isLoading = State(initialValue: false)
        }
    }
    
    var filteredGroups: [EventGroup] {
        groups.filter { group in
            let matchesSearch = searchText.isEmpty || 
                group.name.localizedCaseInsensitiveContains(searchText) ||
                group.description.localizedCaseInsensitiveContains(searchText)
            
            let matchesCategory = filterModel.selectedCategory == nil || 
                filterModel.selectedCategory == "All" || 
                group.category == filterModel.selectedCategory
            
            let matchesMemberCount = Double(group.memberCount) >= filterModel.memberCountRange.lowerBound &&
                Double(group.memberCount) <= filterModel.memberCountRange.upperBound
            
            let matchesRadius = locationManager.location.map { userLocation in
                let groupLocation = CLLocation(
                    latitude: group.location.latitude,
                    longitude: group.location.longitude
                )
                let distanceInMiles = userLocation.distance(from: groupLocation) / 1609.34
                return distanceInMiles <= filterModel.radius
            } ?? true
            
            return matchesSearch && matchesCategory && matchesMemberCount && matchesRadius
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
            
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading) {
                        HStack{
                            Button(action: {}) {
                                HStack {
                                    Text("Abuja, Nigeria")
                                    Image(systemName: "chevron.down")
                                }
                            }
                            Spacer()
                        }.padding(.horizontal)
                        
                        VStack(alignment: .leading) {
                            Text("Groups")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundStyle(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.purple, .blue]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            Text("join a family :)")
                                .font(.headline)
                                .fontWeight(.medium)
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal)
                    }
                    
                    
                    searchBar
                    
                    // Upcoming Group Meeting
                    if let nextGroup = groups.first {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Upcoming Meeting")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ZStack {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.blue)
                                
                                HStack {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(nextGroup.name)
                                            .font(.title3)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                        Text(nextGroup.shortDescription)
                                            .font(.subheadline)
                                            .foregroundColor(.white.opacity(0.8))
                                        HStack {
                                            Image(systemName: "calendar")
                                            Text("Next: \(Date().addingTimeInterval(86400), style: .date)")
                                            Image(systemName: "clock")
                                            Text("10:00 - 13:00")
                                        }
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                    }
                                    
                                    Spacer()
                                    
                                    Button(action: {}) {
                                        Image(systemName: "phone.circle.fill")
                                            .font(.system(size: 44))
                                            .foregroundColor(.white)
                                    }
                                }
                                .padding()
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Categories Grid
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Groups specialty")
                                .font(.headline)
                            Spacer()
                            Button("See all") {
                                // Action
                            }
                            .foregroundColor(.blue)
                        }
                        .padding(.horizontal)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 20) {
                            ForEach(filterModel.categories.prefix(8), id: \.self) { category in
                                VStack {
                                    Circle()
                                        .fill(categoryColor(for: category))
                                        .frame(width: 60, height: 60)
                                        .overlay(
                                            Image(systemName: categoryIcon(for: category))
                                                .font(.system(size: 24))
                                                .foregroundColor(.white)
                                        )
                                    Text(category)
                                        .font(.caption)
                                        .multilineTextAlignment(.center)
                                }
                                .onTapGesture {
                                    filterModel.selectedCategory = category
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Popular Groups
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Popular Groups")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(filteredGroups.prefix(3)) { group in
                            GroupCard(group: group)
                        }
                    }
                }
                .padding(.vertical)
                // Add safe area and tabbar padding at the bottom
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: 50) // Account for tabbar height + extra padding
                }
            }
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            
        }
        .onAppear {
            fetchNearbyGroups()
        }
    }
    
    private func categoryColor(for category: String) -> Color {
        switch category {
        case "Sports": return .blue
        case "Music": return .pink
        case "Art": return .purple
        case "Technology": return .orange
        case "Food": return .green
        case "Travel": return .yellow
        default: return .gray
        }
    }
    
    private func categoryIcon(for category: String) -> String {
        switch category {
        case "Sports": return "figure.run"
        case "Music": return "music.note"
        case "Art": return "paintbrush.fill"
        case "Technology": return "laptopcomputer"
        case "Food": return "fork.knife"
        case "Travel": return "airplane"
        default: return "star.fill"
        }
    }
    
    private func fetchNearbyGroups() {
        print("Starting to fetch groups...")
        
        let db = Firestore.firestore()
        
        // Remove location check temporarily to see all groups
        db.collection("groups")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Error fetching groups: \(error.localizedDescription)")
                    isLoading = false
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("❌ No documents found in snapshot")
                    isLoading = false
                    return
                }
                
                print("📄 Found \(documents.count) documents in Firestore")
                
                // Print the first document to verify structure
                if let firstDoc = documents.first {
                    print("📝 First document data: \(firstDoc.data())")
                }
                
                groups = documents.compactMap { document in
                    do {
                        if let group = EventGroup.fromFirestore(document) {
                            print("✅ Successfully parsed group: \(group.name)")
                            return group
                        } else {
                            print("❌ Failed to parse group from document: \(document.documentID)")
                            print("Document data: \(document.data())")
                            return nil
                        }
                    } catch {
                        print("❌ Error parsing group: \(error)")
                        return nil
                    }
                }
                
                print("📊 Successfully loaded \(groups.count) groups")
                print("Groups: \(groups.map { $0.name })")
                isLoading = false
            }
    }
    
    private func joinGroup(_ group: EventGroup) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let groupRef = db.collection("groups").document(group.id)
        
        groupRef.updateData([
            "pendingRequests": FieldValue.arrayUnion([userId])
        ]) { error in
            if let error = error {
                print("Error joining group: \(error)")
            }
        }
    }
    
    private func uploadSampleGroups() {
        guard let userId = Auth.auth().currentUser?.uid else {
            uploadMessage = "Please sign in to upload groups"
            showUploadAlert = true
            return
        }
        
        isUploading = true
        let db = Firestore.firestore()
        let batch = db.batch()
        
        for group in sampleGroups {
            let groupRef = db.collection("groups").document()
            let groupData = group.toFirestore()
            batch.setData(groupData, forDocument: groupRef)
        }
        
        batch.commit { error in
            isUploading = false
            if let error = error {
                uploadMessage = "Error uploading groups: \(error.localizedDescription)"
            } else {
                uploadMessage = "Successfully uploaded \(sampleGroups.count) groups"
                fetchNearbyGroups() // Refresh the groups list
            }
            showUploadAlert = true
        }
    }
    
    var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("Search groups", text: $searchText)
            NavigationLink(destination: GroupFilterView(
                isPresented: $showingFilterSheet,
                selectedCategory: .init(get: { filterModel.selectedCategory }, set: { filterModel.selectedCategory = $0 }),
                memberCountRange: .init(get: { filterModel.memberCountRange }, set: { filterModel.memberCountRange = $0 }),
                radius: .init(get: { filterModel.radius }, set: { filterModel.radius = $0 }),
                categories: filterModel.categories
            )) {
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
        .padding(.horizontal)
    }
}

struct GroupCard: View {
    let group: EventGroup
    let colors =  [Color.red,Color.blue,Color.green,Color.purple,Color.orange]
    var body: some View {
        NavigationLink(destination: GroupDetailView(group: group)) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.clear)
                
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(group.name)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [colors.randomElement() ?? Color.red, .blue]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        Text(group.shortDescription)
                            .font(.subheadline)
                            .foregroundColor(Color.invert.opacity(0.8))
                            .lineLimit(2)
                        
                        HStack(spacing: 12) {
                            HStack(spacing: 4) {
                                Image(systemName: "person.2")
                                Text("\(group.memberCount) members")
                            }
                            
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                Text("4.9")
                            }
                        }
                        .font(.caption)
                        .foregroundColor(Color.invert.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    Image(systemName: categoryIcon(for: group.category))
                        .font(.system(size: 44))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [colors.randomElement() ?? Color.red, .blue]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                .padding()
            }
            
        }.overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.invert.opacity(0.20), lineWidth: 1)
        )
        .padding(.horizontal)
        
    }
    
    private func categoryIcon(for category: String) -> String {
        switch category {
        case "Sports": return "figure.run"
        case "Music": return "music.note"
        case "Art": return "paintbrush.fill"
        case "Technology": return "desktopcomputer"
        case "Food": return "fork.knife"
        case "Travel": return "airplane"
        case "Environmental": return "leaf.arrow.triangle.circlepath"
        case "Literature": return "book.fill"
        case "Corporate": return "building.2.fill"
        case "Health & Wellness": return "heart.fill"
        default: return "star.fill"
        }
    }
}

struct GroupDetailView: View {
    let group: EventGroup
    @Environment(\.presentationMode) var presentationMode
    @State private var showJoinAlert = false
    @State private var scrollOffset: CGFloat = 0
    let colors = [Color.red, Color.blue, Color.green, Color.purple, Color.orange]
    @StateObject private var tabBarManager = TabBarVisibilityManager.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero Section with Parallax
                GeometryReader { geometry in
                    let minY = geometry.frame(in: .global).minY
                    ZStack {
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, .blue]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .opacity(0.9)
                        .frame(height: 300 + (minY > 0 ? minY : 0))
                        .offset(y: minY > 0 ? -minY : 0)
                        
                        VStack {
                            Spacer()
                            HStack {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(group.name)
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    Text(group.category)
                                        .font(.headline)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                Spacer()
                                
                                Image(systemName: categoryIcon(for: group.category))
                                    .font(.system(size: 60))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 50)
                        }
                    }
                }
                .frame(height: 300)
                
                // Content Section
                VStack(spacing: 24) {
                    // Admin Card
                    HStack(spacing: 16) {
                        Circle()
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [colors.randomElement() ?? .blue, .blue]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Text(group.createdBy.prefix(1).uppercased())
                                    .font(.title2.bold())
                                    .foregroundColor(.white)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(group.createdBy)
                                .font(.title3)
                                .fontWeight(.semibold)
                            Text("Group Admin")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Button(action: {}) {
                            Text("Message")
                                .font(.subheadline.bold())
                                .foregroundColor(.blue)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(20)
                    
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    
                    // Stats Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        StatCard(title: "Members", value: "\(group.memberCount)")
                        StatCard(title: "Rating", value: "4.9")
                        StatCard(title: "Posts", value: "\(group.tags.count)")
                    }
                    
                    // Description Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("About")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(group.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    
                    // Tags Cloud
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Topics")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        FlowLayout(spacing: 8) {
                            ForEach(group.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.subheadline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(12)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    
                    // Members Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Members")
                                .font(.title2)
                                .fontWeight(.bold)
                            Spacer()
                            Button("See All") {
                                // Action
                            }
                            .foregroundColor(.blue)
                        }
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(group.members.prefix(6), id: \.self) { member in
                                    VStack(spacing: 8) {
                                        Circle()
                                            .fill(LinearGradient(
                                                gradient: Gradient(colors: [colors.randomElement() ?? .blue, .blue]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ))
                                            .frame(width: 60, height: 60)
                                            .overlay(
                                                Text(member.prefix(1).uppercased())
                                                    .font(.title2.bold())
                                                    .foregroundColor(.white)
                                            )
                                        
                                        Text(member.split(separator: "@").first ?? "")
                                            .font(.caption)
                                            .lineLimit(1)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                   
                    
                    
                    //Join Group Section
                    // Join Button
                    VStack {
                        Button(action: { showJoinAlert = true }) {
                            Text("Join Group")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [colors.randomElement() ?? .blue, .blue]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(20)
                   
                                .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                                .padding()
                        }
                       
                    }
                }
                .padding()
                .background(Color.dynamic)
            }
        }.navigationBarBackButtonHidden()
        .edgesIgnoringSafeArea(.top)
        .onAppear{
            tabBarManager.hideTab = true
        }
        .overlay(
            // Navigation Bar
            HStack {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                }
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title3)
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                }
            }
            .padding()
            .padding(.top, 0)
            , alignment: .top
        )
        
        .alert("Join Group", isPresented: $showJoinAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Join") {
                // Handle join action
            }
        } message: {
            Text("Would you like to join \(group.name)?")
        }
    }
    
    private func categoryIcon(for category: String) -> String {
        switch category {
        case "Sports": return "figure.run"
        case "Music": return "music.note"
        case "Art": return "paintbrush.fill"
        case "Technology": return "desktopcomputer"
        case "Food": return "fork.knife"
        case "Travel": return "airplane"
        case "Environmental": return "leaf.arrow.triangle.circlepath"
        case "Literature": return "book.fill"
        case "Corporate": return "building.2.fill"
        case "Health & Wellness": return "heart.fill"
        default: return "star.fill"
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        return computeSize(rows: rows, proposal: proposal)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        placeRows(rows, in: bounds)
    }
    
    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[LayoutSubviews.Element]] {
        var rows: [[LayoutSubviews.Element]] = [[]]
        var currentRow = 0
        var remainingWidth = proposal.width ?? 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(proposal)
            if size.width > remainingWidth {
                currentRow += 1
                rows.append([])
                remainingWidth = (proposal.width ?? 0) - size.width - spacing
            } else {
                remainingWidth -= size.width + spacing
            }
            rows[currentRow].append(subview)
        }
        return rows
    }
    
    private func computeSize(rows: [[LayoutSubviews.Element]], proposal: ProposedViewSize) -> CGSize {
        var height: CGFloat = 0
        for row in rows {
            let rowHeight = row.map { $0.sizeThatFits(proposal).height }.max() ?? 0
            height += rowHeight + spacing
        }
        return CGSize(width: proposal.width ?? 0, height: height)
    }
    
    private func placeRows(_ rows: [[LayoutSubviews.Element]], in bounds: CGRect) {
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            for subview in row {
                let size = subview.sizeThatFits(.unspecified)
                subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += rowHeight + spacing
        }
    }
}

// Sample groups for previews
let sampleGroups = [
    EventGroup(
        id: "1",
        name: "Tech Enthusiasts NYC",
        description: "A community of tech lovers in New York City. We meet weekly to discuss the latest in technology, share knowledge, and network with fellow tech enthusiasts.",
        shortDescription: "Weekly tech meetups and discussions in NYC",
        memberCount: 156,
        imageURL: "desktopcomputer",
        location: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
        createdAt: Date(),
        createdBy: "user1",
        isPrivate: false,
        category: "Technology",
        tags: ["Programming", "AI", "Networking"],
        pendingRequests: [],
        members: ["user1", "user2", "user3"],
        admins: ["user1"]
    ),
    EventGroup(
        id: "2",
        name: "Foodies United",
        description: "Join us for culinary adventures! We explore new restaurants, share recipes, and host cooking workshops. From street food to fine dining, we celebrate all things food.",
        shortDescription: "Exploring culinary delights together",
        memberCount: 89,
        imageURL: "leaf.fill",
        location: CLLocationCoordinate2D(latitude: 40.7589, longitude: -73.9851),
        createdAt: Date().addingTimeInterval(-86400),
        createdBy: "user2",
        isPrivate: false,
        category: "Lifestyle",
        tags: ["Cooking", "Restaurants", "Recipes"],
        pendingRequests: [],
        members: ["user2", "user4", "user5"],
        admins: ["user2"]
    ),
    EventGroup(
        id: "3",
        name: "Art & Design Collective",
        description: "A vibrant community of artists and designers. We organize exhibitions, workshops, and collaborative projects. All skill levels welcome!",
        shortDescription: "Creative community for artists and designers",
        memberCount: 234,
        imageURL: "paintbrush.fill",
        location: CLLocationCoordinate2D(latitude: 40.7829, longitude: -73.9654),
        createdAt: Date().addingTimeInterval(-172800),
        createdBy: "user3",
        isPrivate: false,
        category: "Art & Culture",
        tags: ["Design", "Exhibition", "Workshop"],
        pendingRequests: [],
        members: ["user3", "user6", "user7", "user8"],
        admins: ["user3"]
    ),
    EventGroup(
        id: "4",
        name: "Fitness Warriors",
        description: "Get fit together! We organize group workouts, running sessions, and fitness challenges. Motivation and support guaranteed!",
        shortDescription: "Group workouts and fitness challenges",
        memberCount: 178,
        imageURL: "figure.dance",
        location: CLLocationCoordinate2D(latitude: 40.7549, longitude: -73.9840),
        createdAt: Date().addingTimeInterval(-259200),
        createdBy: "user4",
        isPrivate: false,
        category: "Sports",
        tags: ["Fitness", "Workout", "Running"],
        pendingRequests: [],
        members: ["user4", "user9", "user10"],
        admins: ["user4"]
    ),
    EventGroup(
        id: "5",
        name: "Music Lovers Club",
        description: "Share your passion for music! We organize concerts, jam sessions, and music appreciation meetups. All genres welcome!",
        shortDescription: "Music appreciation and jam sessions",
        memberCount: 145,
        imageURL: "music.note.list",
        location: CLLocationCoordinate2D(latitude: 40.7580, longitude: -73.9855),
        createdAt: Date().addingTimeInterval(-345600),
        createdBy: "user5",
        isPrivate: false,
        category: "Entertainment",
        tags: ["Concerts", "Jam Sessions", "Music"],
        pendingRequests: [],
        members: ["user5", "user11", "user12"],
        admins: ["user5"]
    ),
    EventGroup(
        id: "6",
        name: "Environmental Action Group",
        description: "Join us in making a difference for our planet! We organize cleanups, tree plantings, and educational events about sustainability.",
        shortDescription: "Making a difference for our planet",
        memberCount: 112,
        imageURL: "leaf.arrow.triangle.circlepath",
        location: CLLocationCoordinate2D(latitude: 40.7500, longitude: -73.9900),
        createdAt: Date().addingTimeInterval(-432000),
        createdBy: "user6",
        isPrivate: false,
        category: "Environmental",
        tags: ["Sustainability", "Cleanup", "Education"],
        pendingRequests: [],
        members: ["user6", "user13", "user14"],
        admins: ["user6"]
    ),
    EventGroup(
        id: "7",
        name: "Book Lovers Society",
        description: "A community for book enthusiasts! We discuss literature, host author meetups, and organize book swaps.",
        shortDescription: "For book enthusiasts and readers",
        memberCount: 98,
        imageURL: "book.fill",
        location: CLLocationCoordinate2D(latitude: 40.7600, longitude: -73.9800),
        createdAt: Date().addingTimeInterval(-518400),
        createdBy: "user7",
        isPrivate: false,
        category: "Literature",
        tags: ["Books", "Reading", "Authors"],
        pendingRequests: [],
        members: ["user7", "user15", "user16"],
        admins: ["user7"]
    ),
    EventGroup(
        id: "8",
        name: "Corporate Networking",
        description: "Connect with professionals from various industries. Perfect for career growth, mentorship, and business opportunities.",
        shortDescription: "Professional networking and career growth",
        memberCount: 267,
        imageURL: "building.2.fill",
        location: CLLocationCoordinate2D(latitude: 40.7450, longitude: -73.9950),
        createdAt: Date().addingTimeInterval(-604800),
        createdBy: "user8",
        isPrivate: false,
        category: "Corporate",
        tags: ["Networking", "Career", "Business"],
        pendingRequests: [],
        members: ["user8", "user17", "user18", "user19"],
        admins: ["user8"]
    ),
    EventGroup(
        id: "9",
        name: "Health & Wellness Community",
        description: "Focus on mental and physical well-being. We offer meditation sessions, wellness workshops, and support groups.",
        shortDescription: "Mental and physical well-being support",
        memberCount: 143,
        imageURL: "heart.fill",
        location: CLLocationCoordinate2D(latitude: 40.7700, longitude: -73.9750),
        createdAt: Date().addingTimeInterval(-691200),
        createdBy: "user9",
        isPrivate: false,
        category: "Health & Wellness",
        tags: ["Meditation", "Wellness", "Support"],
        pendingRequests: [],
        members: ["user9", "user20", "user21"],
        admins: ["user9"]
    ),
    EventGroup(
        id: "10",
        name: "Other Interests Group",
        description: "A diverse group for various interests that don't fit into other categories. Share your unique hobbies and discover new ones!",
        shortDescription: "For diverse and unique interests",
        memberCount: 76,
        imageURL: "calendar",
        location: CLLocationCoordinate2D(latitude: 40.7550, longitude: -73.9700),
        createdAt: Date().addingTimeInterval(-777600),
        createdBy: "user10",
        isPrivate: false,
        category: "Other",
        tags: ["Diverse", "Unique", "Hobbies"],
        pendingRequests: [],
        members: ["user10", "user22", "user23"],
        admins: ["user10"]
    )
]

struct GroupsView_Previews: PreviewProvider {
    static var previews: some View {
        //GroupsView(previewGroups: sampleGroups)
        GroupDetailView(group: sampleGroups[0])
    }
}

struct GroupFilterView: View {
    @Binding var isPresented: Bool
    @Binding var selectedCategory: String?
    @Binding var memberCountRange: ClosedRange<Double>
    @Binding var radius: Double
    let categories: [String]
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        Form {
            Section(header: Text("Group Type")) {
                ForEach(categories, id: \.self) { category in
                    HStack {
                        Text(category)
                        Spacer()
                        if category == selectedCategory {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedCategory = category
                    }
                }
            }
            
            Section(header: Text("Member Count")) {
                VStack {
                    HStack {
                        Text("\(Int(memberCountRange.lowerBound))")
                        Spacer()
                        Text("\(Int(memberCountRange.upperBound))")
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                    
                    GroupRangeSlider(range: $memberCountRange, in: 0...500)
                        .frame(height: 44)
                }
            }
            
            Section(header: Text("Distance")) {
                VStack(alignment: .leading) {
                    HStack {
                        Text("\(Int(radius)) miles")
                            .font(.headline)
                        Spacer()
                    }
                    
                    Slider(value: $radius, in: 1...100, step: 1)
                }
            }
        }
        .navigationTitle("Group Filters")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Reset") {
                    selectedCategory = "All"
                    memberCountRange = 0...500
                    radius = 50
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}

struct GroupRangeSlider: View {
    @Binding var range: ClosedRange<Double>
    let bounds: ClosedRange<Double>
    
    init(range: Binding<ClosedRange<Double>>, in bounds: ClosedRange<Double>) {
        self._range = range
        self.bounds = bounds
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 4)
                
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: CGFloat((range.upperBound - range.lowerBound) / (bounds.upperBound - bounds.lowerBound)) * geometry.size.width,
                           height: 4)
                    .offset(x: CGFloat((range.lowerBound - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound)) * geometry.size.width)
                
                HStack(spacing: 0) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 24, height: 24)
                        .shadow(radius: 4)
                        .offset(x: CGFloat((range.lowerBound - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound)) * geometry.size.width)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let newValue = bounds.lowerBound + Double(value.location.x / geometry.size.width) * (bounds.upperBound - bounds.lowerBound)
                                    range = min(max(newValue, bounds.lowerBound), range.upperBound - 1)...range.upperBound
                                }
                        )
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: 24, height: 24)
                        .shadow(radius: 4)
                        .offset(x: CGFloat((range.upperBound - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound)) * geometry.size.width - 24)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let newValue = bounds.lowerBound + Double(value.location.x / geometry.size.width) * (bounds.upperBound - bounds.lowerBound)
                                    range = range.lowerBound...max(min(newValue, bounds.upperBound), range.lowerBound + 1)
                                }
                        )
                }
            }
        }
    }
} 
