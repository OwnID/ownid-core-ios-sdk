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
        
        public var eventPublisher: OwnID.UISDK.EventPubliser {
            imageButtonView.eventPublisher
                .eraseToAnyPublisher()
        }
        
        public init(viewState: Binding<ButtonState>, visualConfig: VisualLookConfig) {
            self.imageButtonView = ImageButton(viewState: viewState, visualConfig: visualConfig)
            self.isOrViewEnabled = visualConfig.isOrViewEnabled
            self.tooltipVisualLookConfig = visualConfig.tooltipVisualLookConfig
        }
        
        public var body: some View {
            HStack(spacing: 8) {
                if isOrViewEnabled {
                    OwnID.UISDK.OrView()
                }
                TooltipContainerLayout(tooltipPosition: tooltipVisualLookConfig.tooltipPosition) {
                    TooltipTextAndArrowLayout(tooltipVisualLookConfig: tooltipVisualLookConfig) {
                        RectangleWithTextView()
                            .popupTextContainerType(.text)
                        BeakView()
                            .rotationEffect(.degrees(tooltipVisualLookConfig.tooltipPosition.beakViewRotationAngle))
                            .popupTextContainerType(.beak)
                    }
                    .compositingGroup()
                    .shadow(color: .black.opacity(0.05), radius: 5, y: 4)
                    .popupContainerType(.textAndArrowContainer)
                    imageButtonView
                        .layoutPriority(1)
                        .popupContainerType(.button)
                }
            }
        }
    }
}
