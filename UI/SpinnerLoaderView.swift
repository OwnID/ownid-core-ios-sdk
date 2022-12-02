import SwiftUI

extension OwnID.UISDK {
    struct SpinnerLoaderView: View {
        #warning("do we need this == and if this gets us any good")
        static func == (lhs: OwnID.UISDK.SpinnerLoaderView, rhs: OwnID.UISDK.SpinnerLoaderView) -> Bool {
            lhs.id == rhs.id
        }
        private let id = UUID()
        
        private let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
        private let style = StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round)
        @State private var progress = 0.0
        @State private var isLoading = false
        
        var body: some View {
            ZStack {
                Circle()
                    .stroke(style: style)
                    .foregroundColor(OwnID.Colors.spinnerBackgroundColor)
                Circle()
                    .trim(from: 0, to: 0.011)
                    .stroke(style: style)
                    .foregroundColor(OwnID.Colors.spinnerColor)
                    .rotationEffect(Angle(degrees: isLoading ? 360 : 0))
                    .animation(Animation.easeIn(duration: 2).repeatForever(autoreverses: false))
                    .onAppear { isLoading.toggle() }
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
