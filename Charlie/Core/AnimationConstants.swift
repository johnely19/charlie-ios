import SwiftUI

extension Animation {
    static let charlieSpring = Animation.spring(response: 0.4, dampingFraction: 0.7)
    static let charlieSnappy = Animation.spring(response: 0.2, dampingFraction: 0.8)
    static let charlieFadeIn = Animation.easeOut(duration: 0.3)
}

extension AnyTransition {
    static let pinAppear: AnyTransition = .scale(scale: 0.5).combined(with: .opacity)
    static let cardSlideUp: AnyTransition = .move(edge: .bottom).combined(with: .opacity)
    static let pageSlide: AnyTransition = .asymmetric(
        insertion: .move(edge: .trailing).combined(with: .opacity),
        removal: .move(edge: .leading).combined(with: .opacity)
    )
}