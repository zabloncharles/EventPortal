import SwiftUI
import FirebaseFirestore

struct ChatHomeView: View {
    @EnvironmentObject private var firebaseManager: FirebaseManager
    @State private var requestedGroups: [EventGroup] = []
    @State private var joinedGroups: [EventGroup] = []
    @State private var pendingRequests: [GroupRequest] = []
    @State private var isLoading = true
    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss
    @StateObject private var tabBarManager = TabBarVisibilityManager.shared
    
    
    var body: some View {
        ScrollableNavigationBar(title: "Messages") {
            VStack(spacing: 0) {
                // Custom Header
                VStack(spacing: 16) {
                    HStack {
                        Button(action: { backButtonPressed() }) {
                            Image(systemName: "arrow.left")
                                .font(.title3)
                                .foregroundColor(.primary)
                        }
                        Spacer()
                        Text("Messages")
                            .font(.title2.bold())
                        Spacer()
                        Button(action: {}) {
                            Image(systemName: "square.and.pencil")
                                .font(.title3)
                                .foregroundColor(.primary)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top,50)
                    
                    // Search Bar with modern design
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search conversations", text: $searchText)
                            .font(.system(size: 16))
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color(.systemGray6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal)
                }
                .padding(.top,10)
                .background(Color.dynamic)
                
                // Content
                VStack(spacing: 24) {
                    // Add Group Button with modern design - only show if no joined groups
                    if joinedGroups.isEmpty {
                        Button(action: {}) {
                            HStack(spacing: 15) {
                                ZStack {
                                    Circle()
                                        .fill(Color.blue.opacity(0.1))
                                        .frame(width: 50, height: 50)
                                    Image(systemName: "person.2.fill")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(.blue)
                                }
                                
                                Text("Join a Group")
                                    .font(.system(size: 16, weight: .medium))
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(15)
                            .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5)
                        }
                        .padding(.horizontal)
                        .padding(.top)
                    }
                    
                    // Pending Requests Section
                    if !pendingRequests.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Join Requests")
                                .font(.title3.bold())
                                .padding(.horizontal)
                            
                            ForEach(pendingRequests) { request in
                                NavigationLink(destination: RequestDetailView(request: request)) {
                                    RequestRow(request: request, pendingRequests: $pendingRequests)
                                        .background(Color(.systemBackground))
                                        .cornerRadius(15)
                                        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5)
                                }
                            }
                        }
                    }
                    
                    // Requested Groups Section with modern design
                    if !requestedGroups.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Pending Requests")
                                .font(.title3.bold())
                                .padding(.horizontal)
                            
                            ForEach(requestedGroups) { group in
                                RequestedGroupRow(group: group)
                                    .background(Color(.systemBackground))
                                    .cornerRadius(15)
                                    .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5)
                                    .padding(.horizontal)
                            }
                        }
                    }
                    
                    // Joined Groups Section with modern design
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Recent Chats")
                                .font(.title3.bold())
                            Spacer()
                            Button(action: {}) {
                                Text("See All")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal)
                        
                        if joinedGroups.isEmpty {
                            EmptyGroupsView()
                                .padding(.top)
                        } else {
                            ForEach(joinedGroups) { group in
                                JoinedGroupRow(group: group)
                                    .background(Color.dynamic)
                                    .cornerRadius(19)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 15)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                                    .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5)
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
        }
        .navigationBarBackButtonHidden(true)
        .background(Color.dynamic)
        .onAppear {
            fetchGroups()
            fetchPendingRequests()
        }
    }
    private func backButtonPressed(){
        dismiss()
        tabBarManager.hideTab = false
    }
    private func fetchGroups() {
        guard let userId = firebaseManager.currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        // Fetch requested groups
        db.collection("groups")
            .whereField("pendingRequests", arrayContains: userId)
            .getDocuments { snapshot, error in
                if let documents = snapshot?.documents {
                    requestedGroups = documents.compactMap { EventGroup.fromFirestore($0) }
                }
                
                // Fetch joined groups
                db.collection("groups")
                    .whereField("members", arrayContains: userId)
                    .getDocuments { snapshot, error in
                        if let documents = snapshot?.documents {
                            joinedGroups = documents.compactMap { EventGroup.fromFirestore($0) }
                        }
                        isLoading = false
                    }
            }
    }
    
    private func fetchPendingRequests() {
        guard let userId = firebaseManager.currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        // Fetch groups where user is admin
        db.collection("groups")
            .whereField("admins", arrayContains: userId)
            .getDocuments { snapshot, error in
                if let documents = snapshot?.documents {
                    let groupIds = documents.compactMap { $0.documentID }
                    
                    // For each group, check if there are any pending requests
                    for groupId in groupIds {
                        db.collection("groups")
                            .document(groupId)
                            .getDocument { document, error in
                                if let document = document, document.exists,
                                   let data = document.data(),
                                   let pendingRequestsArray = data["pendingRequests"] as? [String],
                                   !pendingRequestsArray.isEmpty {
                                    
                                    // Get user details for each pending request
                                    for requestUserId in pendingRequestsArray {
                                        db.collection("users")
                                            .document(requestUserId)
                                            .getDocument { userDoc, error in
                                                if let userDoc = userDoc, userDoc.exists,
                                                   let userData = userDoc.data(),
                                                   let userName = userData["name"] as? String {
                                                    
                                                    let request = GroupRequest(
                                                        id: requestUserId,
                                                        groupId: groupId,
                                                        userId: requestUserId,
                                                        userName: userName,
                                                        timestamp: Date()
                                                    )
                                                    
                                                    // Add to pending requests if not already there
                                                    if !pendingRequests.contains(where: { $0.id == request.id && $0.groupId == request.groupId }) {
                                                        pendingRequests.append(request)
                                                    }
                                                }
                                            }
                                    }
                                }
                            }
                    }
                }
            }
    }
}

struct RequestedGroupRow: View {
    let group: EventGroup
    @State private var adminName: String = ""
    
    var body: some View {
        HStack(spacing: 15) {
            // Group Image with modern gradient
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                Text(group.name.prefix(1).uppercased())
                    .font(.title3.bold())
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(group.name)
                    .font(.system(size: 16, weight: .semibold))
                Text("Request pending...")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text("Pending")
                .font(.caption.bold())
                .foregroundColor(.orange)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
        }
        .padding()
    }
}

struct JoinedGroupRow: View {
    let group: EventGroup
    @State private var lastMessage: String = "No messages yet"
    @State private var lastMessageTime: String = "Just now"
    @State private var unreadCount: Int = 0
    @State private var hasUnreadMessages: Bool = false
    
    var body: some View {
        NavigationLink(destination: ChatDetailView(group: group)) {
            HStack(spacing: 15) {
                // Group Image with modern gradient
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    Text(group.name.prefix(1).uppercased())
                        .font(.title3.bold())
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(group.name)
                        .font(.system(size: 16, weight: .semibold))
                    Text(lastMessage)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    Text(lastMessageTime)
                        .font(.caption)
                        .foregroundColor(.gray)
                    if hasUnreadMessages && unreadCount > 0 {
                        Text("\(unreadCount)")
                            .font(.caption2.bold())
                            .foregroundColor(.white)
                            .frame(width: 20, height: 20)
                            .background(Color.blue)
                            .clipShape(Circle())
                    }
                }
            }
            .padding()
        }.hideTabOnAppear(true)
        .onAppear {
            fetchUnreadCount()
        }
    }
    
    private func fetchUnreadCount() {
        guard let userId = FirebaseManager.shared.currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        // Get the last message timestamp for this user
        db.collection("groups")
            .document(group.id)
            .collection("messages")
            .whereField("timestamp", isGreaterThan: Date().addingTimeInterval(-86400)) // Last 24 hours
            .getDocuments { snapshot, error in
                if let documents = snapshot?.documents {
                    // Count messages that are unread by this user
                    unreadCount = documents.filter { doc in
                        let data = doc.data()
                        let readBy = data["readBy"] as? [String] ?? []
                        return !readBy.contains(userId)
                    }.count
                    
                    hasUnreadMessages = unreadCount > 0
                    
                    // Update last message if available
                    if let lastDoc = documents.last,
                       let messageText = lastDoc.data()["text"] as? String {
                        lastMessage = messageText
                    }
                }
            }
    }
}

struct EmptyGroupsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 50))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("No Conversations Yet")
                .font(.title3.bold())
                .foregroundColor(.primary)
            
            Text("Join a group to start chatting with others!")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5)
        .padding(.horizontal)
    }
}

struct ChatHomeView_Previews: PreviewProvider {
    static var previews: some View {
        ChatHomeView()
            .environmentObject(FirebaseManager.shared)
    }
}

// MARK: - Group Request Model
struct GroupRequest: Identifiable {
    let id: String
    let groupId: String
    let userId: String
    let userName: String
    let timestamp: Date
}

// MARK: - Request Row View
struct RequestRow: View {
    let request: GroupRequest
    @Binding var pendingRequests: [GroupRequest]
    @State private var groupName: String = ""
    @State private var groupImage: String = ""
    @State private var isApprover: Bool = false
    @State private var isProcessing: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @EnvironmentObject private var firebaseManager: FirebaseManager
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.blue)
            
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(request.userName)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("Wants to join \(groupName)")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                    
                    HStack {
                        Image(systemName: "person.circle")
                        Text("Requested: \(request.timestamp, style: .date)")
                        Image(systemName: "clock")
                        Text(request.timestamp, style: .time)
                    }
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                if isApprover {
                    // Action buttons for approver
                    HStack(spacing: 12) {
                        Button(action: {
                            approveRequest()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 44, height: 44)
                                
                                Image(systemName: "checkmark")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .disabled(isProcessing)
                        
                        Button(action: {
                            denyRequest()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 44, height: 44)
                                
                                Image(systemName: "xmark")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .disabled(isProcessing)
                    }
                } else {
                    // Pending status for non-approver
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.3))
                            .frame(width: 44, height: 44)
                        
                        Text("Pending")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                }
            }
            .padding()
        }
        .padding(.horizontal)
        .onAppear {
            fetchGroupDetails()
            checkIfApprover()
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Request Update"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .overlay(
            Group {
                if isProcessing {
                    Color.black.opacity(0.1)
                        .cornerRadius(20)
                        .overlay(
                            ProgressView()
                                .scaleEffect(1.2)
                                .tint(.white)
                        )
                }
            }
        )
    }
    
    private func fetchGroupDetails() {
        let db = Firestore.firestore()
        db.collection("groups").document(request.groupId).getDocument { document, error in
            if let document = document, document.exists,
               let data = document.data() {
                groupName = data["name"] as? String ?? ""
                groupImage = data["imageURL"] as? String ?? ""
            }
        }
    }
    
    private func checkIfApprover() {
        guard let currentUserId = firebaseManager.currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        
        // Check if the user is an admin of the group
        db.collection("groups").document(request.groupId).getDocument { document, error in
            if let document = document, document.exists,
               let data = document.data(),
               let admins = data["admins"] as? [String] {
                isApprover = admins.contains(currentUserId)
            }
        }
    }
    
    private func approveRequest() {
        isProcessing = true
        
        let db = Firestore.firestore()
        let groupRef = db.collection("groups").document(request.groupId)
        
        // Start a batch write
        let batch = db.batch()
        
        // Add user to members array
        batch.updateData([
            "members": FieldValue.arrayUnion([request.userId])
        ], forDocument: groupRef)
        
        // Remove from pendingRequests array
        batch.updateData([
            "pendingRequests": FieldValue.arrayRemove([request.userId])
        ], forDocument: groupRef)
        
        // Create a notification for the user
        let notificationRef = db.collection("notifications").document()
        let notification = [
            "userId": request.userId,
            "groupId": request.groupId,
            "type": "request_approved",
            "message": "Your request to join \(groupName) has been approved",
            "timestamp": FieldValue.serverTimestamp(),
            "read": false
        ] as [String : Any]
        batch.setData(notification, forDocument: notificationRef)
        
        // Commit the batch
        batch.commit { error in
            if let error = error {
                isProcessing = false
                alertMessage = "Error: \(error.localizedDescription)"
                showAlert = true
            } else {
                // After successful batch commit, remove the request from the UI
                if let index = pendingRequests.firstIndex(where: { $0.id == request.id && $0.groupId == request.groupId }) {
                    pendingRequests.remove(at: index)
                }
                isProcessing = false
                alertMessage = "Request approved successfully"
                showAlert = true
            }
        }
    }
    
    private func denyRequest() {
        isProcessing = true
        
        let db = Firestore.firestore()
        let groupRef = db.collection("groups").document(request.groupId)
        
        // Start a batch write
        let batch = db.batch()
        
        // Remove from pendingRequests array
        batch.updateData([
            "pendingRequests": FieldValue.arrayRemove([request.userId])
        ], forDocument: groupRef)
        
        // Create a notification for the user
        let notificationRef = db.collection("notifications").document()
        let notification = [
            "userId": request.userId,
            "groupId": request.groupId,
            "type": "request_denied",
            "message": "Your request to join \(groupName) has been denied",
            "timestamp": FieldValue.serverTimestamp(),
            "read": false
        ] as [String : Any]
        batch.setData(notification, forDocument: notificationRef)
        
        // Commit the batch
        batch.commit { error in
            if let error = error {
                isProcessing = false
                alertMessage = "Error: \(error.localizedDescription)"
                showAlert = true
            } else {
                // After successful batch commit, remove the request from the UI
                if let index = pendingRequests.firstIndex(where: { $0.id == request.id && $0.groupId == request.groupId }) {
                    pendingRequests.remove(at: index)
                }
                isProcessing = false
                alertMessage = "Request denied successfully"
                showAlert = true
            }
        }
    }
} 
