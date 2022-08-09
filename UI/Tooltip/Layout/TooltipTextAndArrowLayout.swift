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
            placeText(textSubview, beakSize, bounds)
            placeBeak(beakSubview, beakSize, bounds)
        }
        
        private func placeText(_ textSubview: LayoutSubviews.Element, _ beakSize: CGSize, _ bounds: CGRect) {
            let textSize = textSubview.sizeThatFits(.unspecified)
            switch tooltipVisualLookConfig.tooltipPosition {
            case .top,
                    .bottom:
                let textX = calculateTextXPosition(viewBounds: bounds)
                let textY = bounds.minY
                textSubview.place(at: .init(x: textX, y: textY), proposal: .unspecified)
                
            case .left:
                let magicBeakWidthDividerNumber = 3.3
                let textX = bounds.minX - textSize.width + (beakSize.width / magicBeakWidthDividerNumber)
                let textY = bounds.origin.y
                textSubview.place(at: .init(x: textX, y: textY), proposal: .unspecified)
                
            case .right:
                let magicBeakWidthDividerNumber = 1.4
                let textX = bounds.origin.x + (beakSize.width / magicBeakWidthDividerNumber)
                let textY = bounds.origin.y
                textSubview.place(at: .init(x: textX, y: textY), proposal: .unspecified)
            }
        }
        
        private func placeBeak(_ beakSubview: LayoutSubviews.Element, _ beakSize: CGSize, _ bounds: CGRect) {
            switch tooltipVisualLookConfig.tooltipPosition {
            case .top:
                let x = bounds.minX - (beakSize.width / 2) // puts beak top pin directly in the center of the start point
                let y = bounds.maxY - (BeakView.bottomlineWidth / 2)
                beakSubview.place(at: .init(x: x, y: y), proposal: .unspecified)
                
            case .bottom:
                let x = bounds.minX - (beakSize.width / 2) // puts beak top pin directly in the center of the start point
                let y = bounds.minY - beakSize.height + (BeakView.bottomlineWidth / 2)
                beakSubview.place(at: .init(x: x, y: y), proposal: .unspecified)
                
            case .left:
                beakSubview.place(at: .init(x: bounds.minX, y: bounds.midY - (beakSize.height / 2)), proposal: .unspecified)
                
            case .right:
                beakSubview.place(at: .init(x: bounds.minX, y: bounds.midY - (beakSize.height / 2)), proposal: .unspecified)
            }
        }
        
        private func calculateTextXPosition(viewBounds: CGRect) -> CGFloat {
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
