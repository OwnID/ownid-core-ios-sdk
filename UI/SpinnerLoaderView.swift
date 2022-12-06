import SwiftUI

extension OwnID.UISDK {
    struct SpinnerLoaderView: View, Equatable {
        #warning("do we need this == and if this gets us any good")
        static func == (lhs: OwnID.UISDK.SpinnerLoaderView, rhs: OwnID.UISDK.SpinnerLoaderView) -> Bool {
            lhs.id == rhs.id
        }
        private let id = UUID()
        
        private let lineStyle = StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round)
        private let spinnerColor = OwnID.Colors.spinnerColor
        private let startingTransformAngle = Angle(degrees: -90)
        @State private var increasingProgress = 0.0
        @State private var decreasingProgress = Self.maxGainPoint
        private let animationDuration = 5.0
        private static let maxGainPoint: CGFloat = 1/3
        
        private var increasingAnimation: Animation {
            Animation
                .linear(duration: animationDuration)
                .repeatForever(autoreverses: false)
        }
        
        private var decreasingAnimation: Animation {
            Animation
                .linear(duration: animationDuration)
                .repeatForever(autoreverses: false)
                .delay(animationDuration)
        }
        
        var body: some View {
            VStack {
                ZStack {
                    backgroundCircle()
                    decreasingCircle()
                    increasingCircle()
                }
                .frame(width: 200, height: 200)
                Slider(value: $increasingProgress, in: 0.0...Self.maxGainPoint)
                Text("Percentage \(increasingProgress)")
            }.onAppear {
                withAnimation(increasingAnimation) { increasingProgress = Self.maxGainPoint }
                withAnimation(decreasingAnimation) { decreasingProgress = 0 }
            }
        }
        
        @ViewBuilder
        private func decreasingCircle() -> some View {
            Circle()
                .trim(from: Self.maxGainPoint, to: decreasingProgress)
                .stroke(style: lineStyle)
                .foregroundColor(spinnerColor)
                .rotationEffect(startingTransformAngle)
                .rotationEffect(.degrees(-(360.0 * decreasingProgress * 2.0)))
        }
        
        @ViewBuilder
        private func increasingCircle() -> some View {
            Circle()
                .trim(from: 0.11, to: increasingProgress)
                .stroke(style: lineStyle)
                .foregroundColor(spinnerColor)
                .rotationEffect(startingTransformAngle)
                .rotationEffect(.degrees(360 * increasingProgress))
        }
        
        @ViewBuilder
        private func backgroundCircle() -> some View {
            Circle()
                .stroke(style: lineStyle)
                .foregroundColor(OwnID.Colors.spinnerBackgroundColor)
        }
    }
}
