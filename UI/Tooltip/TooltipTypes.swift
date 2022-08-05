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
