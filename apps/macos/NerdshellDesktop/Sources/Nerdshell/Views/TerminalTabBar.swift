import SwiftUI

struct TerminalTabBar: View {
    let tabs: [TerminalTab]
    @Binding var selection: TerminalTab.ID?
    let onAdd: () -> Void
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(tabs) { tab in
                        Button {
                            selection = tab.id
                        } label: {
                            Label(tab.title, systemImage: "terminal")
                                .lineLimit(1)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 6)
                                .background(
                                    selection == tab.id ? Color.accentColor.opacity(0.18) : .clear,
                                    in: RoundedRectangle(cornerRadius: 6)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Button(action: onAdd) {
                Image(systemName: "plus")
            }
            .buttonStyle(.borderless)
            .help("New Tab")

            Button(action: onClose) {
                Image(systemName: "xmark")
            }
            .buttonStyle(.borderless)
            .help("Close Tab")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(.bar)
    }
}
