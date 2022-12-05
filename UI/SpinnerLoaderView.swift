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
        @State private var progress = 0.0
        
        private var repeatingAnimation: Animation {
            Animation
                .linear(duration: 2)
                .repeatForever(autoreverses: false)
        }
        
        var body: some View {
            VStack {
                ZStack {
                    backgroundCircle()
                    staticCircle()
                    growingPartCircleLine()
                }
                .frame(width: 200, height: 200)
                Slider(value: $progress, in: 0...1)
                Text("Percentage \(progress)")
            }
            .onAppear {
                withAnimation(repeatingAnimation) { progress = 1 }
                withAnimation(repeatingAnimation) { progress = 0 }
            }
        }
        
        @ViewBuilder
        private func staticCircle() -> some View {
            Circle()
                .trim(from: 0, to: 0.0044)
                .stroke(style: lineStyle)
                .foregroundColor(spinnerColor)
                .rotationEffect(startingTransformAngle)
                .rotationEffect(rotationAngle())
        }
        
        @ViewBuilder
        private func growingPartCircleLine() -> some View {
            Circle()
                .trim(from: 0, to: progress)
                .stroke(style: lineStyle)
                .foregroundColor(spinnerColor)
                .rotationEffect(startingTransformAngle)
                .rotationEffect(rotationAngle())
        }
        
        @ViewBuilder
        private func backgroundCircle() -> some View {
            Circle()
                .stroke(style: lineStyle)
                .foregroundColor(OwnID.Colors.spinnerBackgroundColor)
        }
        
        private func rotationAngle() -> Angle { Angle(degrees: 360 * progress * 2) }
    }
}
