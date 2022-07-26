import SwiftUI
import OwnIDCoreSDK

public extension OwnID.UISDK {
    struct TooltipView: View {
        static func == (lhs: OwnID.UISDK.TooltipView, rhs: OwnID.UISDK.TooltipView) -> Bool {
            lhs.id == rhs.id
        }
        private let id = UUID()
        public init() { }
        
        public var body: some View {
            Text("Login with FaceID / TouchID")
                .padding(.init(top: 10, leading: 16, bottom: 10, trailing: 16))
                .background(
                    RoundedRectangle(cornerRadius: 6)
                    .fill(.green)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                    .stroke(.blue, lineWidth: 1)
                )
        }
    }
}
