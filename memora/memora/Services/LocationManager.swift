//
//  LocationManager.swift
//  Memora
//
//  Manages location services and geocoding
//

import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    @Published var locationString: String?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestLocation() {
        // Check authorization status
        let status = manager.authorizationStatus
        
        switch status {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
            manager.requestLocation()
        case .restricted, .denied:
            locationString = "Location access denied"
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        @unknown default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Reverse geocode to get readable address
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Geocoding error: \(error)")
                self.locationString = "Unknown location"
                return
            }
            
            if let placemark = placemarks?.first {
                // Build location string
                var components: [String] = []
                
                if let name = placemark.name, !name.isEmpty {
                    components.append(name)
                }
                if let locality = placemark.locality {
                    components.append(locality)
                }
                if let country = placemark.country {
                    components.append(country)
                }
                
                self.locationString = components.isEmpty ? "Unknown location" : components.joined(separator: ", ")
            } else {
                self.locationString = "Unknown location"
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error)")
        locationString = "Unable to get location"
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }
}

