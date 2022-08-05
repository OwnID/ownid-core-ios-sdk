import SwiftUI
import OwnIDCoreSDK

extension OwnID.UISDK {
    struct TooltipTextAndArrowLayout: Layout {
        func sizeThatFits(
            proposal: ProposedViewSize,
            subviews: Subviews,
            cache: inout Void
        ) -> CGSize {
            guard !subviews.isEmpty else { return .zero }
            let textViewSize = subviews.first(where: { $0[TooltiptextAndArrowContainerViewTypeKey.self] == .text })?.sizeThatFits(.unspecified) ?? .zero
            return textViewSize
        }
        
        func placeSubviews(
            in bounds: CGRect,
            proposal: ProposedViewSize,
            subviews: Subviews,
            cache: inout Void
        ) {
            guard !subviews.isEmpty else { return }
            guard let textSubview = subviews.first(where: { $0[TooltiptextAndArrowContainerViewTypeKey.self] == .text }) else { return }
            guard let arrowSubview = subviews.first(where: { $0[TooltiptextAndArrowContainerViewTypeKey.self] == .arrow }) else { return }
            let arrowHeight = arrowSubview.sizeThatFits(.unspecified).height
            let textHeight = textSubview.sizeThatFits(.unspecified).height
            let offsetFromScreenSide = calculateTextSpacingFromScreen(viewBounds: bounds)
            let textX = Locale.current.isRTL ? bounds.origin.x - offsetFromScreenSide : bounds.origin.x + offsetFromScreenSide
            let textY = bounds.maxY - arrowHeight - (textHeight / 1.29)
            textSubview.place(at: .init(x: textX, y: textY), proposal: .unspecified)
            arrowSubview.place(at: .init(x: bounds.minX, y: bounds.maxY), proposal: .unspecified)
        }
        
        private func calculateTextSpacingFromScreen(viewBounds: CGRect) -> CGFloat {
            let layoutCalculation: XAxisOffsetCalculating
            let nativePlatform = true
            if nativePlatform {
                if Locale.current.isRTL {
                    layoutCalculation = NativeRTLLayoutCalculation()
                } else {
                    layoutCalculation = NativeLTRLayoutCalculation()
                }
            } else {
                layoutCalculation = ReactNativeUnifiedLayoutCalculation()
            }
            return layoutCalculation.calculateXAxisOffset(viewBounds: viewBounds)
        }
    }
}
