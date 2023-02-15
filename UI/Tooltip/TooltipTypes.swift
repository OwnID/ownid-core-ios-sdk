import SwiftUI

public extension OwnID.UISDK {
    /// The side of the button that tooltip should be placed on.
    /**

                          top
            X──────────────X──────────────X
            |                             |
            |                             |
   leading  X           button            X  trailing
            |                             |
            |                             |
            X──────────────X──────────────X
                         bottom
     */
    enum TooltipPositionType: String {
        case top, bottom, leading, trailing
    }
}

public extension OwnID.UISDK {
    struct TooltipVisualLookConfig: Equatable {
        public init(backgroundColor: Color = OwnID.Colors.biometricsButtonBackground,
                    borderColor: Color = OwnID.Colors.biometricsButtonBorder,
                    textColor: Color = OwnID.Colors.defaultBlackColor,
                    textSize: CGFloat = 16,
                    lineHeight: CGFloat = 23,
                    shadowColor: Color = OwnID.Colors.defaultBlackColor,
                    isNativePlatform: Bool = true,
                    tooltipPosition: OwnID.UISDK.TooltipPositionType = .bottom) {
            self.backgroundColor = backgroundColor
            self.borderColor = borderColor
            self.textColor = textColor
            self.textSize = textSize
            self.lineHeight = lineHeight
            self.shadowColor = shadowColor
            self.isNativePlatform = isNativePlatform
            self.tooltipPosition = tooltipPosition
        }
        
        public var backgroundColor: Color
        public var borderColor: Color
        public var textColor: Color
        public var textSize: CGFloat
        public var lineHeight: CGFloat
        public var shadowColor: Color
        public var isNativePlatform: Bool
        public var tooltipPosition: TooltipPositionType
    }
}

extension OwnID.UISDK.TooltipPositionType {
    var beakViewRotationAngle: Double {
        switch self {
        case .top:
            return 180
        case .bottom:
            return 0
        case .leading:
            return 90
        case .trailing:
            return -90
        }
    }
}
