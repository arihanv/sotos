import SwiftUI

struct CommandPanel: View {
    @Binding var isVisible: Bool
    @Binding var query: String
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        if isVisible {
            ZStack {
                Color.clear
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation { isVisible = false }
                    }
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 12) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.white)
                        TextField("dog image from google chrome and share it with my bos", text: $query)
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(.system(size: 18, weight: .medium))
                            .frame(height: 28)
                            .focused($isTextFieldFocused)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 18)
                }
                .background(Color.black.opacity(0.9))
                .cornerRadius(18)
                .frame(width: 520)
                .onAppear {
                    isTextFieldFocused = true
                }
            }
            .transition(.opacity)
        }
    }
} 