import SwiftUI

struct MorningBriefingView: View {
    @Environment(DiscoveryStore.self) var store
    @State private var isVisible = true
    @State private var offset: CGFloat = 0

    private let userDefaultsKey = "briefing.lastShown"

    var body: some View {
        if isVisible, let briefing = createBriefing() {
            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(briefing.greeting.displayText)
                            .font(.title2.weight(.bold))

                        Text("\(briefing.contextEmoji) \(briefing.contextLabel)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(briefing.totalCount) places")
                            .font(.headline)
                        Text("reviewed today")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()

                HStack(spacing: 12) {
                    ForEach(briefing.highlights) { highlight in
                        HighlightChip(highlight: highlight)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 12)
            }
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(radius: 8)
            .padding(.horizontal)
            .padding(.top, 8)
            .offset(y: offset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.height > 0 {
                            offset = value.translation.height
                        }
                    }
                    .onEnded { value in
                        if value.translation.height > 80 {
                            withAnimation(.spring(response: 0.3)) {
                                offset = 200
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                dismissBriefing()
                            }
                        } else {
                            withAnimation(.spring(response: 0.3)) {
                                offset = 0
                            }
                        }
                    }
            )
            .onAppear {
                checkAndShowBriefing()
            }
        }
    }

    private func createBriefing() -> Briefing? {
        guard let ctx = store.activeContext else { return nil }

        let allForCtx = store.discoveries.filter { $0.contextKey == ctx.key }
        let saved = allForCtx.filter { store.triageState(for: $0.id) == .saved }
        let unreviewed = allForCtx.filter { store.triageState(for: $0.id) == .unreviewed }
        let resurfaced = allForCtx.filter { store.triageState(for: $0.id) == .resurfaced }

        let highlights: [BriefingHighlight] = [
            BriefingHighlight(id: "new", type: .new, count: unreviewed.count, label: "New"),
            BriefingHighlight(id: "saved", type: .saved, count: saved.count, label: "Saved"),
            if resurfaced.count > 0 {
                BriefingHighlight(id: "surfacing", type: .surfacing, count: resurfaced.count, label: "Resurfacing")
            }
        ].compactMap { $0 }

        return Briefing(
            id: UUID().uuidString,
            greeting: Greeting.current,
            contextLabel: ctx.label,
            contextEmoji: ctx.emoji,
            totalCount: saved.count,
            highlights: highlights,
            timestamp: Date()
        )
    }

    private func checkAndShowBriefing() {
        guard let ctx = store.activeContext else { return }
        let key = "\(userDefaultsKey).\(ctx.key)"
        let lastShown = UserDefaults.standard.object(forKey: key) as? Date

        if let last = lastShown {
            let calendar = Calendar.current
            if calendar.isDateInToday(last) {
                isVisible = false
            }
        }
    }

    private func dismissBriefing() {
        guard let ctx = store.activeContext else { return }
        let key = "\(userDefaultsKey).\(ctx.key)"
        UserDefaults.standard.set(Date(), forKey: key)
        isVisible = false
    }
}

struct HighlightChip: View {
    let highlight: BriefingHighlight

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.caption)
            Text("\(highlight.count)")
                .font(.subheadline.weight(.semibold))
            Text(highlight.label)
                .font(.caption)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(chipColor.opacity(0.15))
        .foregroundColor(chipColor)
        .clipShape(Capsule())
    }

    private var iconName: String {
        switch highlight.type {
        case .new: return "sparkles"
        case .saved: return "bookmark.fill"
        case .surfacing: return "arrow.up.circle"
        case .reviewed: return "checkmark.circle"
        }
    }

    private var chipColor: Color {
        switch highlight.type {
        case .new: return .purple
        case .saved: return .green
        case .surfacing: return .orange
        case .reviewed: return .blue
        }
    }
}