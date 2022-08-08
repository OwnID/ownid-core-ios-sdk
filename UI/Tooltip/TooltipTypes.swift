import Foundation
import OwnIDCoreSDK

public extension OwnID.UISDK {
    enum TooltipPositionType {
        case top, bottom, left, right
    }
}

public extension OwnID.UISDK {
    struct TooltipVisualLookConfig {
        public init(isNativePlatform: Bool = true,
                      tooltipPosition: OwnID.UISDK.TooltipPositionType = .top,
                      shouldShowTooltip: Bool = true) {
            self.isNativePlatform = isNativePlatform
            self.tooltipPosition = tooltipPosition
            self.shouldShowTooltip = shouldShowTooltip
        }
        
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