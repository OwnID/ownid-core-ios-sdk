import SwiftUI
import UIKit
import Combine

@available(iOS 15.0, *)
public extension View {
    func addInstantOverlayView() -> some View {
        overlay(OwnID.UISDK.PopupView())
    }
}

@available(iOS 15.0, *)
extension UIScreen {
    static let width: CGFloat = main.bounds.size.width
    static let height: CGFloat = main.bounds.size.height
    static let safeArea: UIEdgeInsets = {
        UIApplication.shared.connectedScenes
            .filter({ $0.activationState == .foregroundActive })
            .map({ $0 as? UIWindowScene })
            .compactMap({ $0 })
            .first?.windows
            .filter({ $0.isKeyWindow })
            .first?
            .safeAreaInsets ?? .zero
    }()
}

@available(iOS 15.0, *)
extension View {
    func alignToBottom() -> some View {
        VStack(spacing: 0) {
            Spacer()
            self
        }
    }
}

extension OwnID.UISDK {
    @available(iOS 15.0, *)
    struct PopupStackView: View {
        let popupContent: OwnID.UISDK.InstantConnectView
        var body: some View {
            VStack(spacing: 0) {
                Spacer()
                ZStack(alignment: .bottom) {
                    popupContent
                        .background(.white)
                        .transition(.move(edge: .top))
                }
                .keyboardAware
            }
            .ignoresSafeArea()
            .animation(.spring(response: 0.32, dampingFraction: 1, blendDuration: 0.32), value: popupContent)
        }
    }
}

public extension OwnID.UISDK {
    @available(iOS 15.0, *)
    class PopupManager: ObservableObject {
        @Published var views = [OwnID.UISDK.InstantConnectView]()
        
        public static let shared: PopupManager = .init()
        private init() {}
    }
}

@available(iOS 15.0, *)
extension OwnID.UISDK.PopupManager {
    public static func present(_ popup: OwnID.UISDK.InstantConnectView) { DispatchQueue.main.async { withAnimation(nil) {
        shared.views.append(popup)
    }}}
    
    public static func dismiss() { shared.views.removeAll() }
}

extension OwnID.UISDK {
    @available(iOS 15.0, *)
    struct PopupView: View {
        @State private var orientation = UIDeviceOrientation.portrait
        @StateObject private var stack: PopupManager = .shared
        
        var body: some View {
            if let view = stack.views.first {
                PopupStackView(popupContent: view)
                    .frame(width: orientation.isPortrait ? UIScreen.width : UIScreen.height, height: orientation.isPortrait ?  UIScreen.height : UIScreen.width)
                    .background(createOverlay())
                    .onRotate { newOrientation in
                        orientation = newOrientation
                    }
            } else {
                EmptyView()
            }
        }
    }
}

@available(iOS 15.0, *)
private extension OwnID.UISDK.PopupView {
    var overlayColour: Color { .black.opacity(0.05) }
    var overlayAnimation: Animation { .easeInOut }
}

@available(iOS 15.0, *)
private extension OwnID.UISDK.PopupView {
    func createOverlay() -> some View {
        overlayColour
            .ignoresSafeArea()
            .animation(overlayAnimation, value: true)
    }
}
private extension OwnID.UISDK {
    struct DeviceRotationViewModifier: ViewModifier {
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
        self.modifier(OwnID.UISDK.DeviceRotationViewModifier(action: action))
    }
}
