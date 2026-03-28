import SwiftUI

struct ContextManagementView: View {
    @Environment(DiscoveryStore.self) var store
    @Environment(\.dismiss) var dismiss
    @State private var showCreateSheet = false

    var body: some View {
        NavigationStack {
            List {
                Section("Active Contexts") {
                    ForEach(store.contexts.filter { $0.active }) { ctx in
                        ContextRow(context: ctx)
                    }
                }

                Section("Archived") {
                    ForEach(store.contexts.filter { !$0.active }) { ctx in
                        ContextRow(context: ctx)
                            .opacity(0.5)
                    }
                }
            }
            .navigationTitle("Your Trips")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showCreateSheet = true } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showCreateSheet) {
                CreateContextView()
                    .environment(store)
            }
        }
    }
}

struct ContextRow: View {
    let context: Context
    @Environment(DiscoveryStore.self) var store
    @State private var showEdit = false

    var body: some View {
        HStack(spacing: 12) {
            Text(context.emoji)
                .font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text(context.label)
                    .font(.subheadline.weight(.semibold))
                if let dates = context.dates {
                    Text(dates)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if context.active {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { showEdit = true }
        .sheet(isPresented: $showEdit) {
            EditContextView(context: context)
                .environment(store)
        }
    }
}

// MARK: - Create Context

struct CreateContextView: View {
    @Environment(DiscoveryStore.self) var store
    @Environment(\.dismiss) var dismiss

    @State private var step = 0
    @State private var contextType: ContextType = .trip
    @State private var label = ""
    @State private var city = ""
    @State private var dates = ""
    @State private var emoji = "✈️"
    @State private var focus: [String] = []
    @State private var isCreating = false

    let focusOptions = ["food", "architecture", "music", "art", "nightlife", "nature", "history", "shopping"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Type") {
                    Picker("Context Type", selection: $contextType) {
                        Text("✈️ Trip").tag(ContextType.trip)
                        Text("🎭 Outing").tag(ContextType.outing)
                        Text("📡 Radar").tag(ContextType.radar)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: contextType) { _, t in
                        emoji = t == .trip ? "✈️" : t == .outing ? "🎭" : "📡"
                    }
                }

                Section("Details") {
                    HStack {
                        TextField("Emoji", text: $emoji)
                            .frame(width: 44)
                        TextField("Name (e.g. Boston August)", text: $label)
                    }
                    TextField("City", text: $city)
                    if contextType == .trip {
                        TextField("Dates (e.g. Aug 15–18)", text: $dates)
                    }
                }

                Section("Focus") {
                    FlowLayout(focusOptions) { option in
                        FocusChip(label: option, isSelected: focus.contains(option)) {
                            if focus.contains(option) {
                                focus.removeAll { $0 == option }
                            } else {
                                focus.append(option)
                            }
                        }
                    }
                }
            }
            .navigationTitle("New \(contextType.rawValue.capitalized)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Create") {
                        Task { await create() }
                    }
                    .disabled(label.isEmpty || isCreating)
                    .bold()
                }
            }
        }
    }

    func create() async {
        isCreating = true
        do {
            try await APIClient.shared.createContext(
                type: contextType,
                label: label,
                emoji: emoji,
                city: city.isEmpty ? nil : city,
                dates: dates.isEmpty ? nil : dates,
                focus: focus
            )
            await store.load()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            dismiss()
        } catch {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
        isCreating = false
    }
}

// MARK: - Edit Context

struct EditContextView: View {
    let context: Context
    @Environment(DiscoveryStore.self) var store
    @Environment(\.dismiss) var dismiss

    @State private var label: String
    @State private var dates: String
    @State private var emoji: String
    @State private var isSaving = false

    init(context: Context) {
        self.context = context
        _label = State(initialValue: context.label)
        _dates = State(initialValue: context.dates ?? "")
        _emoji = State(initialValue: context.emoji)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    HStack {
                        TextField("Emoji", text: $emoji).frame(width: 44)
                        TextField("Name", text: $label)
                    }
                    TextField("Dates", text: $dates)
                }
            }
            .navigationTitle("Edit Trip")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { Task { await save() } }
                        .bold().disabled(isSaving)
                }
            }
        }
    }

    func save() async {
        isSaving = true
        do {
            try await APIClient.shared.updateContext(
                key: context.key,
                label: label,
                emoji: emoji,
                dates: dates.isEmpty ? nil : dates
            )
            await store.load()
            dismiss()
        } catch {}
        isSaving = false
    }
}

// MARK: - Flow Layout (for focus chips)
struct FlowLayout<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    let data: Data
    let content: (Data.Element) -> Content

    init(_ data: Data, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.data = data
        self.content = content
    }

    var body: some View {
        // Simple wrapping layout using LazyVGrid
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
            ForEach(Array(data), id: \.self) { item in
                content(item)
            }
        }
    }
}

struct FocusChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(isSelected ? Color.blue : Color(.secondarySystemBackground))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.borderless)
    }
}