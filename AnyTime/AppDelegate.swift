//
//  AppDelegate.swift
//  AnyTime
//
//  Created by Tao Xu on 9/23/17.
//  Copyright © 2017 Tao Xu. All rights reserved.
//

import UIKit
import Fabric
import Crashlytics

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.rootViewController = AppNavController(rootViewController: GlanceViewController())
        self.window?.makeKeyAndVisible()

        setupAppearance()
        registerDefaults()
        Fabric.with([Answers.self, Crashlytics.self])
        return true
    }

    func setupAppearance() {
        UINavigationBar.appearance().barTintColor = UIColor.white
        UINavigationBar.appearance().tintColor = UIColor.midnightBlue()
        UINavigationBar.appearance().isTranslucent = false
        UINavigationBar.appearance().shadowImage = UIImage()
        UINavigationBar.appearance().setBackgroundImage(UIImage(), for: .default)
        UINavigationBar.appearance().titleTextAttributes = [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 17, weight: .light)]
    }
}
