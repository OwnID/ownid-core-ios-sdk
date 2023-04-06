import SwiftUI
import Combine

extension View {
    var keyboardAware: some View {
        self.modifier(OwnID.UISDK.SoftwareKeyboardAdapterModifier())
    }
}

extension OwnID.UISDK {
    struct SoftwareKeyboardAdapterModifier: ViewModifier {
        @State private var currentHeight: CGFloat = 0
        
        func body(content: Content) -> some View {
            content
                .padding(.bottom, currentHeight)
                .edgesIgnoringSafeArea(.bottom)
                .animation(.keyboard)
                .onAppear(perform: subscribeToKeyboardEvents)
        }
        
        private func subscribeToKeyboardEvents() {
            NotificationCenter.Publisher(
                center: NotificationCenter.default,
                name: UIResponder.keyboardWillShowNotification
            )
            .compactMap { notification in notification.userInfo?["UIKeyboardFrameEndUserInfoKey"] as? CGRect }
            .map { rect in rect.height }
            .subscribe(Subscribers.Assign(object: self, keyPath: \.currentHeight))
            
            NotificationCenter.Publisher(
                center: NotificationCenter.default,
                name: UIResponder.keyboardWillHideNotification
            ).compactMap { notification in CGFloat.zero }
                .subscribe(Subscribers.Assign(object: self, keyPath: \.currentHeight))
        }
    }
}

extension Animation {
    static var keyboard: Animation {
        .interpolatingSpring(mass: 3, stiffness: 1000, damping: 500, initialVelocity: 0.0)
    }
}
