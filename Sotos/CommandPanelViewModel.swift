import AppKit
import SwiftUI
import HotKey

class CommandPanelViewModel: ObservableObject {
    @Published var isPanelVisible = false
    @Published var isSettingsVisible = false
    @Published var query = ""

    private var panelWindow: NSWindow?
    private var hotKey: HotKey?
    private var hotKey2: HotKey?

    init() {
        showPanel()
    }

    func setupHotKey() {
        // Command + Space
        hotKey = HotKey(key: .space, modifiers: [.command])
        hotKey?.keyDownHandler = { [weak self] in
            self?.togglePanel()
        }
        
        // Command + K
        hotKey2 = HotKey(key: .k, modifiers: [.command])
        hotKey2?.keyDownHandler = { [weak self] in
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
        let panel = NSPanel(
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
        
        // Add notification observer for window resigning key
        NotificationCenter.default.addObserver(
            forName: NSWindow.didResignKeyNotification,
            object: panel,
            queue: .main
        ) { [weak self] _ in
            self?.hidePanel()
        }

        // Embed your SwiftUI view
        panel.contentView = NSHostingView(rootView:
            CommandPanel(isVisible: .constant(true), query: .constant(""))
        )

        panel.orderFrontRegardless()
        panelWindow = panel
        isPanelVisible = true
    }

    private func hidePanel() {
        panelWindow?.orderOut(nil)
        panelWindow = nil
        isPanelVisible = false
    }
}
