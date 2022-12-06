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
        @State private var decreasingRotation = 1.0
        private let animationDuration = 5.0
        private static let maxGainPoint: CGFloat = 1/3
        private let minimumWidthPoint = 0.022
        
        private var increasingAnimation: Animation {
            Animation
                .linear(duration: animationDuration)
                .repeatForever(autoreverses: false)
        }
        
        private var decreasingAnimation: Animation {
            Animation
                .linear(duration: animationDuration)
                .delay(animationDuration)
                .repeatForever(autoreverses: false)
        }
        
        var body: some View {
            VStack {
                ZStack {
                    backgroundCircle()
                    decreasingCircle()
                    increasingCircle()
                }
                .frame(width: 200, height: 200)
            }.onAppear {
                withAnimation(increasingAnimation) { increasingProgress = 1 }
                withAnimation(decreasingAnimation) {
                    decreasingProgress = 0
                    decreasingRotation = 0
                }
            }
        }
        
        @ViewBuilder
        private func decreasingCircle() -> some View {
            Circle()
                .trim(from: -1, to: decreasingProgress + minimumWidthPoint)
                .stroke(style: lineStyle)
                .foregroundColor(spinnerColor)
                .rotationEffect(.degrees(-(90.0 + ((Self.maxGainPoint * 2) * 100.0))))
                .rotationEffect(.degrees(-(360.0 * decreasingRotation)))
        }
        
        @ViewBuilder
        private func increasingCircle() -> some View {
            Circle()
                .trim(from: 0, to: min((increasingProgress + minimumWidthPoint), Self.maxGainPoint))
                .stroke(style: lineStyle)
                .foregroundColor(spinnerColor)
                .rotationEffect(.degrees(-(90 + (minimumWidthPoint * 100))))
                .rotationEffect(.degrees((360 - (360 / 6)) * increasingProgress))
        }
        
        @ViewBuilder
        private func backgroundCircle() -> some View {
            Circle()
                .stroke(style: lineStyle)
                .foregroundColor(OwnID.Colors.spinnerBackgroundColor)
        }
    }
}
