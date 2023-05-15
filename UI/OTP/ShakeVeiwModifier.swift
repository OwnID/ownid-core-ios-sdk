import SwiftUI

extension OwnID.UISDK.OneTimePassword {
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

extension View {
    func shake(animatableData: Int) -> some View {
        self.modifier(OwnID.UISDK.OneTimePassword.ShakeVeiwModifier(animatableData: CGFloat(animatableData))).animation(.default, value: animatableData)
    }
}
