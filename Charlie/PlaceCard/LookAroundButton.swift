import SwiftUI
import MapKit

struct LookAroundButton: View {
    let coordinate: CLLocationCoordinate2D
    @State private var scene: MKLookAroundScene? = nil
    @State private var isLoading = false
    @State private var showViewer = false
    @State private var checked = false

    var body: some View {
        Group {
            if let scene {
                Button {
                    showViewer = true
                } label: {
                    Label("Look Around", systemImage: "binoculars")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                }
                .sheet(isPresented: $showViewer) {
                    LookAroundViewerSheet(scene: scene)
                }
            } else if isLoading {
                EmptyView()
            } else {
                EmptyView()
            }
        }
        .task {
            guard !checked else { return }
            checked = true
            await fetchScene()
        }
    }

    func fetchScene() async {
        isLoading = true
        do {
            let request = MKLookAroundSceneRequest(coordinate: coordinate)
            scene = try await request.scene
        } catch {
            scene = nil
        }
        isLoading = false
    }
}

struct LookAroundViewerSheet: View {
    let scene: MKLookAroundScene
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            LookAroundViewer(initialScene: scene)
                .ignoresSafeArea()
                .navigationTitle("Look Around")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { dismiss() }
                    }
                }
        }
    }
}

#Preview {
    LookAroundButton(coordinate: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060))
}