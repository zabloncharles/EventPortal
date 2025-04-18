import SwiftUI
import FirebaseFirestore

struct ChatHomeView: View {
    @EnvironmentObject private var firebaseManager: FirebaseManager
    @State private var requestedGroups: [EventGroup] = []
    @State private var joinedGroups: [EventGroup] = []
    @State private var isLoading = true
    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollableNavigationBar(title: "Messages") {
            VStack(spacing: 0) {
                // Custom Header
                VStack(spacing: 16) {
                    HStack {
                        Button(action: { dismiss() }) {
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
                .padding(.top)
                .background(Color.dynamic)
                
                // Content
                VStack(spacing: 24) {
                    // Add Group Button with modern design
                    Button(action: {}) {
                        HStack(spacing: 15) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.1))
                                    .frame(width: 50, height: 50)
                                Image(systemName: "plus")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.blue)
                            }
                            
                            Text("Start a New Chat")
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
                                    .cornerRadius(15)
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
        }
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
    @State private var unreadCount: Int = Int.random(in: 0...5)
    
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
                    if unreadCount > 0 {
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
