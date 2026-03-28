import SwiftUI
import MapKit

struct PlaceSearchView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(DiscoveryStore.self) var store
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var isSearching = false
    @State private var addedIds: Set<String> = []

    var body: some View {
        NavigationStack {
            Group {
                if searchText.isEmpty {
                    ContentUnavailableView(
                        "Search for a place",
                        systemImage: "magnifyingglass",
                        description: Text("Try 'Neptune Oyster Boston' or 'Via Carota NYC'")
                    )
                } else if isSearching {
                    ProgressView("Searching…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if searchResults.isEmpty {
                    ContentUnavailableView("No results", systemImage: "mappin.slash")
                } else {
                    List(searchResults, id: \.self) { item in
                        PlaceSearchRow(
                            item: item,
                            isAdded: addedIds.contains(item.name ?? "")
                        ) {
                            addToCompass(item)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .searchable(text: $searchText,
                        placement: .navigationBarDrawer(displayMode: .always),
                        prompt: "Search places…")
            .onChange(of: searchText) { _, newValue in
                guard !newValue.isEmpty else { searchResults = []; return }
                Task { await searchPlaces(query: newValue) }
            }
            .navigationTitle("Add a Place")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
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

        do {
            let response = try await MKLocalSearch(request: request).start()
            searchResults = response.mapItems
        } catch {
            searchResults = []
        }
    }

    private func addToCompass(_ item: MKMapItem) {
        // CLLocationCoordinate2D is a struct, always non-optional on MKPlacemark
        let coord = item.placemark.coordinate
        let name = item.name ?? "Unknown Place"
        addedIds.insert(name)

        let discovery = Discovery(
            id: UUID().uuidString,
            name: name,
            type: inferType(from: item),
            contextKey: store.activeContext?.key ?? "",
            placeId: nil,
            heroImage: nil,
            address: item.placemark.title,
            city: item.placemark.locality ?? store.activeContext?.city ?? "",
            rating: nil,
            lat: coord.latitude,
            lng: coord.longitude,
            summary: nil,
            source: "search:manual",
            pricePerWeek: nil,
            bedrooms: nil,
            swimQuality: nil,
            amenities: nil,
            julyAvailable: nil,
            listingUrl: nil,
            matchScore: nil,
            driveFromToronto: nil
        )

        Task {
            await store.triage(discovery: discovery, state: .unreviewed)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    private func inferType(from item: MKMapItem) -> DiscoveryType {
        switch item.pointOfInterestCategory {
        case .restaurant, .bakery:         return .restaurant
        case .cafe:                        return .cafe
        case .nightlife, .winery, .brewery: return .bar
        case .museum:                      return .museum
        case .theater:                     return .theatre
        case .hotel:                       return .hotel
        case .park:                        return .park
        case .store:                       return .shop
        default:                           return .restaurant
        }
    }
}

struct PlaceSearchRow: View {
    let item: MKMapItem
    let isAdded: Bool
    let onAdd: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: "mappin.circle.fill")
                    .foregroundStyle(.blue)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name ?? "Unknown")
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                if let address = item.placemark.title {
                    Text(address)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Button(action: onAdd) {
                Image(systemName: isAdded ? "checkmark.circle.fill" : "plus.circle.fill")
                    .foregroundStyle(isAdded ? .green : .blue)
                    .font(.title3)
            }
            .buttonStyle(.borderless)
            .disabled(isAdded)
        }
        .padding(.vertical, 4)
    }
}
