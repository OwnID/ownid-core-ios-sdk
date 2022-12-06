import SwiftUI

extension OwnID.UISDK {
    struct SpinnerLoaderView: View, Equatable {
        #warning("do we need this == and if this gets us any good")
        static func == (lhs: OwnID.UISDK.SpinnerLoaderView, rhs: OwnID.UISDK.SpinnerLoaderView) -> Bool {
            lhs.id == rhs.id
        }
        private let id = UUID()
        
        private let lineStyle = StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round)
        let spinnerColor: Color
        let spinnerBackgroundColor: Color
        @State private var circleLineLength: Double = 0.011
        @State private var circleRotation = 0.0
        private let animationDuration = 2.0
        private let maximumCircleLength: CGFloat = 1/3
        
        private var rotationAnimation: Animation {
            Animation
                .linear(duration: animationDuration)
                .repeatForever(autoreverses: false)
        }
        
        private var lineLengthAnimation: Animation {
            Animation
                .linear(duration: animationDuration)
                .repeatForever(autoreverses: true)
        }
        
        var body: some View {
            VStack {
                ZStack {
                    backgroundCircle()
                    increasingCircle()
                }
            }.onAppear {
                withAnimation(rotationAnimation) {
                    circleRotation = 1
                }
                withAnimation(lineLengthAnimation) {
                    circleLineLength = 1
                }
            }
        }
        
        @ViewBuilder
        private func increasingCircle() -> some View {
            Circle()
                .trim(from: 0, to: min((circleLineLength), maximumCircleLength))
                .stroke(style: lineStyle)
                .foregroundColor(spinnerColor)
                .rotationEffect(.degrees(-(90)))
                .rotationEffect(.degrees(360 * circleRotation))
        }
        
        @ViewBuilder
        private func backgroundCircle() -> some View {
            Circle()
                .stroke(style: lineStyle)
                .foregroundColor(spinnerBackgroundColor)
        }
    }
}
