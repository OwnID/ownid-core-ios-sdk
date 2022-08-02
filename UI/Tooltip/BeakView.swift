import SwiftUI
import OwnIDCoreSDK

public extension OwnID.UISDK {
    struct BeakView: View {
        static func == (lhs: OwnID.UISDK.BeakView, rhs: OwnID.UISDK.BeakView) -> Bool {
            lhs.id == rhs.id
        }
        private let id = UUID()
        public init() { }
        public var body: some View {
            ZStack {
                Triangle()
                    .fill(OwnID.Colors.biometricsButtonBackground)
                    .rotationEffect(.degrees(180))
                Triangle()
                    .stroke(OwnID.Colors.biometricsButtonBorder, style: StrokeStyle(lineWidth: 1, lineCap: .round, lineJoin: .round))
                    .rotationEffect(.degrees(180))
            }
        }
    }
}
