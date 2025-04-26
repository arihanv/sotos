//
//  SotosApp.swift
//  Sotos
//
//  Created by Ethan Goodhart on 4/26/25.
//

import SwiftUI

@main
struct SotosApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // No WindowGroup, so no default window
        Settings {
            EmptyView()
        }
    }
}
