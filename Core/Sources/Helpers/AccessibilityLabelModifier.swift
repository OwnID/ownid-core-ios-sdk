
import SwiftUI

struct AccessibilityLabelModifier: ViewModifier {
    let accessibilityLabel: String
    
    func body(content: Content) -> some View {
        content.accessibilityLabel(accessibilityLabel)
    }
}
