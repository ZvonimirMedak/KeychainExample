//
//  AppDelegate.swift
//  KeychainExample
//
//  Created by Zvonimir Medak on 19.03.2021..
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        window = UIWindow(frame: UIScreen.main.bounds)
        guard let window = self.window else {
            return false
        }
        let initialViewController = UINavigationController(rootViewController: LoginViewController())
        window.rootViewController = initialViewController
        window.makeKeyAndVisible()
        return true
    }


}

