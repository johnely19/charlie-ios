import SwiftUI

struct ShareButton: View {
    let discovery: Discovery
    var label: String = "Share"
    var style: ShareButtonStyle = .icon

    enum ShareButtonStyle {
        case icon, iconAndLabel, labelOnly
    }

    var body: some View {
        ShareLink(
            item: discovery.shareURL,
            subject: Text(discovery.name),
            message: Text(discovery.shareText)
        ) {
            switch style {
            case .icon:
                Image(systemName: "square.and.arrow.up")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            case .iconAndLabel:
                Label(label, systemImage: "square.and.arrow.up")
                    .font(.subheadline)
            case .labelOnly:
                Text(label)
                    .font(.subheadline)
            }
        }
    }
}
