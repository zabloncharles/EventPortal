//
//  GroupDetailView.swift
//  EventAppPortal
//
//  Created by Zablon Charles on 4/18/25.
//

import SwiftUI
import FirebaseFirestore
import CoreLocation

struct GroupDetailView: View {
    let group: EventGroup
    @Environment(\.presentationMode) var presentationMode
    @State private var showJoinAlert = false
    @State private var scrollOffset: CGFloat = 0
    let colors = [Color.red, Color.blue, Color.green, Color.purple, Color.orange]
    @StateObject private var tabBarManager = TabBarVisibilityManager.shared
    @State private var isDescriptionExpanded = false
    @State private var pageAppeared = false
    @State private var bottomBarAppeared = false
    @State private var currentPage = 0
    @State private var memberCount: Int = 0
    @State private var randomColor = Color.randomizetextcolor
    @State private var randomColor2 = Color.randomizetextcolor
    @EnvironmentObject private var firebaseManager: FirebaseManager
    @State private var isMember = false
    @State private var hasRequested = false
    @State private var adminName: String = ""
    @State private var memberNames: [String: String] = [:]
    @State private var showRequestToJoin = false
    @State private var currentGroup: EventGroup?
    @State private var isOwner = false
    @State private var showEditGroup = false
    
    // MARK: - Helper Functions
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
    
    // MARK: - Header Section
    private var headerSection: some View {
        ZStack(alignment: .top) {
            
            
            VStack {
                Spacer()
                
                
                Spacer()
                HStack {
                    Spacer()
                    Image("smilepov")
                        .resizable()
                        .renderingMode(.original)
                        .aspectRatio(contentMode: .fit)
                        .frame(width:200,height:200)
                        .background( Circle().fill(Color.clear).background(LinearGradient(
                            gradient: Gradient(colors: [randomColor2, Color.clear, randomColor.opacity(0.30)]),
                            startPoint: .bottom,
                            endPoint: .center
                        )).clipShape(Circle()))
                    Spacer()
                }
                
                .padding(.horizontal)
                .padding(.bottom, 50)
            }.scaleEffect(bottomBarAppeared ? 1 : 0.97)
                .animation(.spring(), value: bottomBarAppeared)
        }
    }
    
    // MARK: - Stats Section
    private var statsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 16) {
                GroupTypeIcon(
                    icon: categoryIcon(for: group.category),
                    text: group.category
                )
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 1, height: 40)
                GroupTypeIcon(
                    icon: "eye",
                    text: "\(group.memberCount) Views"
                )
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 1, height: 40)
                
                GroupTypeIcon(
                    icon: "person.2",
                    text: "\(group.memberCount) Members"
                )
                
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 1, height: 40)
                
                GroupTypeIcon(
                    icon: "mappin.circle",
                    text: "New York"
                )
                
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 1, height: 40)
                
                GroupTypeIcon(
                    icon: group.isPrivate ? "lock.fill" : "lock.open.fill",
                    text: group.isPrivate ? "Private" : "Public"
                )
            }
        }
        .padding(.vertical)
        .background(Color.dynamic)
        .cornerRadius(16)
        .padding(.top, -15)
        .padding(.bottom, -20)
    }
    
    // MARK: - Description Section
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About")
                .font(.title3)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(group.description)
                    .foregroundColor(.secondary)
                    .lineLimit(isDescriptionExpanded ? nil : 2)
                    .animation(.easeInOut, value: isDescriptionExpanded)
                
                Button(action: {
                    withAnimation {
                        isDescriptionExpanded.toggle()
                    }
                }) {
                    Text(isDescriptionExpanded ? "Read Less" : "Read More")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(randomColor2)
                }
                .padding(.top, 4)
            }
        }
    }
    
    // MARK: - Admin Section
    private var adminSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Group Admins")
                .font(.title3)
                .fontWeight(.bold)
            
            ForEach(group.admins, id: \.self) { adminId in
                HStack {
                    Circle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [randomColor2, .blue]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Text((memberNames[adminId] ?? "").prefix(1).uppercased())
                                .font(.title2.bold())
                                .foregroundColor(.white)
                        )
                    
                    VStack(alignment: .leading) {
                        Text(memberNames[adminId] ?? "")
                            .fontWeight(.semibold)
                        Text("Group Admin")
                            .foregroundColor(.secondary)
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
                .background(Color.dynamic)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            }
        }
    }
    
    // MARK: - Members Section
    private var membersSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Members")
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
                NavigationLink(destination: GroupMembersView(group: group, memberNames: memberNames)) {
                    Text("See All")
                        .foregroundColor(.blue)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(group.members.prefix(6), id: \.self) { memberId in
                        VStack(spacing: 8) {
                            Circle()
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Text((memberNames[memberId] ?? "Anon").prefix(1).uppercased())
                                        .font(.title2.bold())
                                        .foregroundColor(.white)
                                )
                            
                            Text(memberNames[memberId] ?? "Anonymous")
                                .font(.caption)
                                .lineLimit(1)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Join Button Section
    private var joinButtonSection: some View {
        Group {
            if isOwner {
                Button(action: { showEditGroup = true }) {
                    HStack {
                        Image(systemName: "pencil.circle.fill")
                        Text("Edit Group")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [randomColor, .blue]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(20)
                    .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                    .padding()
                }
            } else if isMember {
                Button(action: {}) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Joined")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(20)
                    .shadow(color: .green.opacity(0.3), radius: 10, x: 0, y: 5)
                    .padding()
                }
            } else if hasRequested {
                Button(action: {}) {
                    HStack {
                        Image(systemName: "clock.fill")
                        Text("Requested to Join")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .cornerRadius(20)
                    .shadow(color: .orange.opacity(0.3), radius: 10, x: 0, y: 5)
                    .padding()
                }
            } else {
                Button(action: { showJoinAlert = true }) {
                    Text(group.isPrivate ? "Request to Join" : "Join Group")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [randomColor, .blue]),
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
        .opacity(bottomBarAppeared ? 1 : 0)
        .offset(y: bottomBarAppeared ? 0 : 50)
    }
    
    var body: some View {
        ZStack {
            ScrollableNavigationBar(
                title: group.category,
                icon: "person.3.fill",
                trailingicon: "bookmark",
                isInline: true,
                showBackButton: true
            ) {
                VStack(spacing: 0) {
                    headerSection
                        .frame(height: 400)
                    
                    VStack(alignment: .leading, spacing: 24) {
                        // Title and Stats
                        VStack {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(group.name)
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [.invert, randomColor],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                    HStack {
                                        Text("New York City")
                                        Image(systemName: "location")
                                    }
                                    .foregroundColor(.gray)
                                }
                                Spacer()
                            }
                            
                            statsSection
                        }
                        
                        descriptionSection
                        adminSection
                        membersSection
                    }
                    .padding()
                    .offset(y: !pageAppeared ? UIScreen.main.bounds.height * 0.5 : 0)
                }.padding(.bottom, 140)
            }
            
            VStack {
                Spacer()
                joinButtonSection
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            print("DEBUG: View appeared, checking ownership")
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
                pageAppeared = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    bottomBarAppeared = true
                }
            }
            tabBarManager.hideTab = true
            checkIfOwner()  // Initial check
            fetchLatestGroupData()  // This will also call checkIfOwner after fetching
            fetchUserNames()  // Fetch member names
        }
        
        .alert("Join Group", isPresented: $showJoinAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Join") {
                if group.isPrivate {
                    requestToJoin()
                } else {
                    joinGroup()
                }
            }
        } message: {
            Text("Would you like to join \(group.name)?")
        }
        .background(
            NavigationLink(
                destination: EditGroupView(group: currentGroup ?? group),
                isActive: $showEditGroup
            ) {
                EmptyView()
            }
        )
    }
    
    private func fetchLatestGroupData() {
        let db = Firestore.firestore()
        db.collection("groups").document(group.id).getDocument { document, error in
            if let error = error {
                print("Error fetching group: \(error)")
                return
            }
            
            if let document = document, document.exists,
               let groupData = document.data() {
                // Get location data
                let locationData = groupData["location"] as? [String: Any]
                let latitude = locationData?["latitude"] as? Double ?? 0.0
                let longitude = locationData?["longitude"] as? Double ?? 0.0
                let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                
                // Get admins array
                let admins = groupData["admins"] as? [String] ?? []
                print("DEBUG: Fetched latest admins: \(admins)")
                
                // Update the current group data
                currentGroup = EventGroup(
                    id: document.documentID,
                    name: groupData["name"] as? String ?? "",
                    description: groupData["description"] as? String ?? "",
                    shortDescription: groupData["shortDescription"] as? String ?? "",
                    memberCount: groupData["memberCount"] as? Int ?? 0,
                    imageURL: groupData["imageURL"] as? String ?? "",
                    location: coordinate,
                    createdAt: (groupData["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                    createdBy: groupData["createdBy"] as? String ?? "",
                    isPrivate: groupData["isPrivate"] as? Bool ?? false,
                    category: groupData["category"] as? String ?? "",
                    tags: groupData["tags"] as? [String] ?? [],
                    pendingRequests: groupData["pendingRequests"] as? [String] ?? [],
                    members: groupData["members"] as? [String] ?? [],
                    admins: admins
                )
                
                // Update membership status and owner status
                DispatchQueue.main.async {
                    print("DEBUG: Checking ownership after fetching latest data")
                    checkMembershipStatus()
                    checkIfOwner()
                }
            }
        }
    }
    
    private func checkMembershipStatus() {
        guard let userId = firebaseManager.currentUser?.uid else { return }
        isMember = currentGroup?.members.contains(userId) ?? false
        hasRequested = currentGroup?.pendingRequests.contains(userId) ?? false
    }
    
    private func joinGroup() {
        guard let userId = firebaseManager.currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let groupRef = db.collection("groups").document(group.id)
        
        groupRef.updateData([
            "members": FieldValue.arrayUnion([userId])
        ]) { error in
            if let error = error {
                print("Error joining group: \(error)")
            } else {
                isMember = true
            }
        }
    }
    
    private func requestToJoin() {
        guard let userId = firebaseManager.currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let groupRef = db.collection("groups").document(group.id)
        
        groupRef.updateData([
            "pendingRequests": FieldValue.arrayUnion([userId])
        ]) { error in
            if let error = error {
                print("Error requesting to join: \(error)")
            } else {
                hasRequested = true
                showRequestToJoin = true
                // Fetch latest data after request is sent
                fetchLatestGroupData()
            }
        }
    }
    
    private func fetchUserNames() {
        print("DEBUG: Starting to fetch user names")
        let db = Firestore.firestore()
        
        // Fetch admin names
        for adminId in group.admins {
            print("DEBUG: Fetching admin name for ID: \(adminId)")
            db.collection("users").document(adminId).getDocument { document, error in
                if let error = error {
                    print("DEBUG: Error fetching admin name: \(error)")
                    return
                }
                
                if let document = document, document.exists,
                   let userData = document.data(),
                   let fullName = userData["name"] as? String {
                    print("DEBUG: Found admin name: \(fullName)")
                    DispatchQueue.main.async {
                        memberNames[adminId] = String(fullName.split(separator: " ").first ?? "")
                    }
                } else {
                    print("DEBUG: No admin name found for ID: \(adminId)")
                }
            }
        }
        
        // Fetch member names
        for memberId in group.members {
            print("DEBUG: Fetching member name for ID: \(memberId)")
            db.collection("users").document(memberId).getDocument { document, error in
                if let error = error {
                    print("DEBUG: Error fetching member name: \(error)")
                    return
                }
                
                if let document = document, document.exists,
                   let userData = document.data(),
                   let fullName = userData["name"] as? String {
                    print("DEBUG: Found member name: \(fullName)")
                    DispatchQueue.main.async {
                        memberNames[memberId] = String(fullName.split(separator: " ").first ?? "")
                    }
                } else {
                    print("DEBUG: No member name found for ID: \(memberId)")
                }
            }
        }
    }
    
    private func checkIfOwner() {
        guard let userId = firebaseManager.currentUser?.uid else {
            print("No current user found")
            isOwner = false
            return
        }
        
        print("DEBUG: Current user ID: \(userId)")
        print("DEBUG: Group admins array: \(group.admins)")
        print("DEBUG: Group ID: \(group.id)")
        
        // Check if the current user is in the admins array
        isOwner = group.admins.contains(userId)
        print("DEBUG: Is owner result: \(isOwner)")
        
        // Double check the comparison
        for adminId in group.admins {
            print("DEBUG: Comparing admin ID: \(adminId) with user ID: \(userId)")
            if adminId == userId {
                print("DEBUG: Found matching admin ID!")
            }
        }
    }
}

// MARK: - Group Members View
struct GroupMembersView: View {
    let group: EventGroup
    let memberNames: [String: String]
    let colors = [Color.red, Color.blue, Color.green, Color.purple, Color.orange]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(group.members, id: \.self) { memberId in
                    HStack(spacing: 16) {
                        Circle()
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [colors.randomElement() ?? .blue, .blue]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Text((memberNames[memberId] ?? "").prefix(1).uppercased())
                                    .font(.title3.bold())
                                    .foregroundColor(.white)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(memberNames[memberId] ?? "")
                                .font(.headline)
                            Text(memberId == group.createdBy ? "Admin" : "Member")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if memberId != group.createdBy {
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
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Members")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// Form Fields View
struct GroupFormFieldsView: View {
    @Binding var name: String
    @Binding var description: String
    @Binding var shortDescription: String
    @Binding var category: String
    @Binding var isPrivate: Bool
    @Binding var tags: [String]
    let randomColor: Color
    
    var body: some View {
        VStack(spacing: 20) {
            // Group Name
            VStack(alignment: .leading, spacing: 8) {
                Text("Group Name")
                    .font(.headline)
                    .foregroundColor(.secondary)
                TextField("Enter group name", text: $name)
                    .textFieldStyle(ModernTextFieldStyle())
            }
            
            // Short Description
            VStack(alignment: .leading, spacing: 8) {
                Text("Short Description")
                    .font(.headline)
                    .foregroundColor(.secondary)
                TextField("Enter short description", text: $shortDescription)
                    .textFieldStyle(ModernTextFieldStyle())
            }
            
            // Description
            VStack(alignment: .leading, spacing: 8) {
                Text("Description")
                    .font(.headline)
                    .foregroundColor(.secondary)
                TextEditor(text: $description)
                    .frame(height: 120)
                    .padding(12)
                    .background(Color.dynamic)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            }
            
            // Category
            VStack(alignment: .leading, spacing: 8) {
                Text("Category")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Picker("Category", selection: $category) {
                    Text("Sports").tag("Sports")
                    Text("Music").tag("Music")
                    Text("Art").tag("Art")
                    Text("Technology").tag("Technology")
                    Text("Food").tag("Food")
                    Text("Travel").tag("Travel")
                    Text("Environmental").tag("Environmental")
                    Text("Literature").tag("Literature")
                    Text("Corporate").tag("Corporate")
                    Text("Health & Wellness").tag("Health & Wellness")
                }
                .pickerStyle(MenuPickerStyle())
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
            }
            
            // Privacy Toggle
            VStack(alignment: .leading, spacing: 8) {
                Text("Privacy")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Toggle("Private Group", isOn: $isPrivate)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            }
        }
        .padding(.horizontal)
    }
}

struct EditGroupView: View {
    let group: EventGroup
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var firebaseManager: FirebaseManager
    
    @State private var name: String
    @State private var description: String
    @State private var shortDescription: String
    @State private var category: String
    @State private var isPrivate: Bool
    @State private var tags: [String]
    @State private var showConfirmation = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var randomColor = Color.randomizetextcolor
    @State private var memberNames: [String: String] = [:]
    @State private var membersToRemove: Set<String> = []
    @State private var showRemoveConfirmation = false
    @State private var selectedMemberToRemove: String?
    @State private var showDeleteConfirmation = false
    @State private var showDiscardConfirmation = false
    @State private var hasUnsavedChanges = false
    
    // Store initial values for comparison
    private let initialName: String
    private let initialDescription: String
    private let initialShortDescription: String
    private let initialCategory: String
    private let initialIsPrivate: Bool
    private let initialTags: [String]
    
    init(group: EventGroup) {
        self.group = group
        _name = State(initialValue: group.name)
        _description = State(initialValue: group.description)
        _shortDescription = State(initialValue: group.shortDescription)
        _category = State(initialValue: group.category)
        _isPrivate = State(initialValue: group.isPrivate)
        _tags = State(initialValue: group.tags)
        
        // Store initial values
        self.initialName = group.name
        self.initialDescription = group.description
        self.initialShortDescription = group.shortDescription
        self.initialCategory = group.category
        self.initialIsPrivate = group.isPrivate
        self.initialTags = group.tags
    }
    
    var body: some View {
        ZStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 25) {
                    // Header with SF Symbol
                    VStack(spacing: 15) {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [randomColor, .blue]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .padding(.top, 20)
                        
                        Text("Edit Group")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [randomColor, .blue]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 20)
                    
                    // Form Fields
                    GroupFormFieldsView(
                        name: $name,
                        description: $description,
                        shortDescription: $shortDescription,
                        category: $category,
                        isPrivate: $isPrivate,
                        tags: $tags,
                        randomColor: randomColor
                    )
                    
                    // Members Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Members")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Spacer()
                            NavigationLink(destination: ManageMembersView(
                                group: group,
                                memberNames: memberNames,
                                membersToRemove: $membersToRemove
                            )) {
                                Text("View All")
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        // Preview of first 3 members
                        ForEach(group.members.prefix(3), id: \.self) { memberId in
                            MemberCardView(
                                memberId: memberId,
                                memberName: memberNames[memberId] ?? "Anonymous",
                                isAdmin: group.admins.contains(memberId),
                                isCreator: memberId == group.createdBy,
                                isMarkedForRemoval: membersToRemove.contains(memberId),
                                onRemove: {
                                    // No action needed in preview
                                },
                                randomColor: randomColor
                            )
                        }
                        
                        if group.members.count > 3 {
                            Text("+ \(group.members.count - 3) more members")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.top, 8)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Save Button
                    Button(action: { showConfirmation = true }) {
                        Text("Save Changes")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [randomColor, .blue]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(15)
                            .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .disabled(isLoading)
                    
                    // Delete Button
                    Button(action: { showDeleteConfirmation = true }) {
                        Text("Delete Group")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [.red, .red.opacity(0.8)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(15)
                            .shadow(color: .red.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .padding(.horizontal)
                    .padding(.top, 5)
                    .disabled(isLoading)
                }
                .padding(.vertical)
            }
            .padding(.bottom,80)
            .disabled(isLoading)
            
            if isLoading {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }
        }
        .toolbarBackground(Color.dynamic)
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled(hasUnsavedChanges)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    if hasUnsavedChanges {
                        showDiscardConfirmation = true
                    } else {
                        presentationMode.wrappedValue.dismiss()
                    }
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
            }
        }
        .alert("Unsaved Changes", isPresented: $showDiscardConfirmation) {
            Button("Discard Changes", role: .destructive) {
                presentationMode.wrappedValue.dismiss()
            }
            Button("Keep Editing", role: .cancel) { }
            Button("Save Changes") {
                updateGroup()
            }
        } message: {
            Text("You have unsaved changes. Would you like to save them before leaving?")
        }
        .alert("Delete Group", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteGroup()
            }
        } message: {
            Text("Are you sure you want to delete this group? This action cannot be undone.")
        }
        .alert("Confirm Changes", isPresented: $showConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                updateGroup()
            }
        } message: {
            Text("Are you sure you want to update this group? This action cannot be undone.")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            fetchMemberNames()
        }
        .onChange(of: name) { _ in checkForChanges() }
        .onChange(of: description) { _ in checkForChanges() }
        .onChange(of: shortDescription) { _ in checkForChanges() }
        .onChange(of: category) { _ in checkForChanges() }
        .onChange(of: isPrivate) { _ in checkForChanges() }
        .onChange(of: tags) { _ in checkForChanges() }
        .onChange(of: membersToRemove) { _ in checkForChanges() }
    }
    
    private func checkForChanges() {
        hasUnsavedChanges = name != initialName ||
            description != initialDescription ||
            shortDescription != initialShortDescription ||
            category != initialCategory ||
            isPrivate != initialIsPrivate ||
            tags != initialTags ||
            !membersToRemove.isEmpty
    }
    
    private func fetchMemberNames() {
        let db = Firestore.firestore()
        for memberId in group.members {
            db.collection("users").document(memberId).getDocument { document, error in
                if let document = document, document.exists,
                   let userData = document.data(),
                   let fullName = userData["name"] as? String {
                    memberNames[memberId] = String(fullName.split(separator: " ").first ?? "")
                }
            }
        }
    }
    
    private func updateGroup() {
        guard let userId = firebaseManager.currentUser?.uid,
              group.admins.contains(userId) else {
            errorMessage = "You don't have permission to edit this group"
            showError = true
            return
        }
        
        isLoading = true
        
        let db = Firestore.firestore()
        let groupRef = db.collection("groups").document(group.id)
        
        // Filter out removed members
        let updatedMembers = group.members.filter { !membersToRemove.contains($0) }
        
        let updatedData: [String: Any] = [
            "name": name,
            "description": description,
            "shortDescription": shortDescription,
            "category": category,
            "isPrivate": isPrivate,
            "tags": tags,
            "members": updatedMembers,
            "updatedAt": Timestamp()
        ]
        
        groupRef.updateData(updatedData) { error in
            isLoading = false
            if let error = error {
                errorMessage = "Error updating group: \(error.localizedDescription)"
                showError = true
            } else {
                hasUnsavedChanges = false
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
    
    private func deleteGroup() {
        guard let userId = firebaseManager.currentUser?.uid,
              group.admins.contains(userId) else {
            errorMessage = "You don't have permission to delete this group"
            showError = true
            return
        }
        
        isLoading = true
        
        let db = Firestore.firestore()
        let groupRef = db.collection("groups").document(group.id)
        
        groupRef.delete { error in
            isLoading = false
            if let error = error {
                errorMessage = "Error deleting group: \(error.localizedDescription)"
                showError = true
            } else {
                // Navigate back to root view after successful deletion
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

// Modern TextField Style
struct ModernTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
    }
}

// Member Card View
struct MemberCardView: View {
    let memberId: String
    let memberName: String
    let isAdmin: Bool
    let isCreator: Bool
    let isMarkedForRemoval: Bool
    let onRemove: () -> Void
    let randomColor: Color
    
    var body: some View {
        HStack {
            Circle()
                .fill(LinearGradient(
                    gradient: Gradient(colors: [randomColor, .blue]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(memberName.count > 0 ? memberName.prefix(1).uppercased() : "Anonymous".prefix(1).uppercased())
                        .font(.title3.bold())
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(memberName.count > 0 ? memberName : "Anonymous")
                    .font(.headline)
                Text(isCreator ? "Admin" : "Member")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if !isCreator {
                Button(action: onRemove) {
                    Text(isMarkedForRemoval ? "Undo" : "Remove")
                        .font(.subheadline.bold())
                        .foregroundColor(isMarkedForRemoval ? .blue : .red)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            isMarkedForRemoval ?
                            Color.blue.opacity(0.1) :
                            Color.red.opacity(0.1)
                        )
                        .cornerRadius(20)
                }
            }
        }
        .padding()
        .background(Color.dynamic)
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

// Manage Members View
struct ManageMembersView: View {
    let group: EventGroup
    let memberNames: [String: String]
    @Binding var membersToRemove: Set<String>
    @State private var showRemoveConfirmation = false
    @State private var selectedMember: String?
    @State private var randomColor = Color.randomizetextcolor
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(group.members, id: \.self) { memberId in
                    MemberCardView(
                        memberId: memberId,
                        memberName: memberNames[memberId] ?? "",
                        isAdmin: group.admins.contains(memberId),
                        isCreator: memberId == group.createdBy,
                        isMarkedForRemoval: membersToRemove.contains(memberId),
                        onRemove: {
                            selectedMember = memberId
                            showRemoveConfirmation = true
                        },
                        randomColor: randomColor
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Manage Members")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Remove Member", isPresented: $showRemoveConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button(membersToRemove.contains(selectedMember ?? "") ? "Undo" : "Remove", role: .destructive) {
                if let memberId = selectedMember {
                    if membersToRemove.contains(memberId) {
                        membersToRemove.remove(memberId)
                    } else {
                        membersToRemove.insert(memberId)
                    }
                }
            }
        } message: {
            if let memberId = selectedMember {
                Text(membersToRemove.contains(memberId) ?
                     "Are you sure you want to undo removing \(memberNames[memberId] ?? "")?" :
                     "Are you sure you want to remove \(memberNames[memberId] ?? "") from the group?")
            }
        }
    }
}
