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
            
            let ySpaceFromButton = 10.0
            let xSpaceFromButton = 5.0
            let halfOfButtonWidth = (buttonSize.width / 2)
            
            switch tooltipPosition {
            case .left:
                let x = bounds.origin.x - halfOfButtonWidth - xSpaceFromButton
                let y = bounds.origin.y
                textAndArrowContainerSubview.place(at: .init(x: x, y: y), proposal: .unspecified)
                
            case .right:
                let x = bounds.origin.x + buttonSize.width + ySpaceFromButton + xSpaceFromButton
                let y = bounds.origin.y
                textAndArrowContainerSubview.place(at: .init(x: x, y: y), proposal: .unspecified)
                
            case .top:
                let x = bounds.origin.x + halfOfButtonWidth //ensures that container start positioned in center of the button
                let y = bounds.origin.y - buttonSize.height - ySpaceFromButton
                textAndArrowContainerSubview.place(at: .init(x: x, y: y), proposal: .unspecified)
                
            case .bottom:
                let x = bounds.origin.x + halfOfButtonWidth //ensures that container start positioned in center of the button
                let y = bounds.origin.y + buttonSize.height + ySpaceFromButton
                textAndArrowContainerSubview.place(at: .init(x: x, y: y), proposal: .unspecified)
            }
        }
    }
}
