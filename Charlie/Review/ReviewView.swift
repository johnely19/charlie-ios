import SwiftUI

struct ReviewView: View {
    @Environment(DiscoveryStore.self) var store
    @State private var selectedTab: TriageTab = .unreviewed

    enum TriageTab: String, CaseIterable {
        case unreviewed = "Needs Review"
        case saved = "Saved"
        case dismissed = "Dismissed"
    }

    var discoveriesForTab: [Discovery] {
        guard let ctx = store.activeContext else { return [] }
        let key = ctx.key
        return store.discoveries.filter { d in
            guard d.contextKey == key else { return false }
            let state = store.triageStore.state(for: d.id, in: key)
            switch selectedTab {
            case .unreviewed: return state == .unreviewed || state == .resurfaced
            case .saved: return state == .saved
            case .dismissed: return state == .dismissed
            }
        }
    }

    // Group by city/neighbourhood (use city field as neighbourhood proxy)
    var groupedDiscoveries: [(String, [Discovery])] {
        let grouped = Dictionary(grouping: discoveriesForTab) { d in
            d.city.isEmpty ? "Unknown" : d.city
        }
        return grouped.sorted { $0.key < $1.key }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Tab", selection: $selectedTab) {
                    ForEach(TriageTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)

                if discoveriesForTab.isEmpty {
                    ContentUnavailableView(
                        selectedTab == .unreviewed ? "All caught up!" : "Nothing here yet",
                        systemImage: selectedTab == .saved ? "bookmark.fill" : "checkmark.circle",
                        description: Text(selectedTab == .unreviewed ? "No places to review for this context." : "")
                    )
                } else {
                    List {
                        ForEach(groupedDiscoveries, id: \.0) { neighbourhood, places in
                            Section(neighbourhood) {
                                ForEach(places) { discovery in
                                    ReviewRow(discovery: discovery)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle(store.activeContext?.label ?? "Review")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Text("\(discoveriesForTab.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct ReviewRow: View {
    let discovery: Discovery
    @Environment(DiscoveryStore.self) var store
    @State private var showDetail = false

    var triageState: TriageState {
        store.triageStore.state(for: discovery.id, in: discovery.contextKey)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Type icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(typeColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: typeIcon)
                    .foregroundStyle(typeColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(discovery.name)
                    .font(.subheadline.weight(.semibold))
                HStack(spacing: 4) {
                    TypeBadge(type: discovery.type)
                    if let rating = discovery.rating {
                        StarRatingView(rating: rating)
                    }
                }
            }

            Spacer()

            // Quick triage buttons
            HStack(spacing: 8) {
                Button {
                    Task { await store.triage(discovery: discovery, state: .saved) }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.green)
                        .font(.title3)
                }
                .buttonStyle(.borderless)

                Button {
                    Task { await store.triage(discovery: discovery, state: .dismissed) }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(.orange)
                        .font(.title3)
                }
                .buttonStyle(.borderless)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { showDetail = true }
        .sheet(isPresented: $showDetail) {
            PlaceBottomSheet(discovery: discovery)
                .environment(store)
                .presentationDetents([.height(280), .medium, .large])
        }
    }

    var typeColor: Color {
        switch discovery.type {
        case .restaurant, .bar, .cafe: return .orange
        case .gallery, .museum, .theatre: return .blue
        case .accommodation, .hotel: return .purple
        default: return .gray
        }
    }

    var typeIcon: String {
        switch discovery.type {
        case .restaurant: return "fork.knife"
        case .bar: return "wineglass"
        case .cafe: return "cup.and.saucer"
        case .gallery, .museum: return "building.columns"
        case .theatre, .musicVenue: return "music.note"
        case .accommodation, .hotel: return "house"
        default: return "mappin"
        }
    }
}

#Preview {
    ReviewView()
        .environment(DiscoveryStore())
}