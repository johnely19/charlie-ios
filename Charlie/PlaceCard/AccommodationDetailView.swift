import SwiftUI
import MapKit

struct AccommodationDetailView: View {
    let discovery: Discovery
    @Environment(DiscoveryStore.self) var store
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // Hero
                HeroSection(discovery: discovery)

                // Name + vitals
                VStack(alignment: .leading, spacing: 8) {
                    Text(discovery.name)
                        .font(.title2.bold())
                    if let address = discovery.address {
                        Label(address, systemImage: "mappin")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()

                Divider()

                // Accommodation vitals grid
                AccommodationVitalsGrid(discovery: discovery)

                Divider()

                // Triage
                HStack(spacing: 12) {
                    TriageButton(label: "Save", icon: "plus.circle.fill", color: .green) {
                        Task { await store.triage(discovery: discovery, state: .saved); dismiss() }
                    }
                    TriageButton(label: "Skip", icon: "minus.circle.fill", color: .orange) {
                        Task { await store.triage(discovery: discovery, state: .dismissed); dismiss() }
                    }
                }
                .padding()

                // Swimming section (if swim quality exists)
                if let swim = discovery.swimQuality {
                    SwimmingSection(swimQuality: swim)
                }

                // Amenities grid
                if let amenities = discovery.amenities, !amenities.isEmpty {
                    AmenitiesGrid(amenities: amenities)
                }

                // July availability
                if let julyAvail = discovery.julyAvailable {
                    JulyAvailabilityRow(available: julyAvail)
                }

                // Drive time
                if let drive = discovery.driveFromToronto {
                    DriveTimeRow(duration: drive)
                }

                // Listing CTA
                if let urlString = discovery.listingUrl, let url = URL(string: urlString) {
                    Link(destination: url) {
                        Label("View Listing", systemImage: "safari")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }
                    .padding(.vertical, 8)
                }

                // Map location
                if let coord = discovery.coordinate {
                    AccommodationMapSection(discovery: discovery, coordinate: coord)
                }
            }
        }
        .navigationTitle(discovery.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AccommodationVitalsGrid: View {
    let discovery: Discovery

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            if let price = discovery.pricePerWeek {
                VitalCell(icon: "dollarsign.circle", label: "Per Week", value: String(format: "$%.0f", price))
            }
            if let beds = discovery.bedrooms {
                VitalCell(icon: "bed.double", label: "Bedrooms", value: "\(beds)")
            }
            if let score = discovery.matchScore {
                VitalCell(icon: "star.fill", label: "Match Score", value: String(format: "%.0f%%", score * 100))
            }
            if let drive = discovery.driveFromToronto {
                VitalCell(icon: "car", label: "From Toronto", value: drive)
            }
        }
        .padding()
    }
}

struct VitalCell: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 1) {
                Text(label).font(.caption).foregroundStyle(.secondary)
                Text(value).font(.subheadline.bold())
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}

struct SwimmingSection: View {
    let swimQuality: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Swimming", systemImage: "figure.open.water.swim")
                .font(.headline)
            Text(swimQuality)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

struct AmenitiesGrid: View {
    let amenities: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Amenities", systemImage: "list.bullet.circle")
                .font(.headline)
                .padding(.horizontal)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(amenities, id: \.self) { amenity in
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                        Text(amenity)
                            .font(.caption)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct JulyAvailabilityRow: View {
    let available: Bool

    var body: some View {
        HStack {
            Image(systemName: available ? "calendar.badge.checkmark" : "calendar.badge.minus")
                .foregroundStyle(available ? .green : .orange)
            Text(available ? "Available in July" : "Not available in July")
                .font(.subheadline)
            Spacer()
            Text(available ? "✓" : "✗")
                .foregroundStyle(available ? .green : .orange)
                .font(.headline)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

struct DriveTimeRow: View {
    let duration: String

    var body: some View {
        HStack {
            Image(systemName: "car.fill").foregroundStyle(.blue)
            Text("Drive from Toronto")
            Spacer()
            Text(duration).font(.subheadline.bold())
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

struct AccommodationMapSection: View {
    let discovery: Discovery
    let coordinate: CLLocationCoordinate2D
    @State private var position: MapCameraPosition

    init(discovery: Discovery, coordinate: CLLocationCoordinate2D) {
        self.discovery = discovery
        self.coordinate = coordinate
        _position = State(initialValue: .region(MKCoordinateRegion(
            center: coordinate, latitudinalMeters: 5000, longitudinalMeters: 5000
        )))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Location", systemImage: "map").font(.headline).padding(.horizontal)
            Map(position: $position) {
                Marker(discovery.name, systemImage: "house.fill", coordinate: coordinate)
                    .tint(.purple)
            }
            .frame(height: 200)
            .cornerRadius(12)
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    NavigationStack {
        AccommodationDetailView(discovery: Discovery(
            id: "1",
            name: "Lakefront Cottage",
            type: .accommodation,
            contextKey: "cottages",
            placeId: nil,
            heroImage: nil,
            address: "123 Lakeview Rd, Muskoka",
            city: "Muskoka",
            rating: nil,
            lat: 45.0,
            lng: -79.0,
            summary: nil,
            source: nil,
            pricePerWeek: 2500,
            bedrooms: 3,
            swimQuality: "Lake access, sandy bottom, shallow for kids",
            amenities: ["WiFi", "Fire Pit", "Kayaks", "Dock", "AC"],
            julyAvailable: true,
            listingUrl: "https://example.com/listing",
            matchScore: 0.92,
            driveFromToronto: "2.5h"
        ))
    }
    .environment(DiscoveryStore())
}
