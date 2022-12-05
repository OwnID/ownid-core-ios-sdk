import SwiftUI

extension OwnID.UISDK {
    struct SpinnerLoaderView: View, Equatable {
        #warning("do we need this == and if this gets us any good")
        static func == (lhs: OwnID.UISDK.SpinnerLoaderView, rhs: OwnID.UISDK.SpinnerLoaderView) -> Bool {
            lhs.id == rhs.id
        }
        private let id = UUID()
        
        private let lineStyle = StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round)
        @State private var progress = 0.0
        
        private enum AnimationSteps: CaseIterable {
            case inflate //from circle to 1/3
            case deflate //from 1/3 to circle
        }
        
        private let steps = [AnimationSteps.allCases]
        
        private var repeatingAnimation: Animation {
            Animation
                .linear(duration: 2)
                .repeatForever(autoreverses: false)
        }
        
        var body: some View {
            ZStack {
                backgroundCircle()
                staticCircle()
                growingPartCircleLine()
            }
            .onAppear { withAnimation(repeatingAnimation) { progress = 1 } }
        }
        
        @ViewBuilder
        private func growingPartCircleLine() -> some View {
            Circle()
                .trim(from: 0, to: 0.0044)
                .stroke(style: lineStyle)
                .foregroundColor(OwnID.Colors.spinnerColor)
                .rotationEffect(Angle(degrees: -90))
                .rotationEffect(Angle(degrees: 360 * progress))
        }
        
        @ViewBuilder
        private func staticCircle() -> some View {
            Circle()
                .trim(from: 0, to: progress)
                .stroke(style: lineStyle)
                .foregroundColor(OwnID.Colors.spinnerColor)
                .rotationEffect(Angle(degrees: -90))
                .rotationEffect(Angle(degrees: 360 * progress))
        }
        
        @ViewBuilder
        private func backgroundCircle() -> some View {
            Circle()
                .stroke(style: lineStyle)
                .foregroundColor(OwnID.Colors.spinnerBackgroundColor)
        }
    }
}
