import SwiftUI
import Combine

public extension OwnID.UISDK {
    struct OwnIDView: View {
        static func == (lhs: OwnID.UISDK.OwnIDView, rhs: OwnID.UISDK.OwnIDView) -> Bool {
            lhs.id == rhs.id
        }
        private let id = UUID()
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
                    
                case .start:
                    buttonAndTooltipView()
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
        if isTooltipPresented, buttonState.isTooltipShown, #available(iOS 16.0, *) {
            tooltipOnTopOfButtonView()
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
                                             action: { if !isLoading { resultPublisher.send(()) }},
                                             content: { buttonContents() })
        .layoutPriority(1)
    }
    
    @ViewBuilder
    func tooltipOnTopOfButtonView() -> some View {
        if #available(iOS 16.0, *) {
            OwnID.UISDK.TooltipContainerLayout(tooltipPosition: visualConfig.tooltipVisualLookConfig.tooltipPosition) {
                OwnID.UISDK.TooltipTextAndArrowLayout(tooltipVisualLookConfig: visualConfig.tooltipVisualLookConfig, isRTL: direction == .rightToLeft) {
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
                imageView()
                    .popupContainerType(.ownIdButton)
            }
        }
    }
}
