import Foundation
import CoreLocation
import FirebaseFirestore

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var location: CLLocation?
    @Published var locationString: String = "Not set"
    @Published var authorizationStatus: CLAuthorizationStatus
    @Published var isLoading = false
    
    override init() {
        authorizationStatus = locationManager.authorizationStatus
        
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestLocation() {
        isLoading = true
        locationManager.requestLocation()
    }
    
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        self.location = location
        updateLocationString(for: location)
        isLoading = false
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
        isLoading = false
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
    }
    
    private func updateLocationString(for location: CLLocation) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] (placemarks, error) in
            DispatchQueue.main.async {
                if let error = error {
                    print("Geocoding error: \(error.localizedDescription)")
                    self?.locationString = "Location error"
                    return
                }
                
                if let placemark = placemarks?.first {
                    let city = placemark.locality ?? ""
                    let state = placemark.administrativeArea ?? ""
                    let country = placemark.country ?? ""
                    
                    self?.locationString = [city, state, country]
                        .filter { !$0.isEmpty }
                        .joined(separator: ", ")
                }
            }
        }
    }
    
    func updateUserLocation(userId: String) {
        guard let location = location else { return }
        
        let db = Firestore.firestore()
        let userData: [String: Any] = [
            "location": GeoPoint(latitude: location.coordinate.latitude,
                               longitude: location.coordinate.longitude),
            "locationString": locationString,
            "lastLocationUpdate": Date()
        ]
        
        db.collection("users").document(userId).updateData(userData) { error in
            if let error = error {
                print("Error updating user location: \(error.localizedDescription)")
            }
        }
    }
    
    func fetchUserLocation(userId: String) {
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { [weak self] document, error in
            if let error = error {
                print("Error fetching user location: \(error.localizedDescription)")
                return
            }
            
            if let document = document,
               let locationString = document.get("locationString") as? String {
                DispatchQueue.main.async {
                    self?.locationString = locationString
                }
            }
        }
    }
} 
