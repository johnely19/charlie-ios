import SwiftUI

struct CompanionAvatarStack: View {
    let companions: [String] // names

    var body: some View {
        HStack(spacing: -8) {
            ForEach(companions.prefix(3), id: \.self) { name in
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 28, height: 28)
                    .overlay(
                        Text(String(name.prefix(1)))
                            .font(.caption.bold())
                            .foregroundStyle(.blue)
                    )
                    .overlay(Circle().stroke(Color(.systemBackground), lineWidth: 1.5))
            }
        }
    }
}