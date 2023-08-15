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
    //this was created to support landscape mode since UIHostingController itself doesn't redraw the UI correctly
    final class SliderViewController: UIViewController {
        var popup: AnyPopup!
        
        private var hostingController: UIViewController!
        
        override func viewDidLoad() {
            super.viewDidLoad()

            let hostingController = UIHostingController(rootView: PopupView(content: popup))
            hostingController.view.backgroundColor = .clear
            addChild(hostingController)
            view.addSubview(hostingController.view)
            hostingController.view.frame = view.bounds
            hostingController.didMove(toParent: self)
            self.hostingController = hostingController
        }
        
        override func viewWillLayoutSubviews() {
            super.viewWillLayoutSubviews()
            
            hostingController.view.frame = view.bounds
        }

        override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
            return .allButUpsideDown
        }
    }
    
    final class PopupManager {
        private static var currentViewController: UIViewController?
        
        static func presentPopup(_ popup: AnyPopup) {
            let viewController = SliderViewController()
            viewController.popup = popup
            viewController.view.backgroundColor = .clear
            viewController.modalPresentationStyle = .overCurrentContext
            currentViewController = viewController
            UIApplication.topViewController()?.present(viewController, animated: false)
        }
        
        static func dismissPopup(completion: (() -> Void)? = nil) {
            if currentViewController != nil {
                currentViewController?.dismiss(animated: false, completion: completion)
                currentViewController = nil
            } else {
                completion?()
            }
        }
    }
    
    private enum PopupViewContants {
        static let contentCornerRadius: CGFloat = 10.0
        static let animationResponse = 0.32
        static let animationDampingFraction = 1.0
        static let animationDuration = 0.32
        static let backgroundOpacity = 0.05
    }
    
    struct SliderBackground: ViewModifier {
        let colorScheme: ColorScheme

        func body(content: Content) -> some View {
            if #available(iOS 15.0, *) {
                content
                    .background(colorScheme == .dark ? .regularMaterial : .thinMaterial)
                    .containerShape(RoundedCorner(radius: PopupViewContants.contentCornerRadius, corners: [.topLeft, .topRight]))
            } else {
                content
                    .background(Blur(style: colorScheme == .dark ? .dark : .light)
                        .cornerRadius(PopupViewContants.contentCornerRadius, corners: [.topLeft, .topRight])
                        .ignoresSafeArea())
            }
        }
    }
    
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
                        .sliderBackground(colorScheme: colorScheme)
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

private extension View {
    func sliderBackground(colorScheme: ColorScheme) -> some View {
        modifier(OwnID.UISDK.SliderBackground(colorScheme: colorScheme))
    }
}
