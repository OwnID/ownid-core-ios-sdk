import SwiftUI

public extension OwnID.UISDK {
    struct LoaderViewConfig: Equatable {
        public init(color: Color = OwnID.Colors.spinnerColor,
                    backgroundColor: Color = OwnID.Colors.spinnerBackgroundColor,
                    isEnabled: Bool = true) {
            self.color = color
            self.backgroundColor = backgroundColor
            self.isEnabled = isEnabled
        }
        
        public var color: Color
        public var backgroundColor: Color
        public var isEnabled: Bool
    }
    
    enum IconButtonVariant: String {
        case fingerprint = "touchidImage"
        case faceId = "faceidImage"
    }
    
    enum ButtonVariant: Equatable {
        case iconButton(IconButtonVariant)
        case authButton
    }
    
    struct AuthButtonViewConfig: Equatable {
        public init(textSize: CGFloat = 14.0,
                    lineHeight: CGFloat = 24.0,
                    textColor: Color = .white,
                    iconColor: Color = .white,
                    backgroungColor: Color = OwnID.Colors.blue) {
            self.textSize = textSize
            self.lineHeight = lineHeight
            self.textColor = textColor
            self.iconColor = iconColor
            self.backgroungColor = backgroungColor
        }
        
        public var iconColor: Color
        public var textSize: CGFloat
        public var lineHeight: CGFloat
        public var textColor: Color
        public var backgroungColor: Color
    }
    
    enum WidgetPosition: String {
        case leading
        case trailing
    }
    
    struct OrViewConfig: Equatable {
        public init(isEnabled: Bool = true,
                    textSize: CGFloat = 16.0,
                    lineHeight: CGFloat = 24.0,
                    textColor: Color = OwnID.Colors.textGrey) {
            self.isEnabled = isEnabled
            self.textSize = textSize
            self.lineHeight = lineHeight
            self.textColor = textColor
        }
        
        public var isEnabled: Bool
        public var textSize: CGFloat
        public var lineHeight: CGFloat
        public var textColor: Color
    }
    
    struct ButtonViewConfig: Equatable {
        public init(iconColor: Color = OwnID.Colors.biometricsButtonImageColor,
                    backgroundColor: Color = OwnID.Colors.biometricsButtonBackground,
                    borderColor: Color = OwnID.Colors.biometricsButtonBorder,
                    shadowColor: Color = OwnID.Colors.biometricsButtonBorder.opacity(0.7),
                    variant: ButtonVariant = .iconButton(.faceId)) {
            self.iconColor = iconColor
            self.backgroundColor = backgroundColor
            self.borderColor = borderColor
            self.shadowColor = shadowColor
            self.variant = variant
        }
        
        public var iconColor: Color
        public var backgroundColor: Color
        public var borderColor: Color
        public var shadowColor: Color
        public var variant: ButtonVariant
    }
    
    struct VisualLookConfig: Equatable {
        public init(buttonViewConfig: ButtonViewConfig = ButtonViewConfig(),
                    orViewConfig: OrViewConfig = OrViewConfig(),
                    tooltipVisualLookConfig: TooltipVisualLookConfig = TooltipVisualLookConfig(),
                    widgetPosition: WidgetPosition = .leading,
                    loaderViewConfig: LoaderViewConfig = LoaderViewConfig(),
                    authButtonConfig: AuthButtonViewConfig = AuthButtonViewConfig()) {
            self.buttonViewConfig = buttonViewConfig
            self.authButtonConfig = authButtonConfig
            self.orViewConfig = orViewConfig
            self.tooltipVisualLookConfig = tooltipVisualLookConfig
            self.widgetPosition = widgetPosition
            self.loaderViewConfig = loaderViewConfig
        }
        
        public var buttonViewConfig: ButtonViewConfig
        public var authButtonConfig: AuthButtonViewConfig
        public var orViewConfig: OrViewConfig
        public var tooltipVisualLookConfig: TooltipVisualLookConfig
        public var widgetPosition: WidgetPosition
        public var loaderViewConfig: LoaderViewConfig
    }
}

extension OwnID.UISDK.VisualLookConfig {
    func convertToCurrentMetric() -> OwnID.CoreSDK.MetricLogEntry.CurrentMetricInformation {
        var current = OwnID.CoreSDK.MetricLogEntry.CurrentMetricInformation()
        switch self.widgetPosition {
        case .leading:
            current.widgetPositionTypeMetric = .start
            
        case .trailing:
            current.widgetPositionTypeMetric = .end
        }
        
        switch self.buttonViewConfig.variant {
        case .iconButton(let iconType):
            switch iconType {
            case .fingerprint:
                current.widgetTypeMetric = .fingerprint
                
            case .faceId:
                current.widgetTypeMetric = .faceid
            }
            
        case .authButton:
            current.widgetTypeMetric = .auth
        }
        return current
    }
}
