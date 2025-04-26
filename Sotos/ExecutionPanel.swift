import SwiftUI

struct ExecutionPanel: View {
    @ObservedObject var viewModel: CommandPanelViewModel

    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5)
            Text(viewModel.executionStatus ?? "Running...")
                .font(.system(size: 16, weight: .medium))
            Button(action: {
                viewModel.stopAgent()
            }) {
                Text("Stop")
                    .font(.system(size: 16, weight: .bold))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding(32)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.18), radius: 16, x: 0, y: 4)
        .frame(width: 400, height: 120)
    }
} 