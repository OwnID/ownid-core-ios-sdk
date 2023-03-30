import SwiftUI
import UIKit
import Combine

public extension OwnID.UISDK.InstantConnectView {
    static func displayInstantConnectView(emailPublisher: PassthroughSubject<String, Never>,
                                          visualConfig: OwnID.UISDK.VisualLookConfig) -> Self {
        func topMostController() -> UIViewController? {
            guard let window = UIApplication.shared.keyWindow, let rootViewController = window.rootViewController else {
                return nil
            }
            
            var topController = rootViewController
            
            while let newTopController = topController.presentedViewController {
                topController = newTopController
            }
            
            return topController
        }
        
        let vc = topMostController()!
        let v = UIView(frame: vc.view.frame)
        v.backgroundColor = .red
        v.layer.zPosition = CGFloat(Float.greatestFiniteMagnitude)
        
        vc.view.addSubview(v)
        vc.view.bringSubviewToFront(v)
        
        let sv = OwnID.UISDK.InstantConnectView(emailPublisher: emailPublisher,
                                                visualConfig: visualConfig)
        let hosting = UIHostingController(rootView: sv)
        hosting.willMove(toParent: vc)
        v.addSubview(hosting.view)
        hosting.view.frame = v.frame
        v.bringSubviewToFront(hosting.view)
        hosting.didMove(toParent: vc)
        return sv
    }
}

public extension OwnID.UISDK {
    struct InstantConnectView: View {
        private let emailPublisher: PassthroughSubject<String, Never>
        
        private let visualConfig: VisualLookConfig
        
        @Binding private var isLoading: Bool
        @Binding private var buttonState: ButtonState
        
        public init(emailPublisher: PassthroughSubject<String, Never>,
                    //                    viewState: Binding<ButtonState>,
                    //                    isLoading: Binding<Bool>,
                    visualConfig: VisualLookConfig
        ) {
            self.emailPublisher = emailPublisher
            _isLoading = .constant(false)
            _buttonState = .constant(.enabled)
            self.visualConfig = visualConfig
        }
        
        @State private var email = ""
        
        private let resultPublisher = PassthroughSubject<Void, Never>()
        
        public var eventPublisher: OwnID.UISDK.EventPubliser {
            resultPublisher
                .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
                .eraseToAnyPublisher()
        }
        
        public var body: some View {
            if #available(iOS 14.0, *) {
                viewContent()
                    .onChange(of: email) { newValue in emailPublisher.send(newValue) }
            } else {
                viewContent()
            }
        }
        
        @ViewBuilder
        private func viewContent() -> some View {
            VStack {
                HStack {
                    Text("Sign In")
                    Spacer()
                    Image("closeImage", bundle: .resourceBundle)
                }
                VStack {
                    Text("Enter your email")
                    TextField("", text: $email)
                        .background(Rectangle().fill(.white))
                        .padding()
                    AuthButton(visualConfig: visualConfig,
                               actionHandler: { resultPublisher.send(()) },
                               isLoading: $isLoading,
                               buttonState: $buttonState)
                    .padding()
                }
            }
            .background(Rectangle().fill(.gray))
        }
    }
}
