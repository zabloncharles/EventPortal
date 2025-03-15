import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var errorMessage = ""
    
    private init() {
        // Listen for auth state changes
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.isAuthenticated = user != nil
                self?.currentUser = user
            }
        }
    }
    
    func signIn(email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    completion(false, error.localizedDescription)
                } else {
                    // Update last login timestamp
                    if let userId = result?.user.uid {
                        Firestore.firestore().collection("users").document(userId).updateData([
                            "lastLogin": Timestamp()
                        ]) { error in
                            if let error = error {
                                print("Error updating last login: \(error)")
                            }
                        }
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
} 
