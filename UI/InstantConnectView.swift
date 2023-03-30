import SwiftUI
import UIKit
import Combine

public extension OwnID.UISDK.InstantConnectView {
    static func displayInstantConnectView(emailPublisher: PassthroughSubject<String, Never>,
                                          viewModel: OwnID.FlowsSDK.LoginView.ViewModel,
                                          visualConfig: OwnID.UISDK.VisualLookConfig) -> Self {
        var hostingVC: UIHostingController<OwnID.UISDK.InstantConnectView>?
        let touchBlockerView = UIView()
        let closeClosure: () -> Void = {
            hostingVC?.willMove(toParent: .none)
            hostingVC?.view.removeFromSuperview()
            hostingVC?.removeFromParent()
            touchBlockerView.removeFromSuperview()
        }
        let instantConnectView = OwnID.UISDK.InstantConnectView(emailPublisher: emailPublisher,
                                                                viewModel: viewModel,
                                                                visualConfig: visualConfig,
                                                                closeClosure: closeClosure)
        hostingVC = UIHostingController(rootView: instantConnectView)
        guard let hostingVC, let topmostVC = topMostController else { return instantConnectView }
        
        topmostVC.addChild(hostingVC)
        topmostVC.view.addSubview(hostingVC.view)
        topmostVC.view.addSubview(touchBlockerView)
        hostingVC.view.frame = topmostVC.view.frame
        touchBlockerView.frame = topmostVC.view.frame
        touchBlockerView.layer.zPosition = CGFloat(Float.greatestFiniteMagnitude - 1)
        hostingVC.view.layer.zPosition = CGFloat(Float.greatestFiniteMagnitude)
        topmostVC.view.bringSubviewToFront(touchBlockerView)
        topmostVC.view.bringSubviewToFront(hostingVC.view)
        hostingVC.didMove(toParent: topmostVC)
        
        if #available(iOS 14.0, *) {
            hostingVC.view.backgroundColor = UIColor(OwnID.Colors.instantConnectViewBackgroundColor)
            let cornerRadius = 10.0
            hostingVC.view.layer.cornerRadius = cornerRadius
        }
        
        hostingVC.view.translatesAutoresizingMaskIntoConstraints = false
        hostingVC.view.bottomAnchor.constraint(equalTo: topmostVC.view.bottomAnchor, constant: 0).isActive = true
        hostingVC.view.leadingAnchor.constraint(equalTo: topmostVC.view.leadingAnchor, constant: 0).isActive = true
        hostingVC.view.trailingAnchor.constraint(equalTo: topmostVC.view.trailingAnchor, constant: 0).isActive = true
        
        return instantConnectView
    }
    
    private static var topMostController: UIViewController? {
        guard let window = UIApplication.shared.keyWindow, let rootViewController = window.rootViewController else {
            return nil
        }
        
        var topController = rootViewController
        
        while let newTopController = topController.presentedViewController {
            topController = newTopController
        }
        
        return topController
    }
}

public extension OwnID.UISDK {
    struct InstantConnectView: View {
        private let emailPublisher: PassthroughSubject<String, Never>
        
        private let visualConfig: VisualLookConfig
        private let closeClosure: () -> Void
        private let cornerRadius = 10.0
        
        @ObservedObject private var viewModel: OwnID.FlowsSDK.LoginView.ViewModel
        
        public init(emailPublisher: PassthroughSubject<String, Never>,
                    viewModel: OwnID.FlowsSDK.LoginView.ViewModel,
                    visualConfig: VisualLookConfig,
                    closeClosure: @escaping () -> Void) {
            self.emailPublisher = emailPublisher
            self.viewModel = viewModel
            self.visualConfig = visualConfig
            self.closeClosure = closeClosure
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
                    Button {
                        closeClosure()
                    } label: {
                        Image("closeImage", bundle: .resourceBundle)
                    }

                }
                VStack {
                    Text("Enter your email")
                    TextField("", text: $email)
                        .background(Rectangle().fill(.white))
                        .border(OwnID.Colors.instantConnectViewEmailFiendBorderColor, width: 1.5)
                        .cornerRadius(cornerRadius)
                    AuthButton(visualConfig: visualConfig,
                               actionHandler: { resultPublisher.send(()) },
                               isLoading: viewModel.state.isLoadingBinding,
                               buttonState: viewModel.state.buttonStateBinding)
                }
            }
            .padding()
        }
    }
}
