import SwiftUI
import OwnIDCoreSDK

public extension OwnID.UISDK {
    struct VisualLookConfig {
        public init(biometryIconColor: Color = OwnID.Colors.biometricsButtonImageColor,
                    backgroundColor: Color = OwnID.Colors.biometricsButtonBackground,
                    borderColor: Color = OwnID.Colors.biometricsButtonBorder,
                    shadowColor: Color = OwnID.Colors.biometricsButtonBorder.opacity(0.7),
                    isOrViewEnabled: Bool = true) {
            self.biometryIconColor = biometryIconColor
            self.backgroundColor = backgroundColor
            self.borderColor = borderColor
            self.shadowColor = shadowColor
            self.isOrViewEnabled = isOrViewEnabled
        }
        
        public var biometryIconColor: Color
        public var backgroundColor: Color
        public var borderColor: Color
        public var shadowColor: Color
        public var isOrViewEnabled: Bool
    }
}
