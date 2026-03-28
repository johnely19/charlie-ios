import SwiftUI

struct ContextSwitcher: View {
    @Binding var selectedContext: String?

    var body: some View {
        // TODO: Implement context switching UI
        HStack {
            Text("Context")
                .font(.headline)
            Spacer()
        }
        .padding()
    }
}

#Preview {
    ContextSwitcher(selectedContext: .constant(nil))
}
