import SwiftUI

extension OwnID.UISDK {
    struct SpinnerLoaderView: View {
        #warning("do we need this == and if this gets us any good")
        static func == (lhs: OwnID.UISDK.SpinnerLoaderView, rhs: OwnID.UISDK.SpinnerLoaderView) -> Bool {
            lhs.id == rhs.id
        }
        private let id = UUID()
        
        private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
        private let style = StrokeStyle(lineWidth: 6, lineCap: .round)
        @State private var progress: CGFloat = 0.0 //why CGFloat anyway?
        
        var body: some View {
            ZStack {
                Circle()
                    .strokeBorder(OwnID.Colors.spinnerBackgroundColor, lineWidth: 6)
                Circle()
                    .trim(from: 0, to: 0.055)
                    .stroke(OwnID.Colors.spinnerColor, lineWidth: 6)
            }
        }
    }
}
