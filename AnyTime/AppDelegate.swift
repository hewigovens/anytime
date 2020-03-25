//
//  AppDelegate.swift
//  AnyTime
//
//  Created by Tao Xu on 9/23/17.
//  Copyright © 2017 Tao Xu. All rights reserved.
//

import UIKit
#if !targetEnvironment(macCatalyst)
import Fabric
import Crashlytics
#endif

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = UINavigationController(rootViewController: GlanceViewController())
        window?.makeKeyAndVisible()
        window?.overrideUserInterfaceStyle = .light

        setupAppearance()
        #if targetEnvironment(macCatalyst)
            window?.windowScene?.titlebar?.titleVisibility = .hidden
            window?.windowScene?.titlebar?.toolbar = nil
        #else
            Fabric.with([Answers.self, Crashlytics.self])
        #endif
        return true
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        guard let nav = window?.rootViewController as? UINavigationController,
            let controller = nav.topViewController as? GlanceViewController else { return }
        controller.update(date: Date())
    }

    func setupAppearance() {
        UINavigationBar.appearance().barTintColor = UIColor.white
        UINavigationBar.appearance().tintColor = UIColor.midnightBlue()
        UINavigationBar.appearance().isTranslucent = false
        UINavigationBar.appearance().shadowImage = UIImage()
        UINavigationBar.appearance().setBackgroundImage(UIImage(), for: .default)
        UINavigationBar.appearance().titleTextAttributes = [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17, weight: .light)
        ]
    }
}
