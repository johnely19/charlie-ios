import SwiftUI

struct PlaceBottomSheet: View {
    let placeId: String

    var body: some View {
        // TODO: Implement place card bottom sheet
        VStack {
            Text("Place Details")
                .font(.headline)
        }
        .padding()
    }
}

#Preview {
    PlaceBottomSheet(placeId: "sample")
}
