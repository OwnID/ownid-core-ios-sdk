import SwiftUI

public extension OwnID.UISDK {
    struct LoaderViewConfig: Equatable {
        public init(spinnerColor: Color = OwnID.Colors.spinnerColor,
                    spinnerBackgroundColor: Color = OwnID.Colors.spinnerBackgroundColor,
                    isSpinnerEnabled: Bool = true) {
            self.spinnerColor = spinnerColor
            self.spinnerBackgroundColor = spinnerBackgroundColor
            self.isSpinnerEnabled = isSpinnerEnabled
        }
        
        public var spinnerColor: Color
        public var spinnerBackgroundColor: Color
        public var isSpinnerEnabled: Bool
    }
    
    enum ButtonVariant: String {
        case fingerprint = "touchidImage"
        case faceId = "faceidImage"
    }
    
    enum WidgetPosition: String {
        case start
        case end
    }
    
    struct OrViewConfig: Equatable {
        public init(isOrViewEnabled: Bool = true,
                    orTextSize: CGFloat = 16.0,
                    orLineHeight: CGFloat = 24.0,
                    orTextColor: Color = OwnID.Colors.textGrey) {
            self.isOrViewEnabled = isOrViewEnabled
            self.orTextSize = orTextSize
            self.orLineHeight = orLineHeight
            self.orTextColor = orTextColor
        }
        
        public var isOrViewEnabled: Bool
        public var orTextSize: CGFloat
        public var orLineHeight: CGFloat
        public var orTextColor: Color
    }
    
    struct ButtonViewConfig: Equatable {
        public init(iconColor: Color = OwnID.Colors.biometricsButtonImageColor,
                    backgroundColor: Color = OwnID.Colors.biometricsButtonBackground,
                    borderColor: Color = OwnID.Colors.biometricsButtonBorder,
                    shadowColor: Color = OwnID.Colors.biometricsButtonBorder.opacity(0.7),
                    variant: ButtonVariant = .fingerprint) {
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
                    widgetPosition: WidgetPosition = .start,
                    loaderViewConfig: LoaderViewConfig = LoaderViewConfig()) {
            self.buttonViewConfig = buttonViewConfig
            self.orViewConfig = orViewConfig
            self.tooltipVisualLookConfig = tooltipVisualLookConfig
            self.widgetPosition = widgetPosition
            self.loaderViewConfig = loaderViewConfig
        }
        
        public var buttonViewConfig: ButtonViewConfig
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
        case .start:
            current.widgetPositionTypeMetric = .start
            
        case .end:
            current.widgetPositionTypeMetric = .end
        }
        switch self.buttonViewConfig.variant {
        case .fingerprint:
            current.widgetTypeMetric = .fingerprint
            
        case .faceId:
            current.widgetTypeMetric = .faceid
        }
        return current
    }
}
