import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import CoreLocation

struct Message: Identifiable, Equatable {
    let id: String
    let text: String
    let senderId: String
    let senderName: String
    let timestamp: Date
    var isCurrentUser: Bool
    
    static func == (lhs: Message, rhs: Message) -> Bool {
        lhs.id == rhs.id
    }
    
    static func fromFirestore(_ document: QueryDocumentSnapshot) -> Message? {
        let data = document.data()
        guard let senderId = data["senderId"] as? String,
              let senderName = data["senderName"] as? String,
              let text = data["text"] as? String,
              let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() else {
            return nil
        }
        
        return Message(
            id: document.documentID,
            text: text,
            senderId: senderId,
            senderName: senderName,
            timestamp: timestamp,
            isCurrentUser: senderId == Auth.auth().currentUser?.uid
        )
    }
}

struct ChatDetailView: View {
    let group: EventGroup
    @State private var messages: [Message] = []
    @State private var newMessage: String = ""
    @State private var isLoading = true
    @State private var showScrollToBottom = false
    @State private var isTyping = false
    @FocusState private var isFocused: Bool
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var firebaseManager: FirebaseManager
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.dynamic
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Header with blur effect
                ZStack {
                    Color.dynamic
                        .opacity(0.98)
                    
                    VStack(spacing: 15) {
                        HStack(spacing: 15) {
                            Button(action: { dismiss() }) {
                                Image(systemName: "chevron.left")
                                    .font(.title3)
                                    .foregroundColor(.primary)
                            }
                            
                            // Group Avatar with animation
                            Circle()
                                .fill(LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Text(group.name.prefix(1).uppercased())
                                        .font(.headline.bold())
                                        .foregroundColor(.white)
                                )
                                .shadow(color: .blue.opacity(0.3), radius: 5)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(group.name)
                                    .font(.headline)
                                Text("\(group.memberCount) members")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            Menu {
                                Button(action: {}) {
                                    Label("Group Info", systemImage: "info.circle")
                                }
                                Button(action: {}) {
                                    Label("Search", systemImage: "magnifyingglass")
                                }
                                Button(action: {}) {
                                    Label("Mute Notifications", systemImage: "bell.slash")
                                }
                            } label: {
                                Image(systemName: "ellipsis")
                                    .font(.title3)
                                    .foregroundColor(.primary)
                                    .rotationEffect(.degrees(90))
                            }
                        }
                    }
                    .padding()
                }
                .frame(height: 80)
                
                // Messages
                ScrollViewReader { proxy in
                    ZStack(alignment: .bottomTrailing) {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 20) {
                                if isLoading {
                                    ProgressView()
                                        .padding()
                                } else if messages.isEmpty {
                                    EmptyMessagesView()
                                }
                                
                                ForEach(messages) { message in
                                    MessageBubble(message: message)
                                        .id(message.id)
                                        .transition(.move(edge: .bottom))
                                }
                            }
                            .padding()
                        }
                        .onChange(of: messages) { _ in
                            if let lastMessage = messages.last {
                                withAnimation {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                        
                        // Scroll to bottom button
                        if showScrollToBottom {
                            Button(action: {
                                withAnimation {
                                    if let lastMessage = messages.last {
                                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                    }
                                }
                            }) {
                                Image(systemName: "arrow.down.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                                    .padding(8)
                                    .background(Color.white)
                                    .clipShape(Circle())
                                    .shadow(color: .black.opacity(0.1), radius: 5)
                            }
                            .padding()
                            .transition(.move(edge: .bottom))
                        }
                    }
                }
                
                // Message Input with animations
                VStack(spacing: 0) {
                    Divider()
                    HStack(spacing: 15) {
                        Menu {
                            Button(action: {}) {
                                Label("Photo", systemImage: "photo")
                            }
                            Button(action: {}) {
                                Label("Camera", systemImage: "camera")
                            }
                            Button(action: {}) {
                                Label("Document", systemImage: "doc")
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                        
                        HStack {
                            TextField("Message", text: $newMessage, axis: .vertical)
                                .textFieldStyle(.plain)
                                .padding(.vertical, 8)
                                .focused($isFocused)
                                .onChange(of: newMessage) { _ in
                                    withAnimation {
                                        isTyping = !newMessage.isEmpty
                                    }
                                }
                            
                            if isTyping {
                                Button(action: { newMessage = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray6))
                        .cornerRadius(20)
                        
                        Button(action: sendMessage) {
                            Image(systemName: isTyping ? "paperplane.fill" : "mic.fill")
                                .font(.title3)
                                .foregroundColor(.blue)
                                .frame(width: 30)
                        }
                        .disabled(!isTyping)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .background(Color.dynamic)
                }
            }
        }
        .navigationBarHidden(true)
        .hideTabOnAppear()
        .onAppear {
            fetchMessages()
        }
    }
    
    private func fetchMessages() {
        let db = Firestore.firestore()
        
        db.collection("groups")
            .document(group.id)
            .collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                messages = documents.compactMap { Message.fromFirestore($0) }
                isLoading = false
            }
    }
    
    private func sendMessage() {
        guard !newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let userId = firebaseManager.currentUser?.uid,
              let userName = firebaseManager.currentUser?.displayName else { return }
        
        let db = Firestore.firestore()
        let messageData: [String: Any] = [
            "text": newMessage,
            "senderId": userId,
            "senderName": userName,
            "timestamp": Timestamp()
        ]
        
        db.collection("groups")
            .document(group.id)
            .collection("messages")
            .addDocument(data: messageData) { error in
                if error == nil {
                    newMessage = ""
                }
            }
    }
}

struct MessageBubble: View {
    let message: Message
    @State private var showTime = false
    
    var body: some View {
        HStack {
            if message.isCurrentUser { Spacer() }
            
            VStack(alignment: message.isCurrentUser ? .trailing : .leading, spacing: 4) {
                if !message.isCurrentUser {
                    Text(message.senderName)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                HStack(alignment: .bottom, spacing: 8) {
                    if !message.isCurrentUser {
                        Circle()
                            .fill(LinearGradient(
                                colors: [.blue.opacity(0.5), .purple.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 30, height: 30)
                            .overlay(
                                Text(message.senderName.prefix(1).uppercased())
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                            )
                    }
                    
                    Text(message.text)
                        .foregroundColor(message.isCurrentUser ? .white : .primary)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 15)
                        .background(
                            Group {
                                if message.isCurrentUser {
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                } else {
                                    Color(.systemGray6)
                                }
                            }
                        )
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
                }
                
                if showTime {
                    Text(message.timestamp.formatted(.dateTime.hour().minute()))
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .transition(.opacity)
                }
            }
            .onTapGesture {
                withAnimation(.spring()) {
                    showTime.toggle()
                }
            }
            
            if !message.isCurrentUser { Spacer() }
        }
    }
}

struct EmptyMessagesView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 50))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue.opacity(0.7), .purple.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("No Messages Yet")
                .font(.title3.bold())
            
            Text("Start the conversation by sending a message!")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 50)
    }
}

struct ChatDetailView_Previews: PreviewProvider {
    static let mockGroup = EventGroup(
        id: "mock-id",
        name: "Mock Group",
        description: "This is a mock group for preview",
        shortDescription: "Mock group for preview",
        memberCount: 5,
        imageURL: "",
        location: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        createdAt: Date(),
        createdBy: "mock-user",
        isPrivate: false,
        category: "Technology",
        tags: [],
        pendingRequests: [],
        members: ["mock-user"],
        admins: ["mock-user"]
    )
    
    static var previews: some View {
        ChatDetailView(group: mockGroup)
            .environmentObject(FirebaseManager.shared)
    }
} 
