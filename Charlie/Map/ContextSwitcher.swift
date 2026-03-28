import SwiftUI

struct ContextSwitcher: View {
    @Bindable var store: DiscoveryStore
    var onChatTap: (() -> Void)?
    var onTripTap: (() -> Void)?
    var onManageTap: (() -> Void)?

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

            if let onManageTap = onManageTap {
                Button(action: onManageTap) {
                    Image(systemName: "pencil.circle")
                }
            }

            if let onTripTap = onTripTap, store.activeContext?.type == .trip {
                Button(action: onTripTap) {
                    Image(systemName: "suitcase")
                }
            }

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