//
//  WeatherData.swift
//  WeatherStation
//
//  Created by Gusts Kaksis on 26/05/2018.
//  Copyright © 2018 Gusts Kaksis. All rights reserved.
//

import Foundation
import CoreMotion
import CoreLocation

/// Collect weather data from the mobile device
class WeatherData: NSObject, CLLocationManagerDelegate {
    
    var altimeter:CMAltimeter!
    var locationManager: CLLocationManager!
    
    var pressure:NSNumber = 0
    var altitude:NSNumber = 0
    var location:CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    
    /// Constructor
    override init() {
        altimeter = CMAltimeter()
        locationManager = CLLocationManager()
    }
    
    /// Start data capture proc
    /// @return true if the setup was successfull
    func startCapturingData() -> Bool {
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization() // To use in background
        
        if CMAltimeter.isRelativeAltitudeAvailable() {
            NSLog("Barometer is available")
            
            altimeter.startRelativeAltitudeUpdates(to: .main) { (data, err) in
                self.pressure = (data?.pressure)!
                self.altitude = (data?.relativeAltitude)!
            }
            
            return true
        }
        
        return false
    }
    
    /// User authorization has changed
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status != .authorizedAlways {
            NSLog("App needs to update location always")
            return
        }
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        location = manager.location!.coordinate
    }
    
    /// Location has been updated
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations[locations.count - 1].coordinate
    }
}
