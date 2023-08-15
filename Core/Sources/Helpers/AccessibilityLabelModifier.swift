
import SwiftUI

struct AccessibilityLabelModifier: ViewModifier {
    let accessibilityLabel: String
    
    func body(content: Content) -> some View {
        if #available(iOS 14.0, *) {
            content.accessibilityLabel(accessibilityLabel)
        } else {
            content.accessibility(label: Text(accessibilityLabel))
        }
    }
}
