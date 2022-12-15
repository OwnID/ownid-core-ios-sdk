import SwiftUI

extension OwnID.UISDK {
    struct RTLLayoutCalculation: XAxisOffsetCalculating {
        let shouldIncludeDefaultOffset: Bool
        let viewOrigin: CGPoint
        let textViewWidth: CGFloat
        
        // -500 should be returned in calculations
        func calculateXAxisOffset(viewBounds: CGRect, screenBounds: CGRect) -> CGFloat {
//            var XOffset = 0.0
//            if viewBounds.minX <= screenBounds.minX {
//                XOffset = screenBounds.minX - viewBounds.minX
//            }
//            var computedOffset = viewBounds.origin.x - XOffset
//            if shouldIncludeDefaultOffset {
//                computedOffset -= defaultXAxisOffset
//            }
//            return computedOffset
            
            
//            let startingPoint = Int(viewOrigin.x)
//            let widthAddedPoint = Int(viewOrigin.x + textViewWidth)
//            for currentX in startingPoint...widthAddedPoint {
//                if !screenBounds.contains(.init(x: CGFloat(currentX), y: viewBounds.maxY)) {
//                    let offset = currentX - widthAddedPoint
//                    return CGFloat(offset)
//                }
//            }
            print("--------------------")
            print("viewOrigin", viewOrigin)
            print("viewBounds", viewBounds)
            print("textViewWidth", textViewWidth)
            let offset = -(viewBounds.maxX + viewBounds.size.width)
            print("offset", offset)
            return offset
            
        }
    }
}
