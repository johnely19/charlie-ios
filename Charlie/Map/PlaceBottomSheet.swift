import SwiftUI
import UIKit
import MapKit
import CoreLocation

struct PlaceBottomSheet: View {
    let discovery: Discovery
    @Environment(DiscoveryStore.self) var store
    @Environment(\.dismiss) var dismiss
    @State private var currentDetent: PresentationDetent = .height(280)

    var body: some View {
        if currentDetent == .large {
            NavigationStack {
                PlaceCardDetailView(discovery: discovery)
            }
        } else {
            collapsedSheetContent
        }
    }

    @ViewBuilder
    private var collapsedSheetContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Hero image (120pt tall, full width)
                AsyncImage(url: discovery.heroImageURL) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    TypeGradientView(type: discovery.type)
                }
                .frame(maxWidth: .infinity)
                .frame(height: currentDetent == .height(280) ? 120 : 200)
                .clipped()
                .animation(.easeInOut, value: currentDetent)

                // Name + vitals block
                VStack(alignment: .leading, spacing: 6) {
                    Text(discovery.name)
                        .font(.headline)
                    HStack(spacing: 8) {
                        TypeBadge(type: discovery.type)
                        if let rating = discovery.rating {
                            StarRatingView(rating: rating)
                        }
                    }
                    if let address = discovery.address {
                        Label(address, systemImage: "mappin")
                            .font(.caption)
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
                    Button("Full details") {
                        currentDetent = .large
                    }
                    .buttonStyle(.borderless)
                    .font(.subheadline)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)

                // Extended content (medium + large detents)
                if currentDetent != .height(280) {
                    Divider()

                    if let summary = discovery.summary {
                        Text(summary)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .padding()
                    }
                }
            }
        }
        .presentationDetents([.height(280), .medium, .large], selection: $currentDetent)
        .presentationDragIndicator(.visible)
        .presentationBackgroundInteraction(.enabled(upThrough: .medium))
    }
}

// Type color gradient fallback for missing hero images
struct TypeGradientView: View {
    let type: DiscoveryType
    @Environment(\.colorScheme) var colorScheme

    var colors: [Color] {
        let opacity: Double = colorScheme == .dark ? 0.5 : 0.7
        switch type {
        case .restaurant, .bar, .cafe: return [.orange.opacity(opacity), .orange.opacity(opacity * 0.4)]
        case .gallery, .museum, .theatre, .musicVenue: return [.blue.opacity(opacity), .blue.opacity(opacity * 0.4)]
        case .accommodation, .hotel: return [.purple.opacity(opacity), .purple.opacity(opacity * 0.4)]
        default: return [.gray.opacity(opacity), .gray.opacity(opacity * 0.4)]
        }
    }

    var body: some View {
        LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// Type badge chip
struct TypeBadge: View {
    let type: DiscoveryType

    var label: String { type.rawValue.capitalized }

    var color: Color {
        switch type {
        case .restaurant, .bar, .cafe: return .orange
        case .gallery, .museum, .theatre: return .blue
        default: return .gray
        }
    }

    var body: some View {
        Text(label)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .clipShape(Capsule())
    }
}

// Star rating display
struct StarRatingView: View {
    let rating: Double

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "star.fill")
                .foregroundColor(.yellow)
                .font(.caption)
            Text(String(format: "%.1f", rating))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// Triage action button
struct TriageButton: View {
    let label: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                Text(label)
            }
            .font(.subheadline.weight(.semibold))
            .foregroundColor(color)
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 10))
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
        summary: "A great place with amazing food",
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
