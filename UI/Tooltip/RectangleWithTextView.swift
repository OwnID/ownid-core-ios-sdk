import SwiftUI
import OwnIDCoreSDK

public extension OwnID.UISDK {
    struct RectangleWithTextView: View {
        private let radius: CGFloat = 6
        static func == (lhs: OwnID.UISDK.RectangleWithTextView, rhs: OwnID.UISDK.RectangleWithTextView) -> Bool {
            lhs.id == rhs.id
        }
        private let id = UUID()
        public init() { }
        
        public var body: some View {
            Text("Login with FaceID / TouchID")
                .padding(.init(top: 10, leading: 16, bottom: 10, trailing: 16))
                .background(
                    RoundedRectangle(cornerRadius: radius)
                        .fill(OwnID.Colors.biometricsButtonBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: radius)
                        .stroke(OwnID.Colors.biometricsButtonBorder, lineWidth: 1)
                )
        }
    }
}
