import SwiftUI
import OwnIDCoreSDK

public extension OwnID.UISDK {
    struct Triangle: Shape {
        static func == (lhs: OwnID.UISDK.Triangle, rhs: OwnID.UISDK.Triangle) -> Bool {
            lhs.id == rhs.id
        }
        private let id = UUID()
        
        public func path(in rect: CGRect) -> Path {
            var path = Path()
            
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
            
            return path
        }
    }
    
    struct TriangleTopLine: Shape {
        static func == (lhs: OwnID.UISDK.TriangleTopLine, rhs: OwnID.UISDK.TriangleTopLine) -> Bool {
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
