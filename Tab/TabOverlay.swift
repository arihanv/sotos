//
//  ContentView.swift
//  Tab
//
//  Created by Ethan Goodhart on 4/26/25.
//

import SwiftUI
import AppKit
import Foundation

struct TabOverlay: View {
    @State private var shouldShow: Bool = true
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            if shouldShow {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.yellow.opacity(0.8), lineWidth: 2)
//                    .background(RoundedRectangle(cornerRadius: 4).fill(Color.black.opacity(0.85)))
                    .overlay(
                        HStack(spacing: 4) {
                            Text("TAB")
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.yellow.opacity(0.7))
                                .foregroundColor(.black)
                                .cornerRadius(12)
                            Text("to jump")
                                .foregroundColor(.white)
                        }
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                    )
                    .padding(16)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .ignoresSafeArea()
    }
}

#Preview {
    TabOverlay()
}
