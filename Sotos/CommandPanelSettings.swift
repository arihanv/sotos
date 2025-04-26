import SwiftUI
import HotKey

struct CommandPanelSettings: View {
    @ObservedObject var viewModel: CommandPanelViewModel

    let availableKeys: [String] = Array("abcdefghijklmnopqrstuvwxyz").map { String($0) }
    let availableModifiers: [NSEvent.ModifierFlags] = [.command, .option, .control, .shift]

    var body: some View {
        Form {
            // Picker("Key", selection: $viewModel.key) {
            //     ForEach(availableKeys, id: \ .self) { key in
            //         Text(String(describing: key)).tag(key)
            //     }
            // }
            // HStack {
            //     Text("Modifiers")
            //     ForEach(availableModifiers, id: \.rawValue) { modifier in
            //         Toggle(isOn: Binding(
            //             get: { viewModel.modifiers.contains(modifier) },
            //             set: { isOn in
            //                 if isOn {
            //                     viewModel.modifiers.insert(modifier)
            //                 } else {
            //                     viewModel.modifiers.remove(modifier)
            //                 }
            //             }
            //         )) {
            //             Text(String(describing: modifier))
            //         }
            //     }
            // }
//            Button("Apply Shortcut") {
//                viewModel.setupHotKey()
//            }
        }
        .padding()
    }
} 
