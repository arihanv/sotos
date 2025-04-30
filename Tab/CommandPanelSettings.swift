import SwiftUI
import HotKey

struct CommandPanelSettings: View {
    @ObservedObject var viewModel: CommandPanelViewModel

    let availableKeys: [String] = Array("abcdefghijklmnopqrstuvwxyz").map { String($0) }
    let availableModifiers: [NSEvent.ModifierFlags] = [.command, .option, .control, .shift]

    @State private var selectedKey: String = "l"
    @State private var selectedModifiers: [NSEvent.ModifierFlags] = [.command]

    var body: some View {
        Form {
            Picker("Key", selection: $selectedKey) {
                ForEach(availableKeys, id: \.self) { key in
                    Text(key).tag(key)
                }
            }
            HStack {
                Text("Modifiers")
                ForEach(availableModifiers, id: \.rawValue) { modifier in
                    Toggle(isOn: Binding(
                        get: { selectedModifiers.contains(modifier) },
                        set: { isOn in
                            if isOn {
                                if !selectedModifiers.contains(modifier) {
                                    selectedModifiers.append(modifier)
                                }
                            } else {
                                selectedModifiers.removeAll { $0 == modifier }
                            }
                        }
                    )) {
                        Text(String(describing: modifier))
                    }
                }
            }
            Button("Apply Shortcut") {
                viewModel.updateHotKey(key: selectedKey, modifiers: selectedModifiers)
            }
        }
        .padding()
        .onAppear {
            // Optionally, initialize selectedKey and selectedModifiers from viewModel if you store them
        }
    }
} 
