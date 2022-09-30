import Foundation
import SwiftUI
import OwnIDCoreSDK


/// Possible future improvements:
/// - default margin around tooltip can be calculated as function of the text size to have small margins when text is small and bigger when text is bigger
/// support font as setting instead/along line height and text size to support changes with system sizes (maybe use .preferredFont(forTextStyle: ) ?)

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
        
        @Environment(\.colorScheme) var colorScheme
        @Environment(\.layoutDirection) var direction
        
        public var eventPublisher: OwnID.UISDK.EventPubliser {
            imageButtonView.eventPublisher
                .eraseToAnyPublisher()
        }
        
        public init(viewState: Binding<ButtonState>,
                    visualConfig: VisualLookConfig,
                    shouldShowTooltip: Binding<Bool>) {
            _isTooltipPresented = shouldShowTooltip
            imageButtonView = ImageButton(viewState: viewState, visualConfig: visualConfig)
            self.visualConfig = visualConfig
        }
        
        public var body: some View {
            HStack(spacing: 8) {
                if visualConfig.isOrViewEnabled {
                    OwnID.UISDK.OrView(textSize: visualConfig.orTextSize,
                                       lineHeight: visualConfig.orLineHeight,
                                       textColor: visualConfig.orTextColor)
                }
                if isTooltipPresented {
                    TooltipContainerLayout(tooltipPosition: visualConfig.tooltipVisualLookConfig.tooltipPosition) {
                        TooltipTextAndArrowLayout(tooltipVisualLookConfig: visualConfig.tooltipVisualLookConfig, isRTL: direction == .rightToLeft) {
                            RectangleWithTextView(tooltipVisualLookConfig: visualConfig.tooltipVisualLookConfig)
                                .popupTextContainerType(.text)
                            BeakView(tooltipVisualLookConfig: visualConfig.tooltipVisualLookConfig)
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
                        imageButtonView
                            .layoutPriority(1)
                            .popupContainerType(.ownIdButton)
                    }
                } else {
                    imageButtonView
                        .layoutPriority(1)
                }
            }
        }
    }
}
