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
            switch tooltipPosition {
            case .left, .right,.top:
                textAndArrowContainerSubview.place(at: .init(x: bounds.origin.x + (buttonSize.width / 2.5), y: bounds.origin.y - buttonSize.height - 10), proposal: .unspecified)
            case .bottom:
                textAndArrowContainerSubview.place(at: .init(x: bounds.origin.x + (buttonSize.width / 2.5), y: bounds.origin.y + buttonSize.height + 10), proposal: .unspecified)
            }
        }
        
        private func calculateTextSpacingFromScreen(viewFrame: CGRect) -> CGFloat {
            if viewFrame.maxX >= UIScreen.main.bounds.size.width {
                let spacingToScreenSide: CGFloat = 10
                let offsetFromScreenSide = UIScreen.main.bounds.size.width - viewFrame.maxX
                return offsetFromScreenSide - spacingToScreenSide
            }
            return 0
        }
    }
}
