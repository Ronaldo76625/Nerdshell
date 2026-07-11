import SwiftUI

struct SettingsView: View {
    @AppStorage("terminalFontName") private var fontName = "JetBrainsMono Nerd Font Mono"
    @AppStorage("terminalFontSize") private var fontSize = 14.0
    @AppStorage("warnBeforeMultilinePaste") private var warnBeforeMultilinePaste = true

    var body: some View {
        TabView {
            Form {
                TextField("Font", text: $fontName)
                Stepper("Size: \(fontSize, specifier: "%.0f") pt", value: $fontSize, in: 9...32)
            }
            .formStyle(.grouped)
            .tabItem { Label("Appearance", systemImage: "paintbrush") }

            Form {
                Toggle("Warn before pasting multiple lines", isOn: $warnBeforeMultilinePaste)
            }
            .formStyle(.grouped)
            .tabItem { Label("Security", systemImage: "lock.shield") }
        }
        .frame(width: 520, height: 300)
        .scenePadding()
    }
}
