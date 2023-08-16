
import SwiftUI

struct Overlay<Overlay: View>: ViewModifier {
    let view: Overlay
    var alignment: Alignment = .center
    
    func body(content: Content) -> some View {
        if #available(iOS 15.0, *) {
            content
                .overlay(alignment: alignment) {
                    view
                }
        } else {
            content
                .overlay(view, alignment: alignment)
        }
    }
}
