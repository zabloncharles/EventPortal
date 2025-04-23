import FirebaseFirestore
import FirebaseFirestoreSwift
import CoreLocation

class GroupsView: UIViewController {

    private var db = Firestore.firestore()
    private var groups: [EventGroup] = []
    private var searchText: String = ""
    private var filterModel = FilterModel()
    private var userLatitude: Double = 0.0
    private var userLongitude: Double = 0.0
    private var searchTask: DispatchWorkItem?
    private var searchResults: [EventGroup] = []

    private func searchGroups() {
        // Cancel any existing search task
        searchTask?.cancel()
        
        // Create a new search task
        let task = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            
            var query = self.db.collection("groups")
            
            // Apply search text filter if not empty
            if !self.searchText.isEmpty {
                query = query.whereField("name", isGreaterThanOrEqualTo: self.searchText)
                            .whereField("name", isLessThanOrEqualTo: self.searchText + "\u{f8ff}")
            }
            
            // Apply category filter if selected
            if let category = self.filterModel.selectedCategory, category != "All" {
                query = query.whereField("category", isEqualTo: category)
            }
            
            // Apply member count filter if selected
            if let memberCount = self.filterModel.selectedMemberCount {
                switch memberCount {
                case "Small (1-50)":
                    query = query.whereField("memberCount", isGreaterThanOrEqualTo: 1)
                               .whereField("memberCount", isLessThanOrEqualTo: 50)
                case "Medium (51-200)":
                    query = query.whereField("memberCount", isGreaterThanOrEqualTo: 51)
                               .whereField("memberCount", isLessThanOrEqualTo: 200)
                case "Large (201+)":
                    query = query.whereField("memberCount", isGreaterThanOrEqualTo: 201)
                default:
                    break
                }
            }
            
            query.getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching groups: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                var filteredGroups = documents.compactMap { document -> EventGroup? in
                    EventGroup.fromFirestore(document)
                }
                
                // Apply radius filter in memory since it requires geospatial calculations
                if let radius = self.filterModel.selectedRadius {
                    let userLocation = CLLocation(latitude: self.userLatitude, longitude: self.userLongitude)
                    filteredGroups = filteredGroups.filter { group in
                        let groupLocation = CLLocation(
                            latitude: group.location.latitude,
                            longitude: group.location.longitude
                        )
                        let distance = userLocation.distance(from: groupLocation) / 1000 // Convert to kilometers
                        
                        switch radius {
                        case "Within 5km":
                            return distance <= 5
                        case "Within 10km":
                            return distance <= 10
                        case "Within 25km":
                            return distance <= 25
                        case "Within 50km":
                            return distance <= 50
                        default:
                            return true
                        }
                    }
                }
                
                // Update both the main groups list and search results
                DispatchQueue.main.async {
                    self.groups = filteredGroups
                    self.searchResults = filteredGroups
                }
            }
        }
        
        // Store the task and schedule it
        searchTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: task)
    }
    
    // Call this method when the search text changes
    func searchTextDidChange(_ newText: String) {
        searchText = newText
        searchGroups()
    }
} 