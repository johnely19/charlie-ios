import SwiftUI

struct PlacePinView: View {
    let discovery: Discovery
    let triageState: TriageState
    let isSelected: Bool

    var pinColor: Color {
        if triageState == .saved { return .green }
        switch discovery.type {
        case .restaurant, .bar, .cafe: return .orange
        case .gallery, .museum, .theatre, .musicVenue: return .blue
        case .accommodation, .hotel: return .purple
        default: return .gray
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(pinColor)
                .frame(width: isSelected ? 32 : 24, height: isSelected ? 32 : 24)
            Image(systemName: pinSystemImage)
                .font(.system(size: isSelected ? 14 : 10))
                .foregroundColor(.white)
        }
        .shadow(radius: isSelected ? 4 : 2)
        .animation(.spring(), value: isSelected)
    }

    var pinSystemImage: String {
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