import SwiftUI

private extension OwnID.UISDK {
    struct DeviceRotationAdapterViewModifier: ViewModifier {
        let action: (UIDeviceOrientation) -> Void
        
        func body(content: Content) -> some View {
            content
                .onAppear()
                .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                    action(UIDevice.current.orientation)
                }
        }
    }
}

extension View {
    func onRotate(perform action: @escaping (UIDeviceOrientation) -> Void) -> some View {
        self.modifier(OwnID.UISDK.DeviceRotationAdapterViewModifier(action: action))
    }
}
