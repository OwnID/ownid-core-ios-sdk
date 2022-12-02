import SwiftUI

extension OwnID.UISDK {
    struct SpinnerLoaderView: View {
        #warning("do we need this == and if this gets us any good")
        static func == (lhs: OwnID.UISDK.SpinnerLoaderView, rhs: OwnID.UISDK.SpinnerLoaderView) -> Bool {
            lhs.id == rhs.id
        }
        private let id = UUID()
        
        private let style = StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round)
        @State private var progress = 0.0
        
        private var repeatingAnimation: Animation {
            Animation
                .linear(duration: 10)
                .repeatForever(autoreverses: false)
        }
        
        var body: some View {
            ZStack {
                Circle()
                    .stroke(style: style)
                    .foregroundColor(OwnID.Colors.spinnerBackgroundColor)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(style: style)
                    .foregroundColor(OwnID.Colors.spinnerColor)
                    .rotationEffect(Angle(degrees: -90))
                    .rotationEffect(Angle(degrees: 360 * progress))
                Circle()
                    .trim(from: 0, to: 0.088)
                    .stroke(style: style)
                    .foregroundColor(OwnID.Colors.spinnerColor)
                    .rotationEffect(Angle(degrees: -90))
                    .rotationEffect(Angle(degrees: 360 * progress))
                    .onAppear { withAnimation(repeatingAnimation) { progress = 1 } }
            }
        }
    }
}
