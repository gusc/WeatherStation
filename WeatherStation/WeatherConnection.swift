//
//  WeatherConnection.swift
//  WeatherStation
//
//  Created by Gusts Kaksis on 26/05/2018.
//  Copyright © 2018 Gusts Kaksis. All rights reserved.
//

import Foundation
import SwiftSocket

/// TCP socket connection to weather server
class WeatherConnection: NSObject {
    
    var client:TCPClient!
    
    override init() {
        
    }
    
    func connect(host:String, port:Int16) -> Bool {
        client = TCPClient(address: host, port: Int32(port))
        switch client.connect(timeout: 10) {
            case .success:
                return true
            case .failure(let error):
                NSLog("Failed to connect to server: " + error.localizedDescription)
                return false
        }
    }
    
    func send(data:Data) -> Bool {
        if client != nil {
            switch client.send(data: data) {
                case .success:
                    return true
                case .failure(let error):
                    NSLog("Failed to send data: " + error.localizedDescription)
                    return false
            }
        }
        return false
    }
}
