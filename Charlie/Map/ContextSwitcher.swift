import SwiftUI

struct ContextSwitcher: View {
    @Bindable var store: DiscoveryStore
    var onChatTap: (() -> Void)?

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

            if let onChatTap = onChatTap {
                Button(action: onChatTap) {
                    Image(systemName: "bubble.left.and.bubble.right")
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }
}