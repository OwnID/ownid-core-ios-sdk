import SwiftUI
import OwnIDCoreSDK

extension OwnID.UISDK {
    struct TooltipContainerLayout: Layout {
        let tooltipPosition: TooltipPositionType
        
        func sizeThatFits(
            proposal: ProposedViewSize,
            subviews: Subviews,
            cache: inout Void
        ) -> CGSize {
            guard !subviews.isEmpty else { return .zero }
            let buttonSize = subviews.first(where: { $0[TooltipContainerViewTypeKey.self] == .button })?.sizeThatFits(.unspecified) ?? .zero
            return buttonSize
        }
        
        func placeSubviews(
            in bounds: CGRect,
            proposal: ProposedViewSize,
            subviews: Subviews,
            cache: inout Void
        ) {
            guard let textAndArrowContainerSubview = subviews.first(where: { $0[TooltipContainerViewTypeKey.self] == .textAndArrowContainer }) else { return }
            let buttonSize = subviews.first(where: { $0[TooltipContainerViewTypeKey.self] == .button })?.sizeThatFits(.unspecified) ?? .zero
            let magicOffsetDividerNumber = 2.5
            let actualButtonWidth = buttonSize.width / magicOffsetDividerNumber
            #warning("should spaceFromButton 5.0 for all?")
            let spaceFromButton = 10.0
            switch tooltipPosition {
            case .left:
                #warning("use here buttonSize.width")
                textAndArrowContainerSubview.place(at: .init(x: bounds.origin.x - actualButtonWidth, y: bounds.origin.y), proposal: .unspecified)
                
            case .right:
                let spaceFromButton = 5.0
                textAndArrowContainerSubview.place(at: .init(x: bounds.origin.x + buttonSize.width + spaceFromButton, y: bounds.origin.y), proposal: .unspecified)
                
            case .top:
                textAndArrowContainerSubview.place(at: .init(x: bounds.origin.x + actualButtonWidth, y: bounds.origin.y - buttonSize.height - spaceFromButton), proposal: .unspecified)
                
            case .bottom:
                textAndArrowContainerSubview.place(at: .init(x: bounds.origin.x + actualButtonWidth, y: bounds.origin.y + buttonSize.height + spaceFromButton), proposal: .unspecified)
            }
        }
    }
}
