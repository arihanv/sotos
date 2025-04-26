import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var panelViewModel: CommandPanelViewModel?

    func applicationDidFinishLaunching(_ notification: Notification) {
        panelViewModel = CommandPanelViewModel()
        panelViewModel?.setupHotKey()
    }
} 