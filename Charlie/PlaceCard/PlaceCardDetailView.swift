import SwiftUI
import MapKit

struct PlaceCardDetailView: View {
    let discovery: Discovery
    @Environment(DiscoveryStore.self) var store
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HeroSection(discovery: discovery)

                VStack(alignment: .leading, spacing: 12) {
                    Text(discovery.name)
                        .font(.title2.bold())

                    HStack(spacing: 8) {
                        TypeBadge(type: discovery.type)
                        if let rating = discovery.rating {
                            StarRatingView(rating: rating)
                        }
                    }

                    if let address = discovery.address {
                        Label(address, systemImage: "mappin")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()

                // Triage buttons
                HStack(spacing: 12) {
                    TriageButton(label: "Save", icon: "plus.circle.fill", color: .green) {
                        Task {
                            await store.triage(discovery: discovery, state: .saved)
                            dismiss()
                        }
                    }
                    TriageButton(label: "Skip", icon: "minus.circle.fill", color: .orange) {
                        Task {
                            await store.triage(discovery: discovery, state: .dismissed)
                            dismiss()
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 8)

                Divider()
                    .padding(.vertical, 8)

                // Open in Maps button
                if discovery.coordinate != nil {
                    Button(action: openInMaps) {
                        Label("Open in Maps", systemImage: "map")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemBlue))
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }

                // Look Around button
                if let coord = discovery.coordinate {
                    LookAroundButton(coordinate: coord)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                }

                // Summary
                if let summary = discovery.summary {
                    Text(summary)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .padding()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareButton(discovery: discovery, style: .icon)
            }
        }
    }

    private func openInMaps() {
        guard let coord = discovery.coordinate else { return }
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coord))
        mapItem.name = discovery.name
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDefault])
    }
}

struct HeroSection: View {
    let discovery: Discovery

    var body: some View {
        ZStack(alignment: .bottom) {
            AsyncImage(url: discovery.heroImageURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                TypeGradientView(type: discovery.type)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 250)
            .clipped()

            LinearGradient(
                colors: [.clear, .black.opacity(0.5)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 80)
        }
    }
}

#Preview {
    NavigationStack {
        PlaceCardDetailView(discovery: Discovery(
            id: "1",
            name: "Test Place",
            type: .restaurant,
            contextKey: "test",
            placeId: nil,
            heroImage: nil,
            address: "123 Main St",
            city: "Toronto",
            rating: 4.5,
            lat: 43.6532,
            lng: -79.3832,
            summary: "A great place with amazing food and wonderful atmosphere. Perfect for a casual dinner or special occasion.",
            source: nil,
            pricePerWeek: nil,
            bedrooms: nil,
            swimQuality: nil,
            amenities: nil,
            julyAvailable: nil,
            listingUrl: nil,
            matchScore: nil,
            driveFromToronto: nil
        ))
    }
    .environment(DiscoveryStore())
}