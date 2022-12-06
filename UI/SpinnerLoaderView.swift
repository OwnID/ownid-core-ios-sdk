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
        @State private var circleLineLength = 0.0
        @State private var circleRotation = 0.0
        private let animationDuration = 2.0
        private let maximumCircleLength: CGFloat = 1/3
        private let minimumCircleLength = 0.022
        
        private var increasingAnimation: Animation {
            Animation
                .linear(duration: animationDuration)
                .repeatForever(autoreverses: false)
        }
        
        private var increasingAnimation1: Animation {
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
                .frame(width: 200, height: 200)
            }.onAppear {
                withAnimation(increasingAnimation) {
                    circleRotation = 1
                }
                withAnimation(increasingAnimation1) {
                    circleLineLength = 1
                }
            }
        }
        
        @ViewBuilder
        private func increasingCircle() -> some View {
            Circle()
                .trim(from: 0, to: min((circleLineLength + minimumCircleLength), maximumCircleLength))
                .stroke(style: lineStyle)
                .foregroundColor(spinnerColor)
                .rotationEffect(.degrees(-(90 + (minimumCircleLength * 100))))
                .rotationEffect(.degrees(360 * circleRotation))
        }
        
        @ViewBuilder
        private func backgroundCircle() -> some View {
            Circle()
                .stroke(style: lineStyle)
                .foregroundColor(OwnID.Colors.spinnerBackgroundColor)
        }
    }
}
