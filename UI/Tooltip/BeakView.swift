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
                Triangle()
                    .stroke(OwnID.Colors.biometricsButtonBorder, style: StrokeStyle(lineWidth: 1, lineCap: .round, lineJoin: .round))
                TriangleSide()
                    .stroke(OwnID.Colors.biometricsButtonBackground, style: StrokeStyle(lineWidth: 1.3, lineCap: .round, lineJoin: .round))
            }
            .frame(width: 14, height: 8)
            .compositingGroup()
            .rotationEffect(.degrees(180))
        }
    }
}
