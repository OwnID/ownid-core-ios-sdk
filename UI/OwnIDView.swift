import Foundation
import SwiftUI
import OwnIDCoreSDK

public extension OwnID.UISDK {
    struct OwnIDView: View {
        static func == (lhs: OwnID.UISDK.OwnIDView, rhs: OwnID.UISDK.OwnIDView) -> Bool {
            lhs.id == rhs.id
        }
        private let id = UUID()
        private let isOrViewEnabled: Bool
        
        private let imageButtonView: ImageButton
        private let coordinateSpaceName = String(describing: OwnID.UISDK.ImageButton.self)
        
        private let tooltipVisualLookConfig: TooltipVisualLookConfig
        @State private var isTooltipPresented: Bool
        
        @Environment(\.colorScheme) var colorScheme
        
        public var eventPublisher: OwnID.UISDK.EventPubliser {
            imageButtonView.eventPublisher
                .eraseToAnyPublisher()
        }
        
        public init(viewState: Binding<ButtonState>, visualConfig: VisualLookConfig, shouldImmidiatelyShowTooltip: Bool = true) {
            let shouldPresentTooltip = viewState.wrappedValue.isTooltipShown && shouldImmidiatelyShowTooltip
            _isTooltipPresented = State(initialValue: shouldPresentTooltip)
            imageButtonView = ImageButton(viewState: viewState, visualConfig: visualConfig)
            isOrViewEnabled = visualConfig.isOrViewEnabled
            tooltipVisualLookConfig = visualConfig.tooltipVisualLookConfig
        }
        
        public var body: some View {
            HStack(spacing: 8) {
                if isOrViewEnabled {
                    OwnID.UISDK.OrView()
                }
                if isTooltipPresented {
                    TooltipContainerLayout(tooltipPosition: tooltipVisualLookConfig.tooltipPosition) {
                        TooltipTextAndArrowLayout(tooltipVisualLookConfig: tooltipVisualLookConfig) {
                            RectangleWithTextView(tooltipVisualLookConfig: tooltipVisualLookConfig)
                                .popupTextContainerType(.text)
                            BeakView(tooltipVisualLookConfig: tooltipVisualLookConfig)
                                .rotationEffect(.degrees(tooltipVisualLookConfig.tooltipPosition.beakViewRotationAngle))
                                .popupTextContainerType(.beak)
                        }
                        .compositingGroup()
                        .if(colorScheme != .dark) { view in
                            view.shadow(color: tooltipVisualLookConfig.shadowColor.opacity(0.05), radius: 5, y: 4)
                        }
                        .popupContainerType(.textAndArrowContainer)
                        imageButtonView
                            .layoutPriority(1)
                            .popupContainerType(.button)
                    }
                } else {
                    imageButtonView
                        .layoutPriority(1)
                }
            }
            .fullScreenCover(isPresented: $isTooltipPresented) {
                Button(action: { isTooltipPresented = false }) {
                    Text("")
                        .foregroundColor(.clear)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .clearPresentedModalBackground()
            }
        }
    }
}
