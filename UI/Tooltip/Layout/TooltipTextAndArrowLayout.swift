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
            
            let beakSize = beakSubview.sizeThatFits(.unspecified)
            place(textSubview, beakSize, bounds)
            place(beakSubview, bounds)
        }
        
        
        private func place(_ textSubview: LayoutSubviews.Element, _ beakSize: CGSize, _ bounds: CGRect) {
            let textSize = textSubview.sizeThatFits(.unspecified)
            let magicYTextOffsetNumber = 1.29
            let XOffsetFromScreenSide = calculateTextXOffsetFromScreen(viewBounds: bounds)
            switch tooltipVisualLookConfig.tooltipPosition {
            case .top,
                    .bottom:
                let textX = Locale.current.isRTL ? bounds.origin.x - XOffsetFromScreenSide : bounds.origin.x + XOffsetFromScreenSide
                let textY = bounds.maxY - beakSize.height - (textSize.height / magicYTextOffsetNumber)
                
                textSubview.place(at: .init(x: textX, y: textY), proposal: .unspecified)
                
            case .left:
                let offsetFromButton = 4.0
                let textX = bounds.minX - textSize.width - beakSize.width - offsetFromButton
                let textY = bounds.midY + (textSize.height / magicYTextOffsetNumber)
                textSubview.place(at: .init(x: textX, y: textY), proposal: .unspecified)
                
            case .right:
                break
            }
        }
        
        private func place(_ beakSubview: LayoutSubviews.Element, _ bounds: CGRect) {
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
        
        private func calculateTextXOffsetFromScreen(viewBounds: CGRect) -> CGFloat {
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
