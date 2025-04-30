import Foundation
import CoreLocation
import FirebaseFirestore
import SwiftUI

class LocationManager: NSObject, ObservableObject {
    static let shared = LocationManager()
    private let locationManager = CLLocationManager()
    @Published var location: CLLocation?
    @Published var locationString: String = "Not Set"
    @Published var coordinates: [Double] = [0.0, 0.0]
    @Published var authorizationStatus: CLAuthorizationStatus
    @Published var isLoading = false
    
    // AppStorage for persistent location data
    @AppStorage("userLocationString") private var storedLocationString: String = "Not Set"
    @AppStorage("userLatitude") private var storedLatitude: Double = 0.0
    @AppStorage("userLongitude") private var storedLongitude: Double = 0.0
    @AppStorage("lastLocationUpdate") private var lastLocationUpdate: Double = 0.0
    
    // Add caching and rate limiting
    private var geocodingCache: [String: String] = [:]
    private var lastGeocodingRequest: Date?
    private let minimumGeocodingInterval: TimeInterval = 1.0 // Minimum 1 second between requests
    private let minimumLocationUpdateInterval: TimeInterval = 300 // 5 minutes between updates
    
    override init() {
        authorizationStatus = locationManager.authorizationStatus
        
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Update location when user moves 10 meters
        locationManager.allowsBackgroundLocationUpdates = false
        locationManager.pausesLocationUpdatesAutomatically = false
        
        // Load stored location on init
        loadStoredLocation()
        
        // Request authorization and start updating immediately
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        // Force an initial location update
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.forceLocationUpdate()
        }
        
        // Add notification observers for app lifecycle
        NotificationCenter.default.addObserver(self,
                                             selector: #selector(appDidBecomeActive),
                                             name: UIApplication.didBecomeActiveNotification,
                                             object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func appDidBecomeActive() {
        // Check if enough time has passed since last update
        let currentTime = Date().timeIntervalSince1970
        if currentTime - lastLocationUpdate >= minimumLocationUpdateInterval {
            forceLocationUpdate()
        }
    }
    
    private func loadStoredLocation() {
        locationString = storedLocationString
        coordinates = [storedLatitude, storedLongitude]
        if storedLatitude != 0.0 && storedLongitude != 0.0 {
            location = CLLocation(latitude: storedLatitude, longitude: storedLongitude)
        }
    }
    
    private func storeLocation(_ location: CLLocation, _ locationString: String) {
        storedLocationString = locationString
        storedLatitude = location.coordinate.latitude
        storedLongitude = location.coordinate.longitude
        lastLocationUpdate = Date().timeIntervalSince1970
        self.locationString = locationString
        self.coordinates = [location.coordinate.latitude, location.coordinate.longitude]
        self.location = location
    }
    
    func forceLocationUpdate() {
        isLoading = true
        locationManager.requestLocation()
        
        // If we don't get a location update within 5 seconds, try again
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            if self?.location == nil {
                self?.locationManager.requestLocation()
            }
        }
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
        
        // Stop updating location after we get a good fix
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
        isLoading = false
        
        // If we fail to get location, try again after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.locationManager.requestLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
        
        // If we get authorization, request location immediately
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            forceLocationUpdate()
        }
    }
    
    func updateLocationString(for location: CLLocation) {
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
                    
                    let newLocationString = [city, state, country]
                        .filter { !$0.isEmpty }
                        .joined(separator: ", ")
                    
                    self?.storeLocation(location, newLocationString)
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
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching user location: \(error.localizedDescription)")
                return
            }
            
            if let data = document?.data(),
               let locationString = data["locationString"] as? String,
               let coordinates = data["coordinates"] as? [Double],
               coordinates.count >= 2 {
                
                let location = CLLocation(
                    latitude: coordinates[0],
                    longitude: coordinates[1]
                )
                
                self.storeLocation(location, locationString)
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            locationManager.stopUpdatingLocation()
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        @unknown default:
            break
        }
    }
} 
