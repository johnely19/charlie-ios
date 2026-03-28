import SwiftUI

struct CompanionView: View {
    let context: Context
    @Environment(DiscoveryStore.self) var store
    @Environment(\.dismiss) var dismiss

    @State private var inviteCode: String? = nil
    @State private var isGenerating = false
    @State private var copied = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text(context.emoji)
                            .font(.system(size: 56))
                        Text("Share \(context.label)")
                            .font(.title2.bold())
                        Text("Invite a travel companion to see and save places together.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top)

                    // Generate invite section
                    VStack(spacing: 12) {
                        if let code = inviteCode {
                            VStack(spacing: 8) {
                                Text("Share this link:")
                                    .font(.subheadline.weight(.semibold))

                                let shareURL = "https://charlie.travel/join/\(code)"
                                HStack {
                                    Text(shareURL)
                                        .font(.caption.monospaced())
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                    Spacer()
                                    Button {
                                        UIPasteboard.general.string = shareURL
                                        copied = true
                                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copied = false }
                                    } label: {
                                        Image(systemName: copied ? "checkmark.circle.fill" : "doc.on.doc")
                                            .foregroundStyle(copied ? .green : .blue)
                                    }
                                }
                                .padding(12)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(10)

                                ShareLink(item: URL(string: shareURL)!, message: Text("Join my \(context.label) trip on Charlie 🗺️")) {
                                    Label("Share Invite", systemImage: "square.and.arrow.up")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue)
                                        .foregroundStyle(.white)
                                        .cornerRadius(12)
                                }
                            }
                        } else {
                            Button {
                                Task { await generateInvite() }
                            } label: {
                                Group {
                                    if isGenerating {
                                        ProgressView().tint(.white)
                                    } else {
                                        Label("Generate Invite Link", systemImage: "person.badge.plus")
                                            .font(.headline)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundStyle(.white)
                                .cornerRadius(12)
                            }
                            .disabled(isGenerating)
                        }
                    }
                    .padding(.horizontal)

                    // How it works section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("How it works")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach([
                            ("1", "person.badge.plus", "Share the invite link"),
                            ("2", "iphone", "They install Charlie and join"),
                            ("3", "bookmark.fill", "Both of you save and review places"),
                            ("4", "list.star", "Your saves merge into a shared shortlist")
                        ], id: \.0) { step, icon, desc in
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle().fill(Color.blue.opacity(0.1)).frame(width: 36, height: 36)
                                    Image(systemName: icon).foregroundStyle(.blue).font(.subheadline)
                                }
                                Text(desc).font(.subheadline)
                                Spacer()
                            }
                            .padding(.horizontal)
                        }
                    }

                    Spacer(minLength: 40)
                }
            }
            .navigationTitle("Companion Mode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    func generateInvite() async {
        isGenerating = true
        // For now generate a local code — real backend endpoint comes later
        let code = "\(context.key)-\(String(Int.random(in: 100000...999999)))"
        // Store as "pending" in UserDefaults until backend is ready
        UserDefaults.standard.set(code, forKey: "companion.invite.\(context.key)")
        UserDefaults.standard.set(true, forKey: "shared.\(context.key)")
        try? await Task.sleep(nanoseconds: 500_000_000) // brief loading feel
        inviteCode = code
        isGenerating = false
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}