import AppKit
import SwiftUI
import HotKey

class CommandPanelViewModel: ObservableObject {
    @Published var isPanelVisible = false
    @Published var isSettingsVisible = false
    @Published var query = ""

    private var panelWindow: NSWindow?
    private var hotKey: HotKey?

    private var clickMonitor: Any?

    func setupHotKey() {
        // Command + K
        hotKey = HotKey(key: .l, modifiers: [.command])
        hotKey?.keyDownHandler = { [weak self] in
            self?.togglePanel()
        }
    }

    func togglePanel() {
        if panelWindow == nil {
            showPanel()
        } else {
            hidePanel()
        }
    }

    private func showPanel() {
        isPanelVisible = true
        let panel = FocusablePanel(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 64),
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
            )
        )
        
        // Embed the SwiftUI view
        panel.contentView = NSHostingView(rootView: contentView)

        // Order the panel to front and make it key
        panel.orderFrontRegardless()
        panel.makeKeyAndOrderFront(nil)
        
        // Add notification observer for window resigning key
        NotificationCenter.default.addObserver(
            forName: NSWindow.didResignKeyNotification,
            object: panel,
            queue: .main
        ) { [weak self] _ in
            self?.hidePanel()
        }

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
}
