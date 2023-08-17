import SwiftUI

public extension OwnID.UISDK {
    struct OTPViewConfig: Equatable {
        public init(authButtonConfig: OwnID.UISDK.AuthButtonViewConfig = .init(),
                    loaderViewConfig: OwnID.UISDK.LoaderViewConfig = .init()) {
            self.authButtonConfig = authButtonConfig
            self.loaderViewConfig = loaderViewConfig
        }
        
        public var authButtonConfig: AuthButtonViewConfig
        public var loaderViewConfig: LoaderViewConfig
    }
    
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
    
    enum ButtonVariant: Equatable {
        case iconButton
        case authButton
    }
    
    struct AuthButtonViewConfig: Equatable {
        public init(textSize: CGFloat = 14.0,
                    height: CGFloat = 44.0,
                    loaderHeight: CGFloat = 30.0,
                    lineHeight: CGFloat = 30.0,
                    textColor: Color = .white,
                    iconColor: Color = .white,
                    backgroundColor: Color = OwnID.Colors.blue,
                    loaderViewConfig: LoaderViewConfig = LoaderViewConfig(color: OwnID.Colors.authButtonSpinnerColor,
                                                                          backgroundColor: OwnID.Colors.authButtonSpinnerBackgroundColor)) {
            self.textSize = textSize
            self.lineHeight = lineHeight
            self.textColor = textColor
            self.iconColor = iconColor
            self.backgroundColor = backgroundColor
            self.height = height
            self.loaderHeight = loaderHeight
            self.loaderViewConfig = loaderViewConfig
        }
        
        public var iconColor: Color
        public var textSize: CGFloat
        public var height: CGFloat
        public var loaderHeight: CGFloat
        public var lineHeight: CGFloat
        public var textColor: Color
        public var backgroundColor: Color
        public var loaderViewConfig: LoaderViewConfig
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
                    iconHeight: CGFloat = 28.0,
                    backgroundColor: Color = OwnID.Colors.biometricsButtonBackground,
                    borderColor: Color = OwnID.Colors.biometricsButtonBorder,
                    variant: ButtonVariant = .iconButton) {
            self.iconColor = iconColor
            self.iconHeight = iconHeight
            self.backgroundColor = backgroundColor
            self.borderColor = borderColor
            self.variant = variant
        }
        
        public var iconColor: Color
        public var iconHeight: CGFloat
        public var backgroundColor: Color
        public var borderColor: Color
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
    func convertToCurrentMetric() -> OwnID.CoreSDK.CurrentMetricInformation {
        var current = OwnID.CoreSDK.CurrentMetricInformation()
        switch self.widgetPosition {
        case .leading:
            current.widgetPositionType = .start
            
        case .trailing:
            current.widgetPositionType = .end
        }
        
        switch self.buttonViewConfig.variant {
        case .iconButton:
            current.widgetType = .faceid
        case .authButton:
            current.widgetType = .auth
        }
        return current
    }
}
