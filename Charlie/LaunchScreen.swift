import SwiftUI

struct LaunchScreen: View {
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            // Deep indigo background
            Color(red: 0.12, green: 0.11, blue: 0.30)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Logo mark: compass rose built from SF Symbols
                ZStack {
                    Circle()
                        .fill(Color(red: 0.24, green: 0.22, blue: 0.50))
                        .frame(width: 96, height: 96)

                    Image(systemName: "location.north.fill")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 0.97, green: 0.62, blue: 0.04), .white],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                .shadow(color: Color(red: 0.97, green: 0.62, blue: 0.04).opacity(0.4), radius: 20)

                VStack(spacing: 4) {
                    Text("Charlie")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Your AI Travel Agent")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    scale = 1.0
                    opacity = 1.0
                }
            }
        }
    }
}

#Preview {
    LaunchScreen()
}