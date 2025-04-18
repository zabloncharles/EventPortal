import SwiftUI
import CoreLocation
import FirebaseFirestore
import FirebaseAuth

// Add this before the GroupsView struct
class GroupFilterModel: ObservableObject {
    @Published var selectedCategory: String?
    @Published var memberCountRange: ClosedRange<Double>
    @Published var radius: Double
    var categories: [String]
    
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
    @State var showHorizontalCategory = false
    @State private var selectedCategoryForOverlay: String? = nil
    @State private var showNotifications = false
    @State private var showError = false
    @State private var errorMessage: String?
   
    private let radiusInMiles: Double = 50
    @State var seeAllCategories = false
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
            ZStack {
                ScrollView(showsIndicators: false) {
                
                    VStack(alignment: .leading, spacing: 24) {
                        
                        
                        
                        
                        
                        // Upcoming Group Meeting
                        if !showHorizontalCategory {
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
                                            Image(systemName: "bird.fill")
                                                .font(.system(size: 44))
                                                .foregroundColor(Color.white)
                                        }
                                    }
                                    .padding()
                                }
                                .padding(.horizontal)
                            }.padding(.top, 155)
                        }
                    }
                        
                        // Categories Grid
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Group Category")
                                    .font(.headline)
                                Spacer()
                                Button("See all") {
                                    // Action
                                    withAnimation(.spring()) {
                                        seeAllCategories.toggle()
                                        
                                    }
                                }
                                .foregroundColor(.blue)
                            }
                            .padding(.horizontal)
                            
                           if showHorizontalCategory  {
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible()),
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: 20) {
                                    ForEach(filterModel.categories.prefix(seeAllCategories ? 8 : 4), id: \.self) { category in
                                        VStack {
                                            Circle()
                                                .fill(categoryColor(for: category))
                                                .frame(width: 60, height: 60)
                                                .overlay(
                                                    Image(systemName: categoryIcon(for: category))
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
                                            
                                        }
                                    }
                                }
                            .padding(.horizontal)
                           } else {
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
                                               filterModel.selectedCategory = category
                                               
                                               if let index = filterModel.categories.firstIndex(of: category) {
                                               
                                                   filterModel.categories.remove(at: index)
                                                   filterModel.categories.insert(category, at: category == "All" ? 0 : 1)
                                               }
                                           }
                                       }
                                   }
                               }
                               .padding(.horizontal)
                           }
                        }.padding(.top, showHorizontalCategory ? 155 : 0)
                        
                        // Popular Groups
                        VStack(alignment: .leading, spacing: 16) {
                            Text((selectedCategoryForOverlay ?? "Popular") + " Groups")
                                .font(.headline)
                                .padding(.horizontal)
                            
                           
                            if filteredGroups.isEmpty {
                                HStack {
                                    Spacer()
                                    VStack(alignment: .center) {
                                        Image("hmm")
                                            .resizable()
                                            .renderingMode(.original)
                                            .aspectRatio(contentMode: .fit)
                                        .frame(height:200)
                                        
                                        // Subtitle
                                        Text("Hmm! nothing yet..")
                                            .font(.subheadline)
                                            .foregroundColor(Color.invert)
                                            .multilineTextAlignment(.center)
                                    }
                                    Spacer()
                                }
                            } else {
                                ForEach(filteredGroups.prefix(3)) { group in
                                    GroupCard(group: group)
                                }
                                
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
                
                // Header
                VStack(alignment: .leading) {

                    VStack {
                        HStack{
                        Button(action: {}) {
                            HStack {
                                Text("Abuja, Nigeria")
                                Image(systemName: "chevron.down")
                            }
                        }
                        Spacer()
                    }.padding(.horizontal)
                    
                    
                        HStack {
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
                                }.padding(.trailing)
                            }
                        }
                        searchBar
                    }.padding(.bottom, 15)
                        
                        .background(LinearGradient(
                            gradient: Gradient(colors: [Color.dynamic, Color.dynamic,Color.dynamic.opacity(0.90)]),
                            startPoint: .top,
                            endPoint: .bottom
                        ))
                        
                    
                    Spacer()
                }
            }
            
        }
        .onAppear {
            fetchNearbyGroups()
        }
        .sheet(isPresented: $showNotifications) {
            GroupNotificationsView()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showNotifications.toggle() }) {
                    Image(systemName: "bell.fill")
                        .foregroundColor(.primary)
                }
            }
        }
        .alert("Error", isPresented: $showError, presenting: errorMessage) { _ in
            Button("OK", role: .cancel) { }
        } message: { message in
            Text(message)
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
                            .multilineTextAlignment(.leading)
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

struct GroupTypeIcon: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
            Text(text)
                .font(.caption)
                .lineLimit(1)
        }
        .foregroundColor(.secondary)
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

struct GroupNotificationsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0
    @EnvironmentObject private var firebaseManager: FirebaseManager
    @State private var myGroups: [EventGroup] = []
    @State private var pendingGroups: [EventGroup] = []
    @State private var createdGroups: [EventGroup] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedFilter = "Recent"
  
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    // Header Section
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your\nGroup Updates")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundStyle(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.invert, .blue]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            
                            Text("Stay connected with your groups")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        // Quick Action Button
                        NavigationLink(destination: GroupCreationFlow(viewModel: CreateGroupViewModel())) {
                            HStack {
                                Text("Create New Group")
                                    .foregroundColor(.blue)
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.blue)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                    
                  
                    
                    // Custom Tab Bar
                    HStack(spacing: 0) {
                        TabButton(title: "My Groups", isSelected: selectedTab == 0) {
                            withAnimation { selectedTab = 0 }
                        }
                        TabButton(title: "Pending", isSelected: selectedTab == 1) {
                            withAnimation { selectedTab = 1 }
                        }
                        TabButton(title: "Created", isSelected: selectedTab == 2) {
                            withAnimation { selectedTab = 2 }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Content based on selected tab
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        LazyVStack(spacing: 16) {
                            switch selectedTab {
                            case 0:
                                if myGroups.isEmpty {
                                    EmptyStateView(message: "You haven't joined any groups yet")
                                } else {
                                    ForEach(myGroups) { group in
                                        GroupNotificationCard(group: group)
                                            .padding(.horizontal)
                                    }
                                }
                            case 1:
                                if pendingGroups.isEmpty {
                                    EmptyStateView(message: "No pending group requests")
                                } else {
                                    ForEach(pendingGroups) { group in
                                        GroupNotificationCard(group: group)
                                            .padding(.horizontal)
                                    }
                                }
                            case 2:
                                if createdGroups.isEmpty {
                                    EmptyStateView(message: "You haven't created any groups")
                                } else {
                                    ForEach(createdGroups) { group in
                                        GroupNotificationCard(group: group)
                                            .padding(.horizontal)
                                    }
                                }
                            default:
                                EmptyView()
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .background(Color.dynamic)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(.primary)
                    }
                }
            }
            .onAppear {
                fetchGroups()
            }
        }
    }
    
    private func fetchGroups() {
        guard let userId = firebaseManager.currentUser?.uid else { return }
        
        // Reset loading state
        isLoading = true
        errorMessage = nil
        
        let db = Firestore.firestore()
        
        // Fetch groups user is a member of
        db.collection("groups")
            .whereField("members", arrayContains: userId)
            .getDocuments { snapshot, error in
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    return
                }
                
                self.myGroups = snapshot?.documents.compactMap { document in
                    EventGroup.fromFirestore(document)
                } ?? []
                
                // Fetch pending groups
                db.collection("groups")
                    .whereField("pendingRequests", arrayContains: userId)
                    .getDocuments { snapshot, error in
                        if let error = error {
                            self.errorMessage = error.localizedDescription
                            self.isLoading = false
                            return
                        }
                        
                        self.pendingGroups = snapshot?.documents.compactMap { document in
                            EventGroup.fromFirestore(document)
                        } ?? []
                        
                        // Fetch created groups
                        db.collection("groups")
                            .whereField("createdBy", isEqualTo: userId)
                            .getDocuments { snapshot, error in
                                if let error = error {
                                    self.errorMessage = error.localizedDescription
                                } else {
                                    self.createdGroups = snapshot?.documents.compactMap { document in
                                        EventGroup.fromFirestore(document)
                                    } ?? []
                                }
                                
                                self.isLoading = false
                            }
                    }
            }
    }
}

struct TabButton: View {
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
                .background(isSelected ? Color.black : Color.clear)
                .cornerRadius(20)
        }
    }
}

struct GroupNotificationCard: View {
    let group: EventGroup
    @State private var adminName: String = ""
    
    var body: some View {
        NavigationLink(destination: GroupDetailView(group: group)) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Text(group.name.prefix(1).uppercased())
                                .font(.title2.bold())
                                .foregroundColor(.white)
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(group.name)
                            .font(.headline)
                        Text("Admin: \(adminName)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Text("Joined")
                        .font(.subheadline.bold())
                        .foregroundColor(.green)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(15)
                }
                
                if let description = group.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack {
                    Label("\(group.memberCount) members", systemImage: "person.2")
                    Spacer()
                    Label(group.category, systemImage: "tag")
                }
                .font(.subheadline)
                .foregroundColor(.gray)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
            )
        }
        .onAppear {
            fetchAdminName()
        }
    }
    
    private func fetchAdminName() {
        let db = Firestore.firestore()
        db.collection("users").document(group.createdBy).getDocument { document, error in
            if let document = document, document.exists,
               let userData = document.data(),
               let fullName = userData["name"] as? String {
                adminName = String(fullName.split(separator: " ").first ?? "")
            }
        }
    }
}

struct EmptyStateView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 50))
                .foregroundStyle(
                    LinearGradient(colors: [.blue.opacity(0.7), .purple.opacity(0.7)],
                                 startPoint: .topLeading,
                                 endPoint: .bottomTrailing)
                )
            
            Text(message)
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

struct GroupNotificationsView_Previews: PreviewProvider {
    static var previews: some View {
        GroupNotificationsView()
            .environmentObject(FirebaseManager.shared)
    }
}

// Add this extension for preview purposes
extension GroupNotificationsView {
    static var preview: some View {
        GroupNotificationsView()
            .environmentObject(FirebaseManager.shared)
    }
}

struct GroupsView_Previews: PreviewProvider {
    static var previews: some View {
        GroupsView(previewGroups: sampleGroups)
            .environmentObject(FirebaseManager.shared)
    }
}

struct GroupFilterView: View {
    @Binding var isPresented: Bool
    @Binding var selectedCategory: String?
    @Binding var memberCountRange: ClosedRange<Double>
    @Binding var radius: Double
    let categories: [String]
    @Environment(\.presentationMode) var presentationMode
    @State private var showAllCategories = false
    @State private var selectedRating: Int = 4
    
    var body: some View {
        
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Spacer()
                    Image("smilepov")
                        .resizable()
                        .renderingMode(.original)
                        .aspectRatio(contentMode: .fit)
                    .frame(width:200,height:200)
                    Spacer()
                }
                
                // Header
              
                HStack {
                    Text("Category")
                        .font(.headline)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.gray)
                }.padding(.horizontal)
                    .padding(.top,20)
                // Category Section
                VStack(alignment: .leading, spacing: 12) {
                   
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(categories.prefix(showAllCategories ? categories.count : 3), id: \.self) { category in
                                CategoryPill(text: category, isSelected: selectedCategory == category) {
                                    selectedCategory = category
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // Member Count Range
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Member Count")
                            .font(.headline)
                        Spacer()
                        Text("\(Int(memberCountRange.lowerBound))-\(Int(memberCountRange.upperBound))")
                            .foregroundColor(.gray)
                    }
                    
                    GroupRangeSlider(range: $memberCountRange, in: 0...600)
                        
                        .padding(.horizontal,10)
                        .padding(.top,20)
                        .padding(.bottom,35)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                
                // Distance
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Distance")
                            .font(.headline)
                        Spacer()
                        Text("\(Int(radius)) miles")
                            .foregroundColor(.gray)
                    }
                    
                    Slider(value: $radius, in: 1...100, step: 1)
                        .accentColor(.orange)
                        .padding(.horizontal,10)
                        .padding(.top,15)
                        .padding(.bottom,15)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                
                // Rating Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Rating")
                            .font(.headline)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.gray)
                    }
                    
                    VStack(spacing: 16) {
                        ForEach((2...4).reversed(), id: \.self) { rating in
                            Button(action: { selectedRating = rating }) {
                                HStack {
                                    HStack(spacing: 4) {
                                        ForEach(0..<rating, id: \.self) { _ in
                                            Image(systemName: "star.fill")
                                        }
                                        Text("& up")
                                    }
                                    .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    if selectedRating == rating {
                                        Image(systemName: "checkmark.square.fill")
                                            .foregroundColor(.invert)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Show Results Button
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Text("Show Results")
                        .font(.headline)
                        .foregroundColor(.dynamic)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.invert)
                        .cornerRadius(12)
                }
                .padding()
            }.padding(.bottom, 60)
        }
        .navigationTitle("Filter")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                withAnimation(.spring()) {
                    Button("Reset") {
                        selectedCategory = "All"
                        memberCountRange = 0...500
                        radius = 50
                        //showAllCategories.toggle()
                    }
                }
            }
        }
            
                .foregroundColor(.invert)
        
                .background(Color.dynamic)
        .edgesIgnoringSafeArea(.bottom)
    }
}

struct CategoryPill: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(text)
                if isSelected {
                    Image(systemName: "checkmark")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.black : Color.gray.opacity(0.1))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
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
                    .fill(Color.orange)
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
