import Foundation

@Observable
class TriageStore {
    var states: [String: [String: TriageState]] = [:] // [contextKey: [discoveryId: state]]

    func state(for discoveryId: String, in contextKey: String) -> TriageState {
        return states[contextKey]?[discoveryId] ?? .unreviewed
    }

    func setState(_ state: TriageState, for discoveryId: String, in contextKey: String) {
        if states[contextKey] == nil {
            states[contextKey] = [:]
        }
        states[contextKey]![discoveryId] = state
    }

    func loadFromServer(_ entries: [TriageEntry]) {
        for entry in entries {
            setState(entry.state, for: entry.discoveryId, in: entry.contextKey)
        }
    }
}