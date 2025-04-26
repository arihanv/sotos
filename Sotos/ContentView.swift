//
//  ContentView.swift
//  Sotos
//
//  Created by Ethan Goodhart on 4/26/25.
//

import SwiftUI
import HotKey

struct ContentView: View {
    @StateObject private var panelViewModel = CommandPanelViewModel()

    var body: some View {
        ZStack {
            CommandPanel(isVisible: $panelViewModel.isPanelVisible, query: $panelViewModel.query)
        }
        .onAppear {
            for window in NSApplication.shared.windows {
                window.level = .statusBar
            }
        }
        .sheet(isPresented: $panelViewModel.isSettingsVisible) {
            CommandPanelSettings(viewModel: panelViewModel)
        }
        .onAppear {
            panelViewModel.setupHotKey()
        }
    }
}

#Preview {
    ContentView()
}
