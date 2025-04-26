import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var panelViewModel = CommandPanelViewModel()

    func applicationDidFinishLaunching(_ notification: Notification) {
        panelViewModel.setupHotKey()
        NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.panelViewModel.appDidBecomeActive()
        }
    }
} 