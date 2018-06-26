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

/// Container of a single measurement data
private class WeatherContainer {
    private var features:UInt32
    private var timestamp:UInt32
    var latitude:Float32 = 0.0
    var longitude:Float32 = 0.0
    var pressure:Float32 = 0.0
    var temperature:Float32 = 0.0
    var altitude:Float32 = 0.0
    
    init(hasBarometer:Bool, hasThermometer:Bool, hasAltimeter:Bool)
    {
        timestamp = UInt32(NSDate().timeIntervalSince1970)
        features = 0
        if hasBarometer {
            features |= 1
        }
        if hasThermometer {
            features |= 2
        }
        if hasAltimeter {
            features |= 4
        }
    }
    
    func appendTo(data:inout Data)
    {
        data.append(UnsafeBufferPointer(start: &features, count: 1))
        data.append(UnsafeBufferPointer(start: &timestamp, count: 1))
        data.append(UnsafeBufferPointer(start: &latitude, count: 1))
        data.append(UnsafeBufferPointer(start: &longitude, count: 1))
        data.append(UnsafeBufferPointer(start: &pressure, count: 1))
        data.append(UnsafeBufferPointer(start: &temperature, count: 1))
        data.append(UnsafeBufferPointer(start: &altitude, count: 1))
    }
    
    func isValid() -> Bool {
        return latitude != Float32.nan && longitude != Float32.nan && altitude != Float32.nan
    }
}

/// Collect weather data from the mobile device
class WeatherData: NSObject, CLLocationManagerDelegate {
    
    var altimeter:CMAltimeter!
    var locationManager:CLLocationManager!
    
    private var hasBarometer:Bool = false
    private var hasThermometer:Bool = false
    private var hasAltimeter:Bool = false
    private var hasGps:Bool = false
    
    private var pressure:NSNumber = 0
    private var altitude:NSNumber = 0
    private var location:CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    
    private var unsentHistory:[WeatherContainer] = []
    
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
            hasBarometer = true
            hasAltimeter = true
            
            altimeter.startRelativeAltitudeUpdates(to: .main) { (data, err) in
                self.pressure = (data?.pressure)!
                self.altitude = (data?.relativeAltitude)!
            }
            
            return true
        }
        else
        {
            NSLog("ERROR: Barometer is not available")
        }
        
        return false
    }
    
    /// User authorization has changed
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        
        if status != .authorizedAlways {
            NSLog("ERROR: App needs to update location always")
            return
        }
        
        hasGps = true
        
        locationManager.startUpdatingLocation()
        location = manager.location!.coordinate
    }
    
    /// Location has been updated
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.location = locations[locations.count - 1].coordinate
    }
    
    /// Write datagram header
    private func appendHeaderTo(data:inout Data) {
        var count:UInt32 = UInt32(unsentHistory.count) + 1
        let version:UInt32 = 1
        let size:UInt32 = 12 + (count * 28) // 12 byte header + 1 (or more) * 28 byte container
        var versionSize:UInt32 = 0
        var timestamp:UInt32 = UInt32(NSDate().timeIntervalSince1970)
        versionSize |= (version & 0xFFFF) // Upper 16 bits are version
        versionSize |= ((size & 0xFFFF) << 16) // Lower 16 bits are size
        data.append(UnsafeBufferPointer(start: &versionSize, count: 1))
        data.append(UnsafeBufferPointer(start: &timestamp, count: 1))
        data.append(UnsafeBufferPointer(start: &count, count: 1))
    }
    
    /// Send current data to server
    func sendToServer(host:String, port:UInt16) {
        if !hasGps {
            NSLog("FAILED: No GPS, location information is mandatory")
            return
        }
        
        // Create current data content
        let content = WeatherContainer(hasBarometer: hasBarometer, hasThermometer: hasThermometer, hasAltimeter: hasAltimeter)
        content.latitude = Float32(location.latitude)
        content.longitude = Float32(location.longitude)
        content.altitude = Float32(altitude.floatValue)
        content.pressure = Float32(pressure.floatValue)
        
        if !content.isValid() {
            NSLog("WARNING: GPS not ready")
            return
        }
        
        let connection = WeatherConnection()
        if connection.connect(host: host, port: port) == false {
            // Delay sending till next time
            self.unsentHistory.append(content)
            NSLog("WARNING: No connection - delay sending")
        } else {
            var data:Data = Data()
            
            // Write data pakcet header
            appendHeaderTo(data: &data)
            
            // Write current data container
            content.appendTo(data: &data)
            
            // Write other data containers that failed to send before
            for a in self.unsentHistory {
                a.appendTo(data: &data)
            }
            
            // Send datagram
            if connection.send(data: data) == false {
                // Delay sending till next time
                self.unsentHistory.append(content)
                NSLog("WARNING: Failed to send - delay sending")
            } else {
                // Empty unsent list as everything has been sent successfully
                self.unsentHistory.removeAll()
            }
            
            // Close connection
            connection.disconnect()
        }
    }
}
