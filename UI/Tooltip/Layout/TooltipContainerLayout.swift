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
            let buttonSize = subviews.first(where: { $0[TooltipContainerViewTypeKey.self] == .ownIdButton })?.sizeThatFits(.unspecified) ?? .zero
            return buttonSize
        }
        
        func placeSubviews(
            in bounds: CGRect,
            proposal: ProposedViewSize,
            subviews: Subviews,
            cache: inout Void
        ) {
            if let dismissButton = subviews.first(where: { $0[TooltipContainerViewTypeKey.self] == .dismissButton }) {
                placeDismissButton(bounds, dismissButton)
            }
            
            guard let textAndArrowContainerSubview = subviews.first(where: { $0[TooltipContainerViewTypeKey.self] == .textAndArrowContainer }) else { return }
            let buttonSize = subviews.first(where: { $0[TooltipContainerViewTypeKey.self] == .ownIdButton })?.sizeThatFits(.unspecified) ?? .zero
            
            let increasedSpaceFromButton = 12.5
            let halfOfButtonWidth = buttonSize.width / 2
            let textContainerHeight = textAndArrowContainerSubview.sizeThatFits(.unspecified).height
            
            let buttonCenter = buttonSize.height / 2
            let YButtonCenter = bounds.origin.y + buttonCenter
            let textConteinerCenter = textContainerHeight / 2
            let leftRightYPosition = YButtonCenter - textConteinerCenter
            
            switch tooltipPosition {
            case .left:
                let x = bounds.origin.x - BeakView.width
                textAndArrowContainerSubview.place(at: .init(x: x, y: leftRightYPosition), proposal: .unspecified)
                
            case .right:
                let x = bounds.origin.x + buttonSize.width + BeakView.width
                textAndArrowContainerSubview.place(at: .init(x: x, y: leftRightYPosition), proposal: .unspecified)
                
            case .top:
                let partOfButtonHeight = buttonSize.height / 4
                let x = bounds.origin.x + halfOfButtonWidth //ensures that container start positioned in center of the button
                let y = bounds.origin.y - partOfButtonHeight - textContainerHeight
                textAndArrowContainerSubview.place(at: .init(x: x, y: y), proposal: .unspecified)
                
            case .bottom:
                let x = bounds.origin.x + halfOfButtonWidth //ensures that container start positioned in center of the button
                let y = bounds.origin.y + buttonSize.height + increasedSpaceFromButton
                textAndArrowContainerSubview.place(at: .init(x: x, y: y), proposal: .unspecified)
            }
        }
        
        private func placeDismissButton(_ bounds: CGRect, _ dismissButton: LayoutSubviews.Element) {
            let screenBounds = UIScreen.main.bounds
            let x = max(bounds.origin.x * 2, screenBounds.width)
            let y = max(bounds.origin.y * 2, screenBounds.height)
            let size = CGSize(width: x * 2, height: y * 2)
            dismissButton.place(at: .init(x: -x, y: -y), proposal: .init(size))
        }
    }
}
