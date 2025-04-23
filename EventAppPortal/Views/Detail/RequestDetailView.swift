import SwiftUI
import FirebaseFirestore

struct RequestDetailView: View {
    let request: GroupRequest
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var firebaseManager: FirebaseManager
    @State private var groupName: String = ""
    @State private var groupDescription: String = ""
    @State private var groupImage: String = ""
    @State private var groupCategory: String = ""
    @State private var groupMemberCount: Int = 0
    @State private var showActionAlert = false
    @State private var actionType: RequestAction = .accept
    @State private var isLoading = false
    @State private var randomColor = Color.randomizetextcolor
    @State private var randomColor2 = Color.randomizetextcolor
    
    enum RequestAction {
        case accept
        case decline
    }
    
    var body: some View {
        ScrollableNavigationBar(
            title: "Join Request",
            icon: "person.crop.circle.badge.questionmark",
            isInline: true,
            showBackButton: true
        ) {
            VStack(spacing: 24) {
                // Header Section
                VStack(spacing: 16) {
                    // User Avatar
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [randomColor, randomColor2],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                            .shadow(color: randomColor.opacity(0.3), radius: 10, x: 0, y: 5)
                        
                        Text(request.userName.prefix(1).uppercased())
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Text(request.userName)
                        .font(.title2.bold())
                    
                    Text("Wants to join")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text(groupName)
                        .font(.title3.bold())
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.invert, randomColor],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .padding(.top)
                
                // Group Info Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Group Information")
                        .font(.title3.bold())
                    
                    VStack(spacing: 12) {
                        RequestInfoRow(icon: "tag", title: "Category", value: groupCategory)
                        RequestInfoRow(icon: "person.2", title: "Members", value: "\(groupMemberCount)")
                        RequestInfoRow(icon: "clock", title: "Requested", value: request.timestamp.formatted())
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
                
                // Description Section
                if !groupDescription.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("About Group")
                                .font(.title3.bold())
                            Spacer()
                        }
                        
                        Text(groupDescription)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 16) {
                    Button(action: { handleRequest(.accept) }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Accept Request")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(20)
                        .shadow(color: .green.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    
                    Button(action: { handleRequest(.decline) }) {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                            Text("Decline Request")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(20)
                        .shadow(color: .red.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }.padding(.top,90)
            .padding()
        }
        .onAppear {
            fetchGroupDetails()
        }
        .alert(isPresented: $showActionAlert) {
            Alert(
                title: Text(actionType == .accept ? "Accept Request" : "Decline Request"),
                message: Text(actionType == .accept ? "Are you sure you want to accept this request?" : "Are you sure you want to decline this request?"),
                primaryButton: .destructive(Text(actionType == .accept ? "Accept" : "Decline")) {
                    processRequest()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private func fetchGroupDetails() {
        let db = Firestore.firestore()
        db.collection("groups").document(request.groupId).getDocument { document, error in
            if let document = document, document.exists,
               let data = document.data() {
                groupName = data["name"] as? String ?? ""
                groupDescription = data["description"] as? String ?? ""
                groupImage = data["imageURL"] as? String ?? ""
                groupCategory = data["category"] as? String ?? ""
                groupMemberCount = data["memberCount"] as? Int ?? 0
            }
        }
    }
    
    private func handleRequest(_ action: RequestAction) {
        actionType = action
        showActionAlert = true
    }
    
    private func processRequest() {
        isLoading = true
        let db = Firestore.firestore()
        
        if actionType == .accept {
            // Add user to group members
            db.collection("groups").document(request.groupId).updateData([
                "members": FieldValue.arrayUnion([request.userId]),
                "memberCount": FieldValue.increment(Int64(1))
            ]) { error in
                if error == nil {
                    // Delete the request
                    db.collection("groups")
                        .document(request.groupId)
                        .collection("requests")
                        .document(request.id)
                        .delete { error in
                            isLoading = false
                            if error == nil {
                                dismiss()
                            }
                        }
                }
            }
        } else {
            // Just delete the request
            db.collection("groups")
                .document(request.groupId)
                .collection("requests")
                .document(request.id)
                .delete { error in
                    isLoading = false
                    if error == nil {
                        dismiss()
                    }
                }
        }
    }
}

struct RequestInfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            Text(title)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .fontWeight(.medium)
        }
    }
}

struct RequestDetailView_Previews: PreviewProvider {
    static var previews: some View {
        RequestDetailView(request: GroupRequest(
            id: "preview-id",
            groupId: "preview-group-id",
            userId: "preview-user-id",
            userName: "John Doe",
            timestamp: Date()
        ))
        .environmentObject(FirebaseManager.shared)
    }
} 
