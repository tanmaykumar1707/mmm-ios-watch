//
//  mmmApp.swift
//  mmm Watch App
//
//  Created by Tanmay Kumar on 10/11/26.
//

import SwiftUI

@main
struct mmm_Watch_AppApp: App {

    @WKApplicationDelegateAdaptor var delegate: AppDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, WKApplicationDelegate {
    func applicationDidFinishLaunching() {
        // Boot WCSession connector before first view renders
        _ = PhoneConnector.shared
    }
}
