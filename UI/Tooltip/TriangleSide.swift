import SwiftUI

public extension OwnID.UISDK {
    struct TriangleSide: Shape {
        static func == (lhs: OwnID.UISDK.TriangleSide, rhs: OwnID.UISDK.TriangleSide) -> Bool {
            lhs.id == rhs.id
        }
        private let id = UUID()
        
        public func path(in rect: CGRect) -> Path {
            var path = Path()
            
            path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            
            return path
        }
    }
}
