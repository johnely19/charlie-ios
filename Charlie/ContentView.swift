import SwiftUI
import MapKit

struct ContentView: View {
    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
        Map(position: $cameraPosition) {
            Marker("Toronto", coordinate: CLLocationCoordinate2D(latitude: 43.6532, longitude: -79.3832))
        }
        .mapStyle(.standard)
        .mapControls {
            MapCompass()
            MapScaleView()
        }
    }
}

#Preview {
    ContentView()
}
