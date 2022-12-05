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
        private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
        private let progressResetTimer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()
        @State private var progress = 0.0
        
        private enum AnimationSteps {
            case inflate //from circle to 1/3
            case deflate //from 1/3 to circle
            
            var inverted: Self {
                switch self {
                case .inflate:
                    return .deflate
                case .deflate:
                    return .inflate
                }
            }
        }
        
        @State private var step = AnimationSteps.inflate
        
        private var repeatingAnimation: Animation {
            Animation
                .linear(duration: 1)
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
            }.onReceive(timer) { _ in
                step = step.inverted
                withAnimation(repeatingAnimation) {
                    progress += 0.5
//                    switch step {
//                    case .inflate:
//                        progress += 0.5
//                    case .deflate:
//                        <#code#>
//                    }
                }
            }
            .onReceive(progressResetTimer) { _ in
                progress = 0
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
