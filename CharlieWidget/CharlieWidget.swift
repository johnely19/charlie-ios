import WidgetKit
import SwiftUI

// MARK: - Shared data model for widgets

struct CharlieWidgetEntry: TimelineEntry {
    let date: Date
    let contextLabel: String
    let contextEmoji: String
    let savedCount: Int
    let unreviewedCount: Int
    let topPlaces: [String]          // up to 3 place names
    let daysUntilTrip: Int?          // nil if no upcoming trip date
    let nextPlaceName: String?
    let nextPlaceType: String?
}

// MARK: - Timeline Provider

struct CharlieWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> CharlieWidgetEntry {
        CharlieWidgetEntry(
            date: Date(),
            contextLabel: "NYC Trip",
            contextEmoji: "🗽",
            savedCount: 12,
            unreviewedCount: 8,
            topPlaces: ["Via Carota", "Cafe Mogador", "Roberta's"],
            daysUntilTrip: 4,
            nextPlaceName: "Via Carota",
            nextPlaceType: "restaurant"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (CharlieWidgetEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in timeline: Context, completion: @escaping (Timeline<CharlieWidgetEntry>) -> Void) {
        // Load from UserDefaults app group
        let entry = loadEntry()
        let refresh = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(refresh)))
    }

    private func loadEntry() -> CharlieWidgetEntry {
        let defaults = UserDefaults(suiteName: "group.com.charlie.travel")
        let label = defaults?.string(forKey: "widget.contextLabel") ?? "Charlie"
        let emoji = defaults?.string(forKey: "widget.contextEmoji") ?? "✈️"
        let saved = defaults?.integer(forKey: "widget.savedCount") ?? 0
        let unreviewed = defaults?.integer(forKey: "widget.unreviewedCount") ?? 0
        let places = defaults?.stringArray(forKey: "widget.topPlaces") ?? []
        let days = defaults?.object(forKey: "widget.daysUntilTrip") as? Int
        let nextName = defaults?.string(forKey: "widget.nextPlaceName")
        let nextType = defaults?.string(forKey: "widget.nextPlaceType")

        return CharlieWidgetEntry(
            date: Date(),
            contextLabel: label,
            contextEmoji: emoji,
            savedCount: saved,
            unreviewedCount: unreviewed,
            topPlaces: places,
            daysUntilTrip: days,
            nextPlaceName: nextName,
            nextPlaceType: nextType
        )
    }
}

// MARK: - Small Widget: Next saved place

struct NextPlaceWidgetView: View {
    let entry: CharlieWidgetEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .accessoryCircular:
            AccessoryCircularView(entry: entry)
        case .accessoryRectangular:
            AccessoryRectangularView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

struct SmallWidgetView: View {
    let entry: CharlieWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(entry.contextEmoji)
                    .font(.title2)
                Spacer()
                Image(systemName: "mappin.circle.fill")
                    .foregroundStyle(.blue)
            }
            Spacer()
            if let place = entry.nextPlaceName {
                Text(place)
                    .font(.headline)
                    .lineLimit(2)
            } else {
                Text("No saved places")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Text(entry.contextLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .containerBackground(.background, for: .widget)
    }
}

struct MediumWidgetView: View {
    let entry: CharlieWidgetEntry

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(entry.contextEmoji).font(.title)
                    Text(entry.contextLabel)
                        .font(.headline)
                        .lineLimit(1)
                }
                if let days = entry.daysUntilTrip {
                    Text("\(days) days away")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 12) {
                    VStack {
                        Text("\(entry.savedCount)")
                            .font(.title2.bold())
                        Text("saved")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    VStack {
                        Text("\(entry.unreviewedCount)")
                            .font(.title2.bold())
                        Text("to review")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Divider()
            VStack(alignment: .leading, spacing: 4) {
                Text("Top picks")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                ForEach(entry.topPlaces.prefix(3), id: \.self) { place in
                    Text("• \(place)")
                        .font(.caption)
                        .lineLimit(1)
                }
            }
        }
        .padding()
        .containerBackground(.background, for: .widget)
    }
}

struct AccessoryCircularView: View {
    let entry: CharlieWidgetEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 0) {
                Text(entry.contextEmoji)
                    .font(.title3)
                Text("\(entry.unreviewedCount)")
                    .font(.caption.bold())
            }
        }
        .containerBackground(.background, for: .widget)
    }
}

struct AccessoryRectangularView: View {
    let entry: CharlieWidgetEntry

    var body: some View {
        HStack {
            Text(entry.contextEmoji)
            VStack(alignment: .leading) {
                Text(entry.contextLabel)
                    .font(.caption.bold())
                    .lineLimit(1)
                Text("\(entry.unreviewedCount) to discover")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .containerBackground(.background, for: .widget)
    }
}

// MARK: - Widget Bundle

@main
struct CharlieWidgetBundle: WidgetBundle {
    var body: some Widget {
        CharlieNextPlaceWidget()
    }
}

struct CharlieNextPlaceWidget: Widget {
    let kind: String = "CharlieNextPlace"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CharlieWidgetProvider()) { entry in
            NextPlaceWidgetView(entry: entry)
        }
        .configurationDisplayName("Charlie")
        .description("Your saved places and trip summary from Charlie.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
    }
}