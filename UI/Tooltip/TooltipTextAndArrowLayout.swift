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
            let spacingToScreenSide: CGFloat = 10
            let nativePlatform = true
            if nativePlatform {
                if Locale.current.isRTL {
//                    if viewBounds.minX <= UIScreen.main.bounds.minX {
//                        let offsetFromScreenSide = UIScreen.main.bounds.minX - viewBounds.minX
//                        let combinedOffset = offsetFromScreenSide + spacingToScreenSide
//                        return combinedOffset
//                    }
                } else {
//                    if viewBounds.maxX >= UIScreen.main.bounds.maxX {
//                        let offsetFromScreenSide = UIScreen.main.bounds.maxX - viewBounds.maxX
//                        let combinedOffset = offsetFromScreenSide - spacingToScreenSide
//                        return combinedOffset
//                    }
                }
            } else {
//                if !UIScreen.main.bounds.contains(.init(x: viewBounds.midX / 1.25, y: viewBounds.maxY)) {
//                    let offsetFromScreenSide = -(viewBounds.midX * 1.25)
//                    let combinedOffset = Locale.current.isRTL ? offsetFromScreenSide + spacingToScreenSide : offsetFromScreenSide - spacingToScreenSide
//                    return combinedOffset
//                }
//
//                if !UIScreen.main.bounds.contains(.init(x: viewBounds.midX / 1.5, y: viewBounds.maxY)) {
//                    let offsetFromScreenSide = -(viewBounds.midX * 1.5)
//                    let combinedOffset = offsetFromScreenSide - spacingToScreenSide
//                    return combinedOffset
//                }
//
//                if !UIScreen.main.bounds.contains(.init(x: viewBounds.midX / 2, y: viewBounds.maxY)) {
//                    let offsetFromScreenSide = -(viewBounds.midX / 2)
//                    let combinedOffset = offsetFromScreenSide - spacingToScreenSide
//                    return combinedOffset
//                }
//
//                if !UIScreen.main.bounds.contains(.init(x: viewBounds.midX, y: viewBounds.maxY)) {
//                    let offsetFromScreenSide = -viewBounds.midX
//                    let combinedOffset = offsetFromScreenSide - spacingToScreenSide
//                    return combinedOffset
//                }
//
//                if !UIScreen.main.bounds.contains(.init(x: viewBounds.maxX, y: viewBounds.maxY)) {
//                    let offsetFromScreenSide = -viewBounds.maxX
//                    let combinedOffset = offsetFromScreenSide - spacingToScreenSide
//                    return combinedOffset
//                }
            }
            return 0
        }
    }
}
