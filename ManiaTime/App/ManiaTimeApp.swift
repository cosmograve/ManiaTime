//
//  ManiaTimeApp.swift
//  ManiaTime
//
//  Created by Алексей Авер on 28.01.2026.
//

import SwiftUI

@main
struct ManiaTimeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        OrientationManager.shared.mask
    }
}
