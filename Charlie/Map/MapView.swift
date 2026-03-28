import SwiftUI
import MapKit

struct MapView: View {
    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
        Map(position: $cameraPosition) {
            // TODO: Add discovery pins
        }
        .mapStyle(.standard)
    }
}

#Preview {
    MapView()
}
