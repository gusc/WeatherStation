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
    
    /// Send current data to server
    func sendToServer(host:String, port:UInt16) {
        let connection = WeatherConnection()
        if connection.connect(host: host, port: port) {
            var data:Data = Data()
            
            // Write datagram version and capability bits
            var version:UInt32 = 1 << 16 // Upper 16 bits are version
            // Capability bits:
            // 0 - pressure
            // 1 - temperature
            version |= 1 // This app only supports pressure sensors
            data.append(UnsafeBufferPointer(start: &version, count: 1))
            
            // Write GPS coordinates
            var lat = Float(location.latitude)
            var lng = Float(location.longitude)
            var alt = altitude.floatValue
            data.append(UnsafeBufferPointer(start: &lat, count: 1))
            data.append(UnsafeBufferPointer(start: &lng, count: 1))
            data.append(UnsafeBufferPointer(start: &alt, count: 1))
            
            // Write pressure data
            var press = pressure.floatValue
            data.append(UnsafeBufferPointer(start: &press, count: 1))
            
            // Write temperature data - not available
            var temp:Float = 0.0
            data.append(UnsafeBufferPointer(start: &temp, count: 1))
            
            // Zero-fill to 8 * 4 byte boundary
            var zero:Float = 0.0
            data.append(UnsafeBufferPointer(start: &zero, count: 1))
            data.append(UnsafeBufferPointer(start: &zero, count: 1))
            
            // Send datagram
            connection.send(data: data)
            connection.disconnect()
        }
    }
    
    /// User authorization has changed
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status != .authorizedAlways {
            NSLog("App needs to update location always")
            return
        }
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.startUpdatingLocation()
        location = manager.location!.coordinate
    }
    
    /// Location has been updated
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations[locations.count - 1].coordinate
    }
}
