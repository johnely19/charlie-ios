import SwiftUI

struct PlaceBottomSheet: View {
    let discovery: Discovery

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text(discovery.name)
                            .font(.title2)
                            .fontWeight(.semibold)

                        HStack {
                            Text(discovery.type.rawValue.capitalized)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            if let rating = discovery.rating {
                                Text("•")
                                    .foregroundStyle(.secondary)
                                Text(String(format: "%.1f", rating))
                                    .font(.subheadline)
                            }
                        }
                    }

                    // Address
                    if let address = discovery.address {
                        HStack {
                            Image(systemName: "mappin")
                                .foregroundStyle(.secondary)
                            Text(address)
                                .font(.subheadline)
                        }
                    }

                    // Summary
                    if let summary = discovery.summary {
                        Text(summary)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }

                    // Price (for accommodations)
                    if let price = discovery.pricePerWeek {
                        Text("$\(Int(price))/week")
                            .font(.headline)
                            .foregroundStyle(.green)
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    PlaceBottomSheet(discovery: Discovery(
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
        summary: "A great place",
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