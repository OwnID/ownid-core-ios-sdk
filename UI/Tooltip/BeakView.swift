import SwiftUI
import OwnIDCoreSDK

public extension OwnID.UISDK {
    struct BeakView: View {
        
        static func == (lhs: OwnID.UISDK.BeakView, rhs: OwnID.UISDK.BeakView) -> Bool {
            lhs.id == rhs.id
        }
        private let id = UUID()
        
        static let bottomlineWidth = 1.3
        
        private let tooltipVisualLookConfig: TooltipVisualLookConfig
        
        public init(tooltipVisualLookConfig: OwnID.UISDK.TooltipVisualLookConfig) {
            self.tooltipVisualLookConfig = tooltipVisualLookConfig
        }
        
        public var body: some View {
            ZStack {
                Triangle()
                    .fill(tooltipVisualLookConfig.backgroundColor)
                Triangle()
                    .stroke(tooltipVisualLookConfig.borderColor, style: StrokeStyle(lineWidth: 1, lineCap: .round, lineJoin: .round))
                TriangleSide()
                    .stroke(tooltipVisualLookConfig.backgroundColor, style: StrokeStyle(lineWidth: Self.bottomlineWidth, lineCap: .round, lineJoin: .round))
            }
            .frame(width: 14, height: 8)
            .compositingGroup()
        }
    }
}
