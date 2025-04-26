//
//  ContentView.swift
//  Sotos
//
//  Created by Ethan Goodhart on 4/26/25.
//

import SwiftUI
import AppKit
import Foundation

struct ContentView: View {
    @State private var shouldShow: Bool = true
    
    var body: some View {
        ZStack {
            if shouldShow {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.yellow.opacity(0.5), lineWidth: 1)
                    .frame(width: 150, height: 30)
                    .overlay(
                        HStack(spacing: 4) {
                            Text("TAB")
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(12)
                            Text("to jump")
                        }
                        .foregroundColor(.white)
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                    )
                    .position(x: 100, y: 100)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
