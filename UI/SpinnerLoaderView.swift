import SwiftUI

extension OwnID.UISDK {
    struct SpinnerLoaderView: View {
        #warning("do we need this ==")
        static func == (lhs: OwnID.UISDK.SpinnerLoaderView, rhs: OwnID.UISDK.SpinnerLoaderView) -> Bool {
            lhs.id == rhs.id
        }
        private let id = UUID()
        
        var body: some View {
            Text("c")
        }
    }
}
