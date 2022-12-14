import SwiftUI

extension OwnID.UISDK {
    struct ReactNativeLTRLayoutCalculation: XAxisOffsetCalculating {
        let isBottomPosition: Bool
        let viewOrigin: CGPoint
        let textViewWidth: CGFloat
        
        func calculateXAxisOffset(viewBounds: CGRect, screenBounds: CGRect) -> CGFloat {
            let startingPoint = Int(viewOrigin.x)
            let widthAddedPoint = Int(viewOrigin.x + textViewWidth)
            for currentX in startingPoint...widthAddedPoint {
                if !screenBounds.contains(.init(x: CGFloat(currentX), y: viewBounds.maxY)) {
                    let offset = currentX - widthAddedPoint
                    return CGFloat(offset)
                }
            }
            return 0
        }
    }
}
