import SwiftUI

struct CommandPanel: View {
    @Binding var isVisible: Bool
    @Binding var query: String
    @FocusState private var isTextFieldFocused: Bool
    @ObservedObject var viewModel: CommandPanelViewModel

    var body: some View {
        if isVisible {
            ZStack {
                Color.clear.ignoresSafeArea().onTapGesture {
                    withAnimation { isVisible = false }
                }
                
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 12) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.black.opacity(0.7))
                            .font(.system(size: 20))
                        TextField("dog image from google chrome and share it with my bos", text: $query)
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(.system(size: 18, weight: .medium))
                            .frame(height: 28)
                            .focused($isTextFieldFocused)
                            .foregroundColor(.black)
                        Spacer()
                        Image(systemName: "mic.fill")
                            .foregroundColor(.black.opacity(0.7))
                            .font(.system(size: 20))
                        Image(systemName: "gearshape")
                            .foregroundColor(.black.opacity(0.7))
                            .font(.system(size: 20))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 18)
                    Divider().padding(.horizontal, 8)
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 10) {
                            Image(systemName: "photo.on.rectangle")
                                .foregroundColor(.gray)
                            Text("Select a cute dog image")
                                .foregroundColor(.gray)
                                .font(.system(size: 16))
                        }
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            query = "Select a cute dog image"
                            isTextFieldFocused = true
                        }
                        HStack(spacing: 10) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.gray)
                            Text("Share the image via iMessage")
                                .foregroundColor(.gray)
                                .font(.system(size: 16))
                        }
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            query = "Share the image via iMessage"
                            isTextFieldFocused = true
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 10)
                }
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.18), radius: 16, x: 0, y: 4)
                .frame(width: 700, height: 160)
                .onAppear { isTextFieldFocused = true }
                .onTapGesture { }
            }
            .transition(.opacity)
        }
    }
} 
