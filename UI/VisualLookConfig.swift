import SwiftUI
import OwnIDCoreSDK

public extension OwnID.UISDK {
    struct VisualLookConfig {
        
        public init(biometryIconColor: Color = OwnID.Colors.biometricsButtonImageColor,
                    backgroundColor: Color = OwnID.Colors.biometricsButtonBackground,
                    borderColor: Color = OwnID.Colors.biometricsButtonBorder,
                    shadowColor: Color = OwnID.Colors.biometricsButtonBorder.opacity(0.7),
                    isOrViewEnabled: Bool = true,
                    orTextSize: CGFloat = 16.0,
                    orLineHeight: CGFloat = 24.0,
                    orTextColor: Color = OwnID.Colors.textGrey,
                    tooltipVisualLookConfig: TooltipVisualLookConfig = TooltipVisualLookConfig()) {
            self.biometryIconColor = biometryIconColor
            self.backgroundColor = backgroundColor
            self.borderColor = borderColor
            self.shadowColor = shadowColor
            self.isOrViewEnabled = isOrViewEnabled
            self.orTextSize = orTextSize
            self.orLineHeight = orLineHeight
            self.orTextColor = orTextColor
            self.tooltipVisualLookConfig = tooltipVisualLookConfig
        }
        
        public var biometryIconColor: Color
        public var backgroundColor: Color
        public var borderColor: Color
        public var shadowColor: Color
        public var isOrViewEnabled: Bool
        public var tooltipVisualLookConfig: TooltipVisualLookConfig
        public var orTextSize: CGFloat
        public var orLineHeight: CGFloat
        public var orTextColor: Color
    }
}
