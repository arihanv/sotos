import SwiftUI

struct ExecutionPanel: View {
    @ObservedObject var viewModel: CommandPanelViewModel

    var body: some View {
        HStack {
            Spacer()
            Button(action: {
                viewModel.stopAgent()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                    Text("Stop")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color.white)
                )
            }
            .buttonStyle(PlainButtonStyle())
            Spacer()
        }
        .frame(width: 420, height: 140)
    }
} 