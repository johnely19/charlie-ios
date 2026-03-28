import SwiftUI

struct FlightCardView: View {
    let flight: FlightInfo
    @State private var isExpanded: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    if let flightNum = flight.flight {
                        Text(flightNum)
                            .font(.system(.subheadline, design: .monospaced))
                            .fontWeight(.semibold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.systemGray5))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }

                    Spacer()

                    if let from = flight.from, let to = flight.to {
                        HStack(spacing: 4) {
                            Text(from)
                                .font(.subheadline.weight(.medium))
                            Image(systemName: "arrow.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(to)
                                .font(.subheadline.weight(.medium))
                        }
                    }

                    Spacer()

                    if let departs = flight.departs {
                        Text(departs)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider()
                VStack(alignment: .leading, spacing: 4) {
                    if let from = flight.from {
                        HStack {
                            Text("From:")
                                .foregroundStyle(.secondary)
                            Text(from).fontWeight(.medium)
                        }
                    }
                    if let to = flight.to {
                        HStack {
                            Text("To:")
                                .foregroundStyle(.secondary)
                            Text(to).fontWeight(.medium)
                        }
                    }
                    if let departs = flight.departs {
                        HStack {
                            Text("Departs:")
                                .foregroundStyle(.secondary)
                            Text(departs)
                        }
                    }
                    if let arrives = flight.arrives {
                        HStack {
                            Text("Arrives:")
                                .foregroundStyle(.secondary)
                            Text(arrives)
                        }
                    }
                }
                .font(.subheadline)
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    VStack {
        FlightCardView(flight: FlightInfo(
            flight: "UA 234",
            departs: "2:30 PM",
            arrives: "5:45 PM",
            from: "EWR",
            to: "LAX"
        ))
    }
    .padding()
}