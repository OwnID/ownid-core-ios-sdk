import SwiftUI
import UIKit
import Combine

protocol Popup: View {
    associatedtype V: View

    func createContent() -> V
    func backgroundOverlayTapped()
}

extension Popup {
    func presentAsPopup() { OwnID.UISDK.PopupManager.presentPopup(OwnID.UISDK.AnyPopup(self)) }
    func dismiss() { OwnID.UISDK.PopupManager.dismissPopup() }

    var body: V { createContent() }
}

extension OwnID.UISDK {
    struct AnyPopup: Popup {
        private let popup: any Popup

        init(_ popup: some Popup) {
            self.popup = popup
        }

        func backgroundOverlayTapped() {
            popup.backgroundOverlayTapped()
        }
    }
}

extension OwnID.UISDK.AnyPopup {
    func createContent() -> some View {
        AnyView(popup)
    }
}

extension OwnID.UISDK {
    private enum PopupViewContants {
        static let contentCornerRadius: CGFloat = 10.0
        static let animationResponse = 0.32
        static let animationDampingFraction = 1.0
        static let animationDuration = 0.32
        static let backgroundOpacity = 0.05
    }
    
    final class PopupManager {
        private static var currentController: UIViewController?
        
        static func presentPopup(_ popup: AnyPopup) {
            if #available(iOS 15.0, *) {
                let controller = UIHostingController(rootView: PopupView(content: popup))
                controller.view.backgroundColor = .clear
                controller.modalPresentationStyle = .overCurrentContext
                currentController = controller
                UIApplication.topViewController()?.present(controller, animated: false)
            }
        }
        
        static func dismissPopup(completion: (() -> Void)? = nil) {
            if currentController != nil {
                currentController?.dismiss(animated: false, completion: completion)
                currentController = nil
            } else {
                completion?()
            }
        }
    }
    
    
    @available(iOS 15.0, *)
    struct PopupView<Content: Popup>: View {
        let content: Content
        
        private var overlayColour: Color { .black.opacity(PopupViewContants.backgroundOpacity) }
        private var overlayAnimation: Animation { .easeInOut }
        
        @Environment(\.colorScheme) var colorScheme
        
        var body: some View {
            ZStack {
                createOverlay()
                    .onTapGesture {
                        content.backgroundOverlayTapped()
                    }
                VStack(spacing: 0) {
                    Spacer()
                    content
                        .background(colorScheme == .dark ? .regularMaterial : .thinMaterial)
                        .containerShape(RoundedCorner(radius: PopupViewContants.contentCornerRadius, corners: [.topLeft, .topRight]))
                        .transition(.move(edge: .top))
                }
            }
        }
        
        func createOverlay() -> some View {
            overlayColour
                .ignoresSafeArea()
                .animation(overlayAnimation, value: true)
        }
    }
}
