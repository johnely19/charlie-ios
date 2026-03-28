import SwiftUI
import MapKit

struct MapView: View {
    @Environment(DiscoveryStore.self) var store
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedDiscovery: Discovery?
    @State private var showChat = false
    @State private var showTrip = false
    @State private var showContextManagement = false
    @State private var routeManager = RouteOverlayManager()
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

                if routeManager.isVisible {
                    ForEach(Array(routeManager.routes.enumerated()), id: \.offset) { _, route in
                        MapPolyline(route.polyline)
                            .stroke(.blue.opacity(0.5), style: StrokeStyle(lineWidth: 3, dash: [8, 4]))
                    }
                }
            }
            .mapStyle(colorScheme == .dark
                ? .standard(elevation: .realistic, colorScheme: .dark)
                : .standard(elevation: .realistic)
            )
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapScaleView()
            }
            .ignoresSafeArea(edges: .bottom)
            .onChange(of: store.activeContext) { _, newCtx in
                routeManager.clear()
                if let region = newCtx?.mapRegion {
                    withAnimation(.easeInOut(duration: 1.0)) {
                        position = .region(region)
                    }
                }
            }

            ContextSwitcher(store: store, onChatTap: { showChat = true }, onTripTap: { showTrip = true }, onManageTap: { showContextManagement = true })

            VStack {
                Spacer()
                HStack {
                    if store.hasEnoughSavedForRoute {
                        Button {
                            Task { await toggleRoute() }
                        } label: {
                            HStack(spacing: 6) {
                                if routeManager.isLoading {
                                    ProgressView().scaleEffect(0.8)
                                } else {
                                    Image(systemName: routeManager.isVisible ? "figure.walk.circle.fill" : "figure.walk.circle")
                                        .font(.title2)
                                }
                                if !routeManager.isVisible && !routeManager.isLoading {
                                    Text("Route")
                                        .font(.subheadline.weight(.semibold))
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(.ultraThinMaterial)
                            .cornerRadius(20)
                            .shadow(radius: 4)
                        }
                        .padding(.leading, 16)
                        .padding(.bottom, 100)
                    }
                    Spacer()
                }
            }
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
        .sheet(isPresented: $showContextManagement) {
            ContextManagementView()
                .environment(store)
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

func toggleRoute() async {
    if routeManager.isVisible {
        routeManager.clear()
        return
    }
    guard let origin = store.activeContext?.accommodationCoordinate else { return }
    let destinations = store.savedDiscoveriesForRoute.compactMap { $0.coordinate }
    guard destinations.count >= 3 else { return }
    routeManager.isVisible = true
    await routeManager.buildRoutes(from: origin, to: destinations)
}