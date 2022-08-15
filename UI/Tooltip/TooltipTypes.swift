import SwiftUI
import OwnIDCoreSDK

public extension OwnID.UISDK {
    /// The side of the button that tooltip should be placed on.
    /**

                          top
            X──────────────X──────────────X
            |                             |
            |                             |
      left  X           button            X  right
            |                             |
            |                             |
            X──────────────X──────────────X
                         bottom
     */
    enum TooltipPositionType {
        case top, bottom, left, right
    }
}

public extension OwnID.UISDK {
    struct TooltipVisualLookConfig {
        public init(backgroundColor: Color = OwnID.Colors.biometricsButtonBackground,
                    borderColor: Color = OwnID.Colors.biometricsButtonBorder,
                    textColor: Color = OwnID.Colors.defaultBlackColor,
                    shadowColor: Color = OwnID.Colors.defaultBlackColor,
                    isNativePlatform: Bool = true,
                    tooltipPosition: OwnID.UISDK.TooltipPositionType = .top,
                    shouldShowTooltip: Bool = true) {
            self.backgroundColor = backgroundColor
            self.borderColor = borderColor
            self.textColor = textColor
            self.shadowColor = shadowColor
            self.isNativePlatform = isNativePlatform
            self.tooltipPosition = tooltipPosition
            self.shouldShowTooltip = shouldShowTooltip
        }
        
        public var backgroundColor: Color
        public var borderColor: Color
        public var textColor: Color
        public var shadowColor: Color
        public var isNativePlatform: Bool = true
        public var tooltipPosition: TooltipPositionType = .top
        public var shouldShowTooltip: Bool = true
    }
}

extension OwnID.UISDK.TooltipPositionType {
    var beakViewRotationAngle: Double {
        switch self {
        case .top:
            return 180
        case .bottom:
            return 0
        case .left:
            return 90
        case .right:
            return -90
        }
    }
}
