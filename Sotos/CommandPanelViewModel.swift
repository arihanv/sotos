import AppKit
import SwiftUI
import HotKey
import Combine

class CommandPanelViewModel: ObservableObject {
    @Published var isPanelVisible = false
    @Published var isSettingsVisible = false
    @Published var query = ""

    private var panelWindow: NSWindow?
    private var hotKey: HotKey?

    private var clickMonitor: Any?
    private var lastBecameActive: Date? = nil

    func setupHotKey() {
        // Command + K
        hotKey = HotKey(key: .l, modifiers: [.command])
        hotKey?.keyDownHandler = { [weak self] in
            self?.togglePanel()
        }
    }

    func updateHotKey(key: String, modifiers: [NSEvent.ModifierFlags]) {
        // Remove the old hotkey
        hotKey = nil
        // Map the string key to Key enum
        guard let keyEnum = Key(string: key) else { return }
        hotKey = HotKey(key: keyEnum, modifiers: NSEvent.ModifierFlags(modifiers))
        hotKey?.keyDownHandler = { [weak self] in
            self?.togglePanel()
        }
    }

    func appDidBecomeActive() {
        lastBecameActive = Date()
    }

    func togglePanel() {
        // Prevent showing panel if app just became active (e.g., after Cmd+Tab)
        if let lastActive = lastBecameActive, Date().timeIntervalSince(lastActive) < 0.5 {
            return
        }
        if panelWindow == nil {
            showPanel()
        } else {
            hidePanel()
        }
    }

    private func showPanel() {
        isPanelVisible = true
        let panel = FocusablePanel(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 160),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isReleasedWhenClosed = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.center()
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.title = ""
        panel.isMovable = true
        panel.isMovableByWindowBackground = true

        // Create the SwiftUI view with proper bindings
        let contentView = CommandPanel(
            isVisible: Binding(
                get: { self.isPanelVisible },
                set: { self.isPanelVisible = $0 }
            ),
            query: Binding(
                get: { self.query },
                set: { self.query = $0 }
            ),
            viewModel: self
        )
        
        // Embed the SwiftUI view
        panel.contentView = NSHostingView(rootView: contentView)

        // Order the panel to front and make it key
        panel.orderFrontRegardless()
        panel.makeKeyAndOrderFront(nil)
        
        // Add global click monitor to hide panel on click off
        clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self, let panelWindow = self.panelWindow else { return }
            let mouseLocation = NSEvent.mouseLocation
            let windowFrame = panelWindow.frame
            if !windowFrame.contains(mouseLocation) {
                self.hidePanel()
            }
        }

        panelWindow = panel
        
        // Focus the window
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
    }

    private func hidePanel() {
        if let clickMonitor = clickMonitor {
            NSEvent.removeMonitor(clickMonitor)
            self.clickMonitor = nil
        }
        panelWindow?.orderOut(nil)
        panelWindow = nil
        isPanelVisible = false
    }

    func openSettings() {
        NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
    }
}

class GlobalOverlayManager {
    static let shared = GlobalOverlayManager()
    private var overlayWindows: [NSPanel] = []
    private var cancellable: AnyCancellable?
    private var timer: Timer?

    private var dom: [Int: DOMElement] = [:]

    func showOverlay() {
        guard overlayWindows.isEmpty else { return }
        
        // Start a timer that updates the DOM every 1 second
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.dom = getCurrentDom()
            let dom_str = domToString(some_dom: self.dom)
            print(dom_str)
            
            // Clear existing overlay windows
            for window in self.overlayWindows {
                window.orderOut(nil)
            }
            self.overlayWindows.removeAll()
            
            // Create overlays for the first 30 DOM elements
            let elementsToShow = Array(self.dom.values.filter { $0.isClickable }.prefix(200))
            let screenHeight = NSScreen.main?.frame.height ?? 0
            for element in elementsToShow {
                let frame = element.frame
                let padding: CGFloat = 12.0
                let x = floor(frame.origin.x) - padding
                let y = floor(screenHeight - frame.origin.y - frame.size.height) - padding
                let width = ceil(frame.size.width) + 2 * padding
                let height = ceil(frame.size.height) + 2 * padding
                let panel = NSPanel(
                    contentRect: NSRect(x: x, y: y, width: width, height: height),
                    styleMask: [.borderless, .nonactivatingPanel],
                    backing: .buffered,
                    defer: false
                )
                panel.isReleasedWhenClosed = false
                panel.level = .statusBar
                panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
                panel.isOpaque = false
                panel.backgroundColor = .clear
                panel.hasShadow = false
                panel.ignoresMouseEvents = true
                panel.title = ""
                panel.contentView = NSHostingView(rootView: TabOverlay())
                panel.orderFrontRegardless()
                self.overlayWindows.append(panel)
            }
        }
    }

    func hideOverlay() {
        // Invalidate the timer when hiding the overlay
        timer?.invalidate()
        timer = nil
        
        // Hide and clear all overlay windows
        for window in overlayWindows {
            window.orderOut(nil)
        }
        overlayWindows.removeAll()
    }
}
