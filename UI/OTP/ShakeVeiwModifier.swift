import SwiftUI

@available(iOS 15.0, *)
extension OwnID.UISDK.OneTimePasswordView {
    struct ShakeVeiwModifier: GeometryEffect {
        var amount: CGFloat = 10
        var shakesPerUnit = 3
        var animatableData: CGFloat
        
        func effectValue(size: CGSize) -> ProjectionTransform {
            ProjectionTransform(
                CGAffineTransform(translationX: amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)),
                                  y: 0)
            )
        }
    }
}

@available(iOS 15.0, *)
extension View {
    func shake(animatableData: Int) -> some View {
        self.modifier(OwnID.UISDK.OneTimePasswordView.ShakeVeiwModifier(animatableData: CGFloat(animatableData))).animation(.default, value: animatableData)
    }
}
