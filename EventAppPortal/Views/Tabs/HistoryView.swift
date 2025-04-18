import SwiftUI
import FirebaseFirestore
import CoreLocation

struct HistoryView: View {
    @EnvironmentObject private var firebaseManager: FirebaseManager
    @State private var selectedTab = 0
    @State private var groups: [EventGroup] = []
    @State private var events: [Event] = []
    @State private var isLoading = true
    
    var body: some View {
        
            VStack(spacing: 0) {
                // Custom Segmented Control
                HStack(spacing: 0) {
                    HistoryTabButton(title: "Groups", isSelected: selectedTab == 0) {
                        withAnimation { selectedTab = 0 }
                    }
                    HistoryTabButton(title: "Events", isSelected: selectedTab == 1) {
                        withAnimation { selectedTab = 1 }
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            if selectedTab == 0 {
                                // Groups History
                                ForEach(groups) { group in
                                    GroupHistoryCard(group: group)
                                }
                            } else {
                                // Events History
                                ForEach(events) { event in
                                    EventHistoryCard(event: event)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("History")
            .onAppear {
                fetchHistory()
            }
        
    }
    
    private func fetchHistory() {
        guard let userId = firebaseManager.currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        // Fetch groups
        db.collection("groups")
            .whereField("members", arrayContains: userId)
            .getDocuments { snapshot, error in
                if let documents = snapshot?.documents {
                    groups = documents.compactMap { document in
                        EventGroup.fromFirestore(document)
                    }
                }
                
                // Fetch events
                db.collection("events")
                    .whereField("participants", arrayContains: userId)
                    .getDocuments { snapshot, error in
                        if let documents = snapshot?.documents {
                            events = documents.compactMap { document in
                                let data = document.data()
                                return Event(
                                    id: document.documentID,
                                    name: data["name"] as? String ?? "",
                                    description: data["description"] as? String ?? "",
                                    type: data["type"] as? String ?? "",
                                    views: data["views"] as? String ?? "0",
                                    location: data["location"] as? String ?? "",
                                    price: data["price"] as? String ?? "",
                                    owner: data["owner"] as? String ?? "",
                                    organizerName: data["organizerName"] as? String ?? "",
                                    shareContactInfo: data["shareContactInfo"] as? Bool ?? false,
                                    startDate: (data["startDate"] as? Timestamp)?.dateValue() ?? Date(),
                                    endDate: (data["endDate"] as? Timestamp)?.dateValue() ?? Date(),
                                    images: data["images"] as? [String] ?? [],
                                    participants: data["participants"] as? [String] ?? [],
                                    maxParticipants: data["maxParticipants"] as? Int ?? 0,
                                    isTimed: data["isTimed"] as? Bool ?? false,
                                    createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                                    coordinates: data["coordinates"] as? [Double] ?? [],
                                    status: data["status"] as? String ?? "active"
                                )
                            }
                        }
                        isLoading = false
                    }
            }
    }
}

// MARK: - Supporting Views
struct HistoryTabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundColor(isSelected ? .white : .gray)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    Group {
                        if isSelected {
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        } else {
                            Color.clear
                        }
                    }
                )
                .cornerRadius(25)
        }
    }
}

struct GroupHistoryCard: View {
    let group: EventGroup
    @State private var adminName: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
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
            
            HStack {
                Label("\(group.memberCount) members", systemImage: "person.2")
                Spacer()
                Label(group.category, systemImage: "tag")
            }
            .font(.subheadline)
            .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(15)
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

struct EventHistoryCard: View {
    let event: Event
    @State private var organizerName: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.orange, .red],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(event.name.prefix(1).uppercased())
                            .font(.title2.bold())
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.name)
                        .font(.headline)
                    Text("Organizer: \(organizerName)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Text(event.price == "0" ? "Free" : "Paid")
                    .font(.subheadline.bold())
                    .foregroundColor(event.price == "0" ? .green : .blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background((event.price == "0" ? Color.green : Color.blue).opacity(0.1))
                    .cornerRadius(15)
            }
            
            HStack {
                Label(event.startDate.formatted(date: .abbreviated, time: .shortened),
                      systemImage: "calendar")
                Spacer()
                Label(event.location, systemImage: "location")
            }
            .font(.subheadline)
            .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(15)
        .onAppear {
            fetchOrganizerName()
        }
    }
    
    private func fetchOrganizerName() {
        let db = Firestore.firestore()
        db.collection("users").document(event.owner).getDocument { document, error in
            if let document = document, document.exists,
               let userData = document.data(),
               let fullName = userData["name"] as? String {
                organizerName = String(fullName.split(separator: " ").first ?? "")
            }
        }
    }
}

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            HistoryView()
                .environmentObject(FirebaseManager.shared)
        }
    }
} 
