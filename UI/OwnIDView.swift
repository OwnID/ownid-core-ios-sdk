import Foundation
import SwiftUI

public extension OwnID.UISDK {
    struct OwnIDView: View {
        static func == (lhs: OwnID.UISDK.OwnIDView, rhs: OwnID.UISDK.OwnIDView) -> Bool {
            lhs.id == rhs.id
        }
        private let id = UUID()
        private let visualConfig: VisualLookConfig
        
        private let imageButtonView: ImageButton
        private let coordinateSpaceName = String(describing: OwnID.UISDK.ImageButton.self)
        @Binding private var isTooltipPresented: Bool
        @Binding private var isLoading: Bool
        @Binding private var viewState: ButtonState
        
        @Environment(\.colorScheme) var colorScheme
        @Environment(\.layoutDirection) var direction
        
        public var eventPublisher: OwnID.UISDK.EventPubliser {
            imageButtonView.eventPublisher
                .eraseToAnyPublisher()
        }
        
        public init(viewState: Binding<ButtonState>,
                    visualConfig: VisualLookConfig,
                    shouldShowTooltip: Binding<Bool>,
                    isLoading: Binding<Bool>) {
            _isTooltipPresented = shouldShowTooltip
            _isLoading = isLoading
            _viewState = viewState
            imageButtonView = ImageButton(viewState: viewState, visualConfig: visualConfig)
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
        if isTooltipPresented, viewState.isTooltipShown, #available(iOS 16.0, *) {
            tooltipOnTopOfButtonView()
        } else {
            imageView()
        }
    }
    
    @ViewBuilder
    func imageView() -> some View {
        ZStack {
            if isLoading {
#warning("remove debug, only displayed when tolltip overlaps")
                VStack {
                    Text("dmmdeeeeeeee").foregroundColor(.clear)
                    Text("dmmdeee").foregroundColor(.clear)
                    Text("dmmd").foregroundColor(.clear)
                    Text("dmmdeeee").foregroundColor(.clear)
                }
                OwnID.UISDK.SpinnerLoaderView()
                    .padding(9)
            } else {
                imageButtonView
                    .layoutPriority(1)
            }
        }
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
