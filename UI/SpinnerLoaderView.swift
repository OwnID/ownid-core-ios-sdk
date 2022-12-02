import SwiftUI

extension OwnID.UISDK {
    struct SpinnerLoaderView: View {
        #warning("do we need this == and if this gets us any good")
        static func == (lhs: OwnID.UISDK.SpinnerLoaderView, rhs: OwnID.UISDK.SpinnerLoaderView) -> Bool {
            lhs.id == rhs.id
        }
        private let id = UUID()
        
        private let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
        private let style = StrokeStyle(lineWidth: 6, lineCap: .round)
        @State private var progress: CGFloat = 0.0 //why CGFloat anyway?
        
        var body: some View {
            ZStack {
                Circle()
                    .stroke(AngularGradient(colors: [OwnID.Colors.spinnerBackgroundColor], center: .center), style: style)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(AngularGradient(colors: [OwnID.Colors.spinnerColor], center: .center), style: style)
                    .animation(.default, value: progress)
                    .onReceive(timer) { _ in
                        progress += 0.01
                        if self.progress >= 1 {
                            progress = 0
                        }
                    }
            }
        }
    }
}
