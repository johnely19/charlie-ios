import AppIntents
import SwiftUI

// MARK: - String extension (used below)
extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}

// MARK: - GetRecommendationIntent
// "Hey Siri, ask Charlie what to do"

struct GetRecommendationIntent: AppIntent {
    static var title: LocalizedStringResource = "Get a recommendation from Charlie"
    static var description = IntentDescription("Ask Charlie for a place recommendation based on your active trip or outing.")

    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        let store = await DiscoveryStore.sharedForIntents
        let contextKey = store.activeContext?.key ?? ""
        let contextLabel = store.activeContext?.label ?? "your current context"

        let saved = store.discoveries.filter { d in
            d.contextKey == contextKey && store.triageStore.state(for: d.id, in: contextKey) == .saved
        }

        let message: String
        if saved.isEmpty {
            message = "No saved places yet for \(contextLabel). Open Charlie to explore and save places."
        } else {
            let names = saved.prefix(3).map(\.name).joined(separator: ", ")
            message = "Your top saved places for \(contextLabel): \(names). Open Charlie for the full map."
        }

        return .result(dialog: IntentDialog(stringLiteral: message))
    }
}

// MARK: - CheckTripIntent
// "Hey Siri, what's my NYC trip looking like?"

struct CheckTripIntent: AppIntent {
    static var title: LocalizedStringResource = "Check my trip with Charlie"
    static var description = IntentDescription("Get a summary of your active trip — saved places, days until departure.")

    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        let store = await DiscoveryStore.sharedForIntents

        guard let ctx = store.activeContext else {
            return .result(dialog: IntentDialog("No active trip or outing. Open Charlie to set one up."))
        }

        let allForCtx = store.discoveries.filter { $0.contextKey == ctx.key }
        let saved = allForCtx.filter { store.triageStore.state(for: $0.id, in: ctx.key) == .saved }
        let pending = allForCtx.filter { store.triageStore.state(for: $0.id, in: ctx.key) == .unreviewed }

        var summary = "\(ctx.emoji) \(ctx.label)"
        if let dates = ctx.dates { summary += " — \(dates)" }
        summary += ". \(saved.count) saved, \(pending.count) to review."

        if let topSaved = saved.prefix(2).map(\.name).joined(separator: ", ").nilIfEmpty {
            summary += " Top picks: \(topSaved)."
        }

        return .result(dialog: IntentDialog(stringLiteral: summary))
    }
}

// MARK: - SavePlaceIntent
// "Hey Siri, save this to my trip"

struct SavePlaceIntent: AppIntent {
    static var title: LocalizedStringResource = "Save a place with Charlie"
    static var description = IntentDescription("Save a named place to your active Charlie context.")

    @Parameter(title: "Place Name", description: "The name of the place to save")
    var placeName: String

    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        let store = await DiscoveryStore.sharedForIntents

        guard let ctx = store.activeContext else {
            return .result(dialog: IntentDialog("No active context. Open Charlie to set up a trip first."))
        }

        if let match = store.discoveries.first(where: {
            $0.name.localizedCaseInsensitiveContains(placeName) && $0.contextKey == ctx.key
        }) {
            await store.triage(discovery: match, state: .saved)
            return .result(dialog: IntentDialog(stringLiteral: "Saved \(match.name) to \(ctx.label)."))
        }

        return .result(dialog: IntentDialog(stringLiteral: "Couldn't find \(placeName) in \(ctx.label). Open Charlie to search and save manually."))
    }
}

// MARK: - App Shortcuts (appears in Shortcuts app automatically)

struct CharlieShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GetRecommendationIntent(),
            phrases: [
                "Ask \(.applicationName) what to do",
                "Ask \(.applicationName) for a recommendation",
                "What should I do with \(.applicationName)",
                "Get a recommendation from \(.applicationName)"
            ],
            shortTitle: "Get Recommendation",
            systemImageName: "map"
        )
        AppShortcut(
            intent: CheckTripIntent(),
            phrases: [
                "Check my trip with \(.applicationName)",
                "What's my trip looking like in \(.applicationName)",
                "Trip summary from \(.applicationName)"
            ],
            shortTitle: "Check Trip",
            systemImageName: "suitcase"
        )
    }
}
