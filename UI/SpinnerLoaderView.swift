import SwiftUI

extension OwnID.UISDK {
    struct SpinnerLoaderView: View {
        #warning("do we need this == and if this gets us any good")
        static func == (lhs: OwnID.UISDK.SpinnerLoaderView, rhs: OwnID.UISDK.SpinnerLoaderView) -> Bool {
            lhs.id == rhs.id
        }
        private let id = UUID()
        
        var body: some View {
            Circle()
                .strokeBorder(OwnID.Colors.spinnerBackgroundColor, lineWidth: 6)
        }
    }
}
