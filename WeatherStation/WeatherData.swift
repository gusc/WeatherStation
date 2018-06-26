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

private class WeatherContainer {
    private var features:UInt32
    private var timestamp:UInt32
    var latitude:Float32
    var longitude:Float32
    var pressure:Float32
    var temperature:Float32
    var altitude:Float32
    
    init()
    {
        timestamp = NSDate().timeIntervalSince1970
        features = 0x5 // This app only supports pressure and altitude data
    }
    
    func appendTo(data:Data)
    {
        data.append(UnsafeBufferPointer(start: &features, count: 1))
        data.append(UnsafeBufferPointer(start: &timestamp, count: 1))
        data.append(UnsafeBufferPointer(start: &latitude, count: 1))
        data.append(UnsafeBufferPointer(start: &longitude, count: 1))
        data.append(UnsafeBufferPointer(start: &pressure, count: 1))
        data.append(UnsafeBufferPointer(start: &temperature, count: 1))
        data.append(UnsafeBufferPointer(start: &altitude, count: 1))
    }
}

/// Collect weather data from the mobile device
class WeatherData: NSObject, CLLocationManagerDelegate {
    
    var altimeter:CMAltimeter!
    var locationManager:CLLocationManager!
    
    var pressure:NSNumber = 0
    var altitude:NSNumber = 0
    var location:CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    
    var unsentHistory:[WeatherContainer]
    
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
    
    // Write datagram header
    private func appendHeaderTo(data:Data) -> UInt16 {
        let count:UInt32 = unsentHistory.count + 1
        let version:UInt16 = 1
        let size:UInt16 = 12 + (count) * 28 // 12 byte header + 1 (or more) * 28 byte container
        var versionSize:UInt32 = 0
        let timestamp:UInt32 = NSDate().timeIntervalSince1970
        versionSize |= (version << 16) // Upper 16 bits are version
        versionSize |= size // Lower 16 bits are size
        data.append(UnsafeBufferPointer(start: &versionSize, count: 1))
        data.append(UnsafeBufferPointer(start: &timestamp, count: 1))
        return size
    }
    
    /// Send current data to server
    func sendToServer(host:String, port:UInt16) {
        let connection = WeatherConnection()
        if connection.connect(host: host, port: port) {
            var data:Data = Data()
            
            // Write data pakcet header
            let size = appendHeaderTo(data: data)
            
            // Create current data content
            var content = WeatherContainer()
            content.latitude = Float32(location.latitude)
            content.longitude = Float32(location.longitude)
            content.altitude = Float32(altitude.floatValue)
            content.pressure = Float32(pressure.floatValue)
            content.temperature = 0.0
            
            // Write current data container
            content.appendTo(data: data)
            
            // Write other data containers that failed to send before
            for a in self.unsentHistory {
                a.appendTo(data)
            }
            
            // Send datagram
            if connection.send(data: data) == false {
                // Delay sending till next time
                self.unsentHistory.append(content)
            } else {
                // Empty unsent list as everything has been sent successfully
                self.unsentHistory.removeAll()
            }
            
            // Close connection
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
        self.location = locations[locations.count - 1].coordinate
    }
}
