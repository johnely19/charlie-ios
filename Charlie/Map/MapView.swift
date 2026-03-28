import SwiftUI
import MapKit

struct MapView: View {
    @Environment(DiscoveryStore.self) var store
    @State private var selectedDiscovery: Discovery?
    @State private var showChat = false
    @State private var showTrip = false
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 43.6532, longitude: -79.3832),
            latitudinalMeters: 15000, longitudinalMeters: 15000
        )
    )

    var body: some View {
        ZStack(alignment: .top) {
            Map(position: $position, selection: $selectedDiscovery) {
                if let base = store.activeContext?.accommodationCoordinate {
                    Marker("Home base", systemImage: "house.fill", coordinate: base)
                        .tint(.purple)
                }

                ForEach(store.filteredDiscoveries) { discovery in
                    if let coord = discovery.coordinate {
                        Annotation(discovery.name, coordinate: coord) {
                            PlacePinView(
                                discovery: discovery,
                                triageState: store.triageState(for: discovery.id),
                                isSelected: selectedDiscovery?.id == discovery.id
                            )
                        }
                        .tag(discovery as Discovery?)
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapScaleView()
            }
            .ignoresSafeArea(edges: .bottom)
            .onChange(of: store.activeContext) { _, newCtx in
                if let region = newCtx?.mapRegion {
                    withAnimation(.easeInOut(duration: 1.0)) {
                        position = .region(region)
                    }
                }
            }

            ContextSwitcher(store: store, onChatTap: { showChat = true }, onTripTap: { showTrip = true })
        }
        .sheet(item: $selectedDiscovery) { discovery in
            PlaceBottomSheet(discovery: discovery)
                .presentationDetents([.height(280), .medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showChat) {
            ChatView().environment(store)
        }
        .sheet(isPresented: $showTrip) {
            TripView().environment(store)
        }
        .task {
            if store.discoveries.isEmpty {
                await store.load()
            }
        }
    }
}

#Preview {
    MapView()
        .environment(DiscoveryStore())
}