import SwiftUI

public extension View {
    func eraseToAnyView() -> AnyView { AnyView(self) }
    
    var cornerRadiusValue: CGFloat { 6.0 }
    
    func border(color: Color) -> some View {
        self
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadiusValue)
                    .stroke(color, lineWidth: 0.75)
            )
    }
    
    func backgroundRectangle(color: Color) -> some View {
        RoundedRectangle(cornerRadius: cornerRadiusValue)
            .fill(color)
    }
}
