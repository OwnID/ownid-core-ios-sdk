import SwiftUI

extension OwnID.UISDK {
    @available(iOS 16, *)
    struct TooltipContainerLayout: Layout {
        let tooltipPosition: TooltipPositionType
        
        @available(iOS 16.0, *)
        func sizeThatFits(
            proposal: ProposedViewSize,
            subviews: Subviews,
            cache: inout Void
        ) -> CGSize {
            guard !subviews.isEmpty else { return .zero }
            let buttonSize = subviews.first(where: { $0[TooltipContainerViewTypeKey.self] == .ownIdButton })?.sizeThatFits(.unspecified) ?? .zero
            return buttonSize
        }
        
        @available(iOS 16.0, *)
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
            
            let halfOfButtonWidth = buttonSize.width / 2
            let textContainerHeight = textAndArrowContainerSubview.sizeThatFits(.unspecified).height
            
            let buttonCenter = buttonSize.height / 2
            let YButtonCenter = bounds.origin.y + buttonCenter
            let textConteinerCenter = textContainerHeight / 2
            let leftRightYPosition = YButtonCenter - textConteinerCenter
            
            let paddingFromButton = 4.0
            let spaceFromButton = BeakView.height + paddingFromButton
            
            switch tooltipPosition {
            case .left:
                let x = bounds.origin.x - spaceFromButton
                textAndArrowContainerSubview.place(at: .init(x: x, y: leftRightYPosition), proposal: .unspecified)
                
            case .right:
                let x = bounds.origin.x + buttonSize.width + spaceFromButton
                textAndArrowContainerSubview.place(at: .init(x: x, y: leftRightYPosition), proposal: .unspecified)
                
            case .top:
                let x = bounds.origin.x + halfOfButtonWidth //ensures that container start positioned in center of the button
                let y = bounds.origin.y - textContainerHeight - spaceFromButton
                textAndArrowContainerSubview.place(at: .init(x: x, y: y), proposal: .unspecified)
                
            case .bottom:
                let x = bounds.origin.x + halfOfButtonWidth //ensures that container start positioned in center of the button
                let y = bounds.origin.y + buttonSize.height + spaceFromButton
                textAndArrowContainerSubview.place(at: .init(x: x, y: y), proposal: .unspecified)
            }
        }
        
        @available(iOS 16.0, *)
        private func placeDismissButton(_ bounds: CGRect, _ dismissButton: LayoutSubviews.Element) {
            let screenBounds = UIScreen.main.bounds
            let x = max(bounds.origin.x * 2, screenBounds.width)
            let y = max(bounds.origin.y * 2, screenBounds.height)
            let size = CGSize(width: x * 2, height: y * 2)
            dismissButton.place(at: .init(x: -x, y: -y), proposal: .init(size))
        }
    }
}
