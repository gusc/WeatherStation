//
//  AppDelegate.swift
//  WeatherStation
//
//  Created by Gusts Kaksis on 26/05/2018.
//  Copyright © 2018 Gusts Kaksis. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window:UIWindow?
    var data:WeatherData!
    var backgroundTask:UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    var timer:Timer?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        data = WeatherData()
        if data.startCapturingData() {
            NSLog("Data capture started")
        }
        
        self.timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [self] _ in
            self.startBackgroundTask()
        }
        
        return true
    }
    
    func startBackgroundTask() {
        NSLog("Send data")
        
        self.backgroundTask = UIApplication.shared.beginBackgroundTask(expirationHandler: {
            self.endBackgroundTask()
        })
        
        if self.backgroundTask == UIBackgroundTaskInvalid {
            NSLog("ERROR: Failed to start background task")
        }
        
        self.data.sendToServer(host:"192.168.0.124", port:6868)
        
        self.endBackgroundTask()
    }
    
    func endBackgroundTask() {
        UIApplication.shared.endBackgroundTask(backgroundTask)
        self.backgroundTask = UIBackgroundTaskInvalid
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

