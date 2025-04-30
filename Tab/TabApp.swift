//
//  TabApp.swift
//  Tab
//
//  Created by Ethan Goodhart on 4/26/25.
//

import SwiftUI

@main
struct TabApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // No WindowGroup, so no default window
        Settings {
            CommandPanelSettings(viewModel: appDelegate.panelViewModel)
        }
    }
}
