import SwiftUI
import MapKit

struct PlaceSearchView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(DiscoveryStore.self) var store
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var isSearching = false
    @Binding var position: MapCameraPosition

    var body: some View {
        NavigationStack {
            List {
                if isSearching {
                    HStack {
                        Spacer()
                        ProgressView("Searching...")
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                } else if searchResults.isEmpty && !searchText.isEmpty {
                    Text("No results found")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(searchResults, id: \.self) { item in
                        PlaceSearchRow(item: item) {
                            addToCompass(item)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .searchable(text: $searchText, prompt: "Search places")
            .onChange(of: searchText) { _, newValue in
                if !newValue.isEmpty {
                    Task { await searchPlaces(query: newValue) }
                } else {
                    searchResults = []
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func searchPlaces(query: String) async {
        isSearching = true
        defer { isSearching = false }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query

        if let region = store.activeContext?.mapRegion {
            request.region = region
        }

        let search = MKLocalSearch(request: request)
        do {
            let response = try await search.start()
            searchResults = response.mapItems
        } catch {
            searchResults = []
        }
    }

    func addToCompass(_ item: MKMapItem) {
        guard let coordinate = item.placemark.coordinate else { return }

        let newDiscovery = Discovery(
            id: UUID().uuidString,
            name: item.name ?? "New Place",
            type: .restaurant,
            description: item.placemark.title ?? "",
            contextKey: store.activeContext?.key ?? "",
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            createdAt: Date()
        )

        Task {
            await store.triage(discovery: newDiscovery, state: .saved)
            await MainActor.run {
                dismiss()
            }
        }

        withAnimation(.easeInOut(duration: 0.8)) {
            position = .camera(MapCamera(
                centerCoordinate: coordinate,
                distance: 1500,
                heading: 0,
                pitch: 45
            ))
        }

        HapticManager.soft()
    }
}

struct PlaceSearchRow: View {
    let item: MKMapItem
    let onAdd: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name ?? "Unknown")
                    .font(.headline)
                if let address = item.placemark.title {
                    Text(address)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Button(action: onAdd) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}