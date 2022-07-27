import SwiftUI
import OwnIDCoreSDK

#warning("clean up?")
public extension OwnID.UISDK {
    struct TooltipView: View {
        private let radius: CGFloat = 6
        static func == (lhs: OwnID.UISDK.TooltipView, rhs: OwnID.UISDK.TooltipView) -> Bool {
            lhs.id == rhs.id
        }
        private let id = UUID()
        public init() { }
        
        public var body: some View {
            ZStack(alignment: .bottom) {
                RectangleWithTextView()
                    .padding(.init(top: 0, leading: 0, bottom: 8, trailing: 0))
                BeakView()
                    .frame(width: 14, height: 8)
            }.background(.ultraThinMaterial)
                .edgesIgnoringSafeArea(.all)
        }
    }
}
