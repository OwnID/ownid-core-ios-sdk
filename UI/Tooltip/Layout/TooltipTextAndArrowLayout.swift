import SwiftUI

extension OwnID.UISDK {
    @available(iOS 16, *)
    struct TooltipTextAndArrowLayout: Layout {
        let tooltipVisualLookConfig: TooltipVisualLookConfig
        let isStartPosition: Bool
        let isRTL: Bool
        let globalFrame: CGRect
        
        @available(iOS 16.0, *)
        func sizeThatFits(
            proposal: ProposedViewSize,
            subviews: Subviews,
            cache: inout Void
        ) -> CGSize {
            guard !subviews.isEmpty else { return .zero }
            let textViewSize = subviews.first(where: { $0[TooltiptextAndArrowContainerViewTypeKey.self] == .text })?.sizeThatFits(.unspecified) ?? .zero
            return textViewSize
        }
        
        @available(iOS 16.0, *)
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
        
        @available(iOS 16.0, *)
        private func placeText(_ textSubview: LayoutSubviews.Element, _ beakSize: CGSize, _ bounds: CGRect) {
            let textSize = textSubview.sizeThatFits(.unspecified)
            switch tooltipVisualLookConfig.tooltipPosition {
            case .top,
                    .bottom:
                let textX = calculateTextXPosition(viewBounds: bounds)
                let textY = bounds.minY
                textSubview.place(at: .init(x: textX, y: textY), proposal: .unspecified)
                
            case .leading:
                let textX = bounds.minX - textSize.width
                let textY = bounds.origin.y
                textSubview.place(at: .init(x: textX, y: textY), proposal: .unspecified)
                
            case .trailing:
                let textX = bounds.origin.x
                let textY = bounds.origin.y
                textSubview.place(at: .init(x: textX, y: textY), proposal: .unspecified)
            }
        }
        
        @available(iOS 16.0, *)
        private func placeBeak(_ beakSubview: LayoutSubviews.Element, _ beakSize: CGSize, _ bounds: CGRect) {
            switch tooltipVisualLookConfig.tooltipPosition {
            case .top:
                let x = bounds.minX - (beakSize.width / 2) // puts beak top pin directly in the center of the start point
                let y = bounds.maxY
                beakSubview.place(at: .init(x: x, y: y), proposal: .unspecified)
                
            case .bottom:
                let x = bounds.minX - (beakSize.width / 2) // puts beak top pin directly in the center of the start point
                let y = bounds.minY - beakSize.height
                beakSubview.place(at: .init(x: x, y: y), proposal: .unspecified)
                
            case .leading:
                let x = bounds.minX - (BeakView.bottomlineWidth * 2.2)
                let y = bounds.midY - (beakSize.height / 2)
                beakSubview.place(at: .init(x: x, y: y), proposal: .unspecified)
                
            case .trailing:
                let x = bounds.minX - beakSize.width + (BeakView.bottomlineWidth * 2.2)
                let y = bounds.midY - (beakSize.height / 2)
                beakSubview.place(at: .init(x: x, y: y), proposal: .unspecified)
            }
        }
        
        @available(iOS 16.0, *)
        private func calculateTextXPosition(viewBounds: CGRect) -> CGFloat {
            let layoutCalculation: XAxisOffsetCalculating
            let isNative = tooltipVisualLookConfig.isNativePlatform
            if isRTL {
                layoutCalculation = RTLLayoutCalculation(viewFrame: globalFrame,
                                                         isStartPosition: isStartPosition,
                                                         isNative: isNative)
            } else {
                if isNative {
                    layoutCalculation = NativeLTRLayoutCalculation(viewFrame: globalFrame)
                } else {
                    layoutCalculation = ReactNativeLTRLayoutCalculation(viewFrame: globalFrame)
                }
            }
            return layoutCalculation.calculateXAxisOffset(viewBounds: viewBounds)
        }
    }
}
