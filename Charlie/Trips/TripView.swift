import SwiftUI

struct TripView: View {
    @Environment(DiscoveryStore.self) var store
    @Environment(\.dismiss) var dismiss

    @State private var showCompanion = false

    var context: Context? {
        store.activeContext
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                if let ctx = context {
                    HStack {
                        Text(ctx.emoji)
                            .font(.largeTitle)
                        VStack(alignment: .leading) {
                            Text(ctx.label)
                                .font(.title2.bold())
                            if let dates = ctx.dates {
                                Text(dates)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // Flight section
                if let travel = context?.travel {
                    SectionHeader(icon: "airplane", title: "Flights")

                    if let outbound = travel.outbound {
                        FlightCardView(flight: outbound)
                    }
                    if let returnFlight = travel.returnFlight {
                        FlightCardView(flight: returnFlight)
                    }
                }

                // Accommodation section
                if let accommodation = context?.accommodation {
                    SectionHeader(icon: "bed.double", title: "Accommodation")

                    VStack(alignment: .leading, spacing: 4) {
                        Text(accommodation.name)
                            .font(.headline)
                        if let address = accommodation.address {
                            Label(address, systemImage: "mappin")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        Text("Booked")
                            .font(.caption.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .clipShape(Capsule()),
                        alignment: .topTrailing
                    )
                }

                // Schedule section
                if let schedule = context?.schedule, !schedule.isEmpty {
                    SectionHeader(icon: "calendar", title: "Schedule")

                    ForEach(schedule, id: \.date) { day in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(day.date)
                                    .font(.subheadline.bold())
                                if let label = day.label {
                                    Text(label)
                                        .font(.caption)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color(.systemGray5))
                                        .clipShape(Capsule())
                                }
                            }
                            ForEach(day.events, id: \.self) { event in
                                Label(event, systemImage: "circle.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }

                // Anchors section
                if let anchors = context?.anchorExperiences, !anchors.isEmpty {
                    SectionHeader(icon: "star", title: "Anchor Experiences")

                    ForEach(anchors, id: \.name) { anchor in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(anchor.name)
                                    .font(.headline)
                                Text(anchor.type)
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                            if let date = anchor.date {
                                Text(date)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            if let notes = anchor.notes {
                                Text(notes)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }

                // People section
                if let people = context?.people, !people.isEmpty {
                    SectionHeader(icon: "person.2", title: "Traveling With")

                    Text(people.joined(separator: ", "))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
        }
        .navigationTitle("Trip")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showCompanion = true
                } label: {
                    Label("Companions", systemImage: context?.isShared == true ? "person.2.fill" : "person.badge.plus")
                }
                .sheet(isPresented: $showCompanion) {
                    if let ctx = context {
                        CompanionView(context: ctx).environment(store)
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}

struct SectionHeader: View {
    let icon: String
    let title: String

    var body: some View {
        Label(title, systemImage: icon)
            .font(.headline)
            .padding(.horizontal)
    }
}

#Preview {
    NavigationStack {
        TripView()
            .environment(DiscoveryStore())
    }
}