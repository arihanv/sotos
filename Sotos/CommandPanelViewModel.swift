import AppKit
import SwiftUI
import HotKey
import Darwin

class CommandPanelViewModel: ObservableObject {
    @Published var isPanelVisible = false
    @Published var isSettingsVisible = false
    @Published var query = ""
    @Published var isExecuting = false
    @Published var executionStatus: String? = nil

    private var panelWindow: NSWindow?
    private var hotKey: HotKey?

    private var clickMonitor: Any?
    private var lastBecameActive: Date? = nil
    private var runningProcess: Process? = nil
    private var executionPanelWindow: NSWindow? = nil

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
        if panelWindow != nil {
            // Panel is already open, just bring it to front
            panelWindow?.orderFrontRegardless()
            panelWindow?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
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

    func runAgent(with prompt: String) {
        guard !isExecuting else { return }
        isExecuting = true
        executionStatus = "Running..."
        hidePanel()

        let agentPath = "/Users/arihanvaranasi/Dev/sotos/zeus-agent/agent.py"
        let condaEnv = "zeus"
        let command = "source /opt/homebrew/Caskroom/miniforge/base/etc/profile.d/conda.sh && conda activate \(condaEnv) && python3 \(agentPath) \"\(prompt)\""

        let process = Process()
        process.launchPath = "/bin/zsh"
        process.arguments = ["-c", command]
        process.currentDirectoryPath = "/Users/arihanvaranasi/Dev/sotos/zeus-agent/"

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = outputPipe

        // Print output to Swift terminal as it is received
        outputPipe.fileHandleForReading.readabilityHandler = { handle in
            if let str = String(data: handle.availableData, encoding: .utf8), !str.isEmpty {
                print("[agent.py]", str)
            }
        }

        process.terminationHandler = { [weak self] proc in
            DispatchQueue.main.async {
                self?.isExecuting = false
                self?.executionStatus = "Finished"
                self?.showPanel()
                self?.closeExecutionPanel()
            }
            outputPipe.fileHandleForReading.readabilityHandler = nil
        }

        do {
            runningProcess = process
            try process.run()
            showExecutionPanel()
        } catch {
            isExecuting = false
            executionStatus = "Failed to start: \(error.localizedDescription)"
            showPanel()
        }
    }

    func stopAgent() {
        if let process = runningProcess {
            process.terminate()
            // If still running after a short delay, force kill
            DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) { [weak self] in
                if process.isRunning {
                    kill(process.processIdentifier, SIGKILL)
                }
            }
        }
        runningProcess = nil
        isExecuting = false
        executionStatus = "Stopped"
        showPanel()
        closeExecutionPanel()
    }

    private func showExecutionPanel() {
        guard executionPanelWindow == nil else { return }
        let panel = FocusablePanel(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 120),
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

        let contentView = ExecutionPanel(viewModel: self)
        panel.contentView = NSHostingView(rootView: contentView)
        panel.orderFrontRegardless()
        panel.makeKeyAndOrderFront(nil)
        executionPanelWindow = panel
        NSApp.activate(ignoringOtherApps: true)
    }

    private func closeExecutionPanel() {
        executionPanelWindow?.orderOut(nil)
        executionPanelWindow = nil
    }
}
