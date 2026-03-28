import SwiftUI

struct ContextSwitcher: View {
    @Bindable var store: DiscoveryStore

    var body: some View {
        HStack {
            Image(systemName: "map")
                .foregroundColor(.primary)

            Picker("Context", selection: $store.activeContext) {
                ForEach(store.contexts) { ctx in
                    Text(ctx.emoji + " " + ctx.label)
                        .tag(Optional(ctx))
                }
            }
            .pickerStyle(.menu)

            Spacer()

            Button(action: {}) {
                Image(systemName: "bubble.left")
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }
}