import SwiftUI

extension OwnID.UISDK {
    struct SpinnerLoaderView: View {
        #warning("do we need this == and if this gets us any good")
        static func == (lhs: OwnID.UISDK.SpinnerLoaderView, rhs: OwnID.UISDK.SpinnerLoaderView) -> Bool {
            lhs.id == rhs.id
        }
        private let id = UUID()
        
        private let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
        private let style = StrokeStyle(lineWidth: 6, lineCap: .round)
        @State private var progress = 0.0
        
        var body: some View {
            ZStack {
                Circle()
                    .stroke(AngularGradient(colors: [OwnID.Colors.spinnerBackgroundColor], center: .center), style: style)
                Circle()
                    .trim(from: 0, to: 0.011)
                    .stroke(AngularGradient(colors: [OwnID.Colors.spinnerColor], center: .center), style: style)
                    .rotationEffect(Angle.degrees(360 * progress))
                    .animation(.default, value: progress)
                    .onReceive(timer) { _ in
                        progress += 0.01
                        if progress >= 1 {
                            progress = 0
                        }
                    }
            }
        }
    }
}
