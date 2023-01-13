import SwiftUI
import Combine

public extension OwnID.UISDK {
    struct OwnIDView: View {
        private let visualConfig: VisualLookConfig
        
        private let coordinateSpaceName = String(describing: OwnID.UISDK.BorderAndHighlightButton.self)
        @Binding private var isTooltipPresented: Bool
        @Binding private var isLoading: Bool
        @Binding private var buttonState: ButtonState
        
        @Environment(\.colorScheme) var colorScheme
        @Environment(\.layoutDirection) var direction
        
        private let resultPublisher = PassthroughSubject<Void, Never>()
        
        public var eventPublisher: OwnID.UISDK.EventPubliser {
            resultPublisher
                .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
                .eraseToAnyPublisher()
        }
        
        public init(viewState: Binding<ButtonState>,
                    visualConfig: VisualLookConfig,
                    shouldShowTooltip: Binding<Bool>,
                    isLoading: Binding<Bool>) {
            _isTooltipPresented = shouldShowTooltip
            _isLoading = isLoading
            _buttonState = viewState
            self.visualConfig = visualConfig
            OwnID.CoreSDK.shared.currentMetricInformation = visualConfig.convertToCurrentMetric()
        }
        
        public var body: some View {
            HStack(spacing: 8) {
                switch visualConfig.widgetPosition {
                case .end:
                    orView()
                    buttonAndTooltipView()
                        .zIndex(1)
                    
                case .start:
                    buttonAndTooltipView()
                        .zIndex(1)
                    orView()
                }
            }
        }
    }
}

private extension OwnID.UISDK.OwnIDView {
    @ViewBuilder
    func orView() -> some View {
        if visualConfig.orViewConfig.isOrViewEnabled {
            OwnID.UISDK.OrView(textSize: visualConfig.orViewConfig.orTextSize,
                               lineHeight: visualConfig.orViewConfig.orLineHeight,
                               textColor: visualConfig.orViewConfig.orTextColor)
        }
    }
    
    @ViewBuilder
    func buttonAndTooltipView() -> some View {
        if isTooltipPresented,
           buttonState.isTooltipShown,
           #available(iOS 16.0, *) {
            ZStack {
                imageView()
                GeometryReader { geometryProxy in
                    tooltipOnTopOfButtonView(globalFrame: geometryProxy.frame(in: .global))
                        .position(x: geometryProxy.frame(in: .local).origin.x,
                                  y: geometryProxy.frame(in: .local).origin.y)
                }
            }
        } else {
            imageView()
        }
    }
    
    func variantImage() -> some View {
        let imageName = visualConfig.buttonViewConfig.variant.rawValue
        let image = Image(imageName, bundle: .resourceBundle)
            .renderingMode(.template)
            .foregroundColor(visualConfig.buttonViewConfig.iconColor)
        return image
    }
    
    @ViewBuilder
    func buttonContents() -> some View {
        ZStack {
            variantImage()
                .layoutPriority(1)
                .opacity(isLoading ? 0 : 1)
            OwnID.UISDK.SpinnerLoaderView(spinnerColor: visualConfig.loaderViewConfig.spinnerColor,
                                          spinnerBackgroundColor: visualConfig.loaderViewConfig.spinnerBackgroundColor,
                                          viewBackgroundColor: visualConfig.buttonViewConfig.backgroundColor)
            .opacity(isLoading ? 1 : 0)
        }
    }
    
    @ViewBuilder
    func imageView() -> some View {
        OwnID.UISDK.BorderAndHighlightButton(viewState: $buttonState,
                                             buttonViewConfig: visualConfig.buttonViewConfig,
                                             action: { resultPublisher.send(()) },
                                             content: { buttonContents() })
        .layoutPriority(1)
    }
    
    @ViewBuilder
    func tooltipOnTopOfButtonView(globalFrame: CGRect) -> some View {
        if #available(iOS 16.0, *) {
            OwnID.UISDK.TooltipContainerLayout(tooltipPosition: visualConfig.tooltipVisualLookConfig.tooltipPosition,
                                               globalFrame: globalFrame) {
                OwnID.UISDK.TooltipTextAndArrowLayout(tooltipVisualLookConfig: visualConfig.tooltipVisualLookConfig,
                                                      isStartPosition: visualConfig.widgetPosition == .start,
                                                      isRTL: direction == .rightToLeft,
                                                      globalFrame: globalFrame) {
                    OwnID.UISDK.RectangleWithTextView(tooltipVisualLookConfig: visualConfig.tooltipVisualLookConfig)
                        .popupTextContainerType(.text)
                    OwnID.UISDK.BeakView(tooltipVisualLookConfig: visualConfig.tooltipVisualLookConfig)
                        .rotationEffect(.degrees(visualConfig.tooltipVisualLookConfig.tooltipPosition.beakViewRotationAngle))
                        .popupTextContainerType(.beak)
                }
                .compositingGroup()
                .shadow(color: colorScheme == .dark ? .clear : visualConfig.tooltipVisualLookConfig.shadowColor.opacity(0.05), radius: 5, y: 4)
                .popupContainerType(.textAndArrowContainer)
                Button(action: { isTooltipPresented = false }) {
                    Text("")
                        .foregroundColor(.clear)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .popupContainerType(.dismissButton)
            }
        }
    }
}
