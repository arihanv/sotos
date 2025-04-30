//
//  ContentView.swift
//  Tab
//
//  Created by Ethan Goodhart on 4/26/25.
//

import SwiftUI
import HotKey

struct ContentView: View {
    @StateObject private var panelViewModel = CommandPanelViewModel()

    var body: some View {
        Color.clear
            .onAppear {
                for window in NSApplication.shared.windows {
                    window.level = .statusBar
                }
            }
            .onAppear {
                panelViewModel.setupHotKey()
            }
    }
}

#Preview {
    ContentView()
}
