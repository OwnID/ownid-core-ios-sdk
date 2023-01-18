import SwiftUI

public extension OwnID.UISDK {
    struct BeakView: View {
        static let bottomlineWidth = 1.3
        static let width = 14.0
        static let height = 8.0
        
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
                    .stroke(tooltipVisualLookConfig.backgroundColor, style: StrokeStyle(lineWidth: Self.bottomlineWidth, lineCap: .square, lineJoin: .bevel))
            }
            .frame(width: Self.width, height: Self.height)
            .compositingGroup()
        }
    }
}
