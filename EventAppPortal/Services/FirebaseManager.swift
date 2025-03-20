import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var errorMessage = ""
    @AppStorage("userID") private var userID: String = ""
    
    private init() {
        // Listen for auth state changes
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.isAuthenticated = user != nil
                self?.currentUser = user
                // Update userID in AppStorage
                self?.userID = user?.uid ?? ""
            }
        }
    }
    
    func signIn(email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    self?.userID = ""
                    completion(false, error.localizedDescription)
                } else {
                    // Store userID in AppStorage
                    if let userId = result?.user.uid {
                        self?.userID = userId
                        
                        // Update last login timestamp
//                        Firestore.firestore().collection("users").document(userId).updateData([
//                            "lastLogin": Timestamp()
//                        ]) { error in
//                            if let error = error {
//                                print("Error updating last login: \(error)")
//                            }
//                        }
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self?.isAuthenticated = true
                    }
                    self?.errorMessage = ""
                    completion(true, nil)
                }
            }
        }
    }
    
    func signUp(email: String, name: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    completion(false, error.localizedDescription)
                } else {
                    // Create user document in Firestore
                    if let user = result?.user {
                        // Update display name
                        let changeRequest = user.createProfileChangeRequest()
                        changeRequest.displayName = name
                        changeRequest.commitChanges { error in
                            if let error = error {
                                print("Error updating user profile: \(error)")
                            }
                        }
                        
                        // Create user document with all information
                        let userData: [String: Any] = [
                            "uid": user.uid,
                            "email": email,
                            "name": name,
                            "createdAt": Timestamp(),
                            "lastLogin": Timestamp(),
                            "profileImageUrl": "",
                            "eventsCreated": 0,
                            "eventsAttended": 0,
                            "isEmailVerified": false,
                            "settings": [
                                "notifications": true,
                                "emailUpdates": true
                            ],
                            "deviceTokens": [],
                            "accountStatus": "active"
                        ]
                        
                        Firestore.firestore().collection("users").document(user.uid).setData(userData) { error in
                            if let error = error {
                                print("Error creating user document: \(error)")
                            } else {
                                // Send email verification
                                user.sendEmailVerification { error in
                                    if let error = error {
                                        print("Error sending verification email: \(error)")
                                    }
                                }
                            }
                        }
                    }
                    self?.errorMessage = ""
                    completion(true, nil)
                }
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            DispatchQueue.main.async {
                self.isAuthenticated = false
                self.currentUser = nil
                self.userID = "" // Clear userID from AppStorage
            }
        } catch {
            print("Error signing out: \(error)")
        }
    }
    
    func resetPassword(email: String, completion: @escaping (Bool, String?) -> Void) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(false, error.localizedDescription)
                } else {
                    completion(true, nil)
                }
            }
        }
    }
    
    // Helper function to get user data
    func getUserData(completion: @escaping ([String: Any]?, String?) -> Void) {
        guard let userId = currentUser?.uid else {
            completion(nil, "No user logged in")
            return
        }
        
        Firestore.firestore().collection("users").document(userId).getDocument { document, error in
            if let error = error {
                completion(nil, error.localizedDescription)
            } else if let document = document, document.exists {
                completion(document.data(), nil)
            } else {
                completion(nil, "User document not found")
            }
        }
    }
    
    // Helper function to update user data
    func updateUserData(_ data: [String: Any], completion: @escaping (Bool, String?) -> Void) {
        guard let userId = currentUser?.uid else {
            completion(false, "No user logged in")
            return
        }
        
        Firestore.firestore().collection("users").document(userId).updateData(data) { error in
            if let error = error {
                completion(false, error.localizedDescription)
            } else {
                completion(true, nil)
            }
        }
    }
    
    // Create a new event
    func createEvent(event: Event, completion: @escaping (Bool, String?) -> Void) {
        guard let userId = currentUser?.uid else {
            completion(false, "No user logged in")
            return
        }
        
        let eventData: [String: Any] = [
            "id": "", // This will be updated with the actual document ID
            "name": event.name,
            "description": event.description,
            "type": event.type,
            "location": event.location,
            "price": event.price,
            "owner": userId,
            "organizerName": event.organizerName,
            "shareContactInfo": event.shareContactInfo,
            "startDate": event.startDate,
            "endDate": event.endDate,
            "images": event.images,
            "maxParticipants": event.maxParticipants,
            "participants": [],
            "isTimed": event.isTimed,
            "createdAt": Timestamp(),
            "coordinates": event.coordinates,
            "status": "active"
        ]
        
        // Create the event document
        let docRef = Firestore.firestore().collection("events").document()
        var mutableEventData = eventData
        mutableEventData["id"] = docRef.documentID // Set the document ID
        
        docRef.setData(mutableEventData) { error in
            if let error = error {
                completion(false, error.localizedDescription)
            } else {
                // Update user's events created count
                self.incrementUserEventCount(userId: userId)
                completion(true, nil)
            }
        }
    }
    
    private func incrementUserEventCount(userId: String) {
        let userRef = Firestore.firestore().collection("users").document(userId)
        userRef.updateData([
            "eventsCreated": FieldValue.increment(Int64(1))
        ]) { error in
            if let error = error {
                print("Error updating user event count: \(error)")
            }
        }
    }
    
    // Fetch user's events
    func fetchUserEvents(completion: @escaping (Result<[Event], Error>) -> Void) {
        guard let userId = currentUser?.uid else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])))
            return
        }
        
        Firestore.firestore().collection("events")
            .whereField("owner", isEqualTo: userId)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                let events = documents.compactMap { document -> Event? in
                    let data = document.data()
                    
                    guard let name = data["name"] as? String,
                          let description = data["description"] as? String,
                          let type = data["type"] as? String,
                          let location = data["location"] as? String,
                          let price = data["price"] as? String,
                          let owner = data["owner"] as? String,
                          let startDate = (data["startDate"] as? Timestamp)?.dateValue(),
                          let endDate = (data["endDate"] as? Timestamp)?.dateValue(),
                          let images = data["images"] as? [String],
                          let isTimed = data["isTimed"] as? Bool,
                          let coordinates = data["coordinates"] as? [Double],
                          let organizerName = data["organizerName"] as? String,
                          let shareContactInfo = data["shareContactInfo"] as? Bool,
                          let maxParticipants = data["maxParticipants"] as? Int else {
                        return nil
                    }
                    
                    let participants = data["participants"] as? [String] ?? []
                    
                    return Event(
                        id: document.documentID,
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
                        maxParticipants: maxParticipants,
                        isTimed: isTimed,
                        createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                        coordinates: coordinates,
                        status: data["status"] as? String ?? "active"
                    )
                }
                
                completion(.success(events))
            }
    }
    
    func purchaseTicket(eventId: String, completion: @escaping (Bool, String?) -> Void) {
        guard let userId = currentUser?.uid else {
            completion(false, "No user logged in")
            return
        }
        
        let db = Firestore.firestore()
        let eventRef = db.collection("events").document(eventId)
        
        // Start a transaction to ensure data consistency
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let eventDocument: DocumentSnapshot
            do {
                try eventDocument = transaction.getDocument(eventRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            guard let eventData = eventDocument.data() else {
                let error = NSError(domain: "AppErrorDomain", code: -1, userInfo: [NSLocalizedDescriptionKey: "Event data not found"])
                errorPointer?.pointee = error
                return nil
            }
            
            // Check if user already has a ticket
            let participants = eventData["participants"] as? [String] ?? []
            if participants.contains(userId) {
                let error = NSError(domain: "AppErrorDomain", code: -1, userInfo: [NSLocalizedDescriptionKey: "You already have a ticket for this event"])
                errorPointer?.pointee = error
                return nil
            }
            
            // Check if event is full
            let maxParticipants = eventData["maxParticipants"] as? Int ?? 0
            
            if participants.count >= maxParticipants {
                let error = NSError(domain: "AppErrorDomain", code: -1, userInfo: [NSLocalizedDescriptionKey: "Event is full. Maximum capacity is \(maxParticipants)"])
                errorPointer?.pointee = error
                return nil
            }
            
            // Create ticket document
            let ticketRef = db.collection("tickets").document()
            let ticketData: [String: Any] = [
                "id": ticketRef.documentID,
                "eventId": eventId,
                "userId": userId,
                "purchaseDate": Timestamp(),
                "status": "active"
            ]
            
            // Update event document
            transaction.setData(ticketData, forDocument: ticketRef)
            transaction.updateData([
                "participants": FieldValue.arrayUnion([userId])
            ], forDocument: eventRef)
            
            // Update user's tickets
            let userRef = db.collection("users").document(userId)
            transaction.updateData([
                "tickets": FieldValue.arrayUnion([ticketRef.documentID])
            ], forDocument: userRef)
            
            return nil
        }) { (_, error) in
            if let error = error {
                completion(false, error.localizedDescription)
            } else {
                completion(true, nil)
            }
        }
    }
}


