//
//  AppDelegate.swift
//  watchDemo-iOS
//
//  Created by RatneshShukla on 19/11/22.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }
        
    class func shareDelegate() -> AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }
}
