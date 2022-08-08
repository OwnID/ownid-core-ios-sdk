import SwiftUI
import OwnIDCoreSDK

extension OwnID.UISDK {
    struct TooltipTextAndArrowLayout: Layout {
        let tooltipVisualLookConfig: TooltipVisualLookConfig
        
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
            guard let beakSubview = subviews.first(where: { $0[TooltiptextAndArrowContainerViewTypeKey.self] == .beak }) else { return }
            
            let arrowHeight = beakSubview.sizeThatFits(.unspecified).height
            let textHeight = textSubview.sizeThatFits(.unspecified).height
            
            let offsetFromScreenSide = calculateTextSpacingFromScreen(viewBounds: bounds)
            
            let textX = Locale.current.isRTL ? bounds.origin.x - offsetFromScreenSide : bounds.origin.x + offsetFromScreenSide
            let magicYTextOffsetNumber = 1.29
            let textY = bounds.maxY - arrowHeight - (textHeight / magicYTextOffsetNumber)
            
            textSubview.place(at: .init(x: textX, y: textY), proposal: .unspecified)
            
            switch tooltipVisualLookConfig.tooltipPosition {
            case .top:
                beakSubview.place(at: .init(x: bounds.minX, y: bounds.maxY), proposal: .unspecified)
            case .bottom:
                let magicBottomYOffsetNumber = 5.5
                beakSubview.place(at: .init(x: bounds.minX, y: bounds.origin.y - magicBottomYOffsetNumber), proposal: .unspecified)
            case .left:
                break
            case .right:
                break
            }
        }
        
        private func calculateTextSpacingFromScreen(viewBounds: CGRect) -> CGFloat {
            let layoutCalculation: XAxisOffsetCalculating
            let isRTL = Locale.current.isRTL
            if tooltipVisualLookConfig.isNativePlatform {
                if isRTL {
                    layoutCalculation = NativeRTLLayoutCalculation()
                } else {
                    layoutCalculation = NativeLTRLayoutCalculation()
                }
            } else {
                layoutCalculation = ReactNativeUnifiedLayoutCalculation(isRTL: isRTL)
            }
            return layoutCalculation.calculateXAxisOffset(viewBounds: viewBounds)
        }
    }
}
