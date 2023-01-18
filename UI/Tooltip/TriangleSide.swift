import SwiftUI

public extension OwnID.UISDK {
    struct TriangleSide: Shape {
        public func path(in rect: CGRect) -> Path {
            var path = Path()
            
            let visibleLineOnBothEndsPercentageMultiplier = 12.0
            let offset = (visibleLineOnBothEndsPercentageMultiplier * rect.maxX) / 100
            let startX = rect.minX + offset
            path.move(to: CGPoint(x: startX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX - offset, y: rect.maxY))
            
            return path
        }
    }
}
