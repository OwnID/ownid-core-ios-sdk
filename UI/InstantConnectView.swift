import SwiftUI
import UIKit
import Combine

public extension OwnID.UISDK {
    struct InstantConnectView: View, Equatable {
        public static func == (lhs: OwnID.UISDK.InstantConnectView, rhs: OwnID.UISDK.InstantConnectView) -> Bool {
            lhs.uuid == rhs.uuid
        }
        private let uuid = UUID().uuidString
        private let emailPublisher = PassthroughSubject<String, Never>()
        
        private var visualConfig: VisualLookConfig
        private let closeClosure: () -> Void
        private let cornerRadius = 10.0
        private let borderWidth = 10.0
        
        @ObservedObject private var viewModel: OwnID.FlowsSDK.LoginView.ViewModel
        @State private var email = ""
        
        private let resultPublisher = PassthroughSubject<Void, Never>()
        
        public init(viewModel: OwnID.FlowsSDK.LoginView.ViewModel,
                    visualConfig: VisualLookConfig,
                    closeClosure: @escaping () -> Void) {
            self.viewModel = viewModel
            self.visualConfig = visualConfig
            self.closeClosure = closeClosure
            self.visualConfig.authButtonConfig.backgroundColor = OwnID.Colors.instantConnectViewAuthButtonColor
            
            viewModel.updateEmailPublisher(emailPublisher.eraseToAnyPublisher())
            viewModel.subscribe(to: eventPublisher)
        }
        
        var eventPublisher: OwnID.UISDK.EventPubliser {
            resultPublisher
                .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
                .eraseToAnyPublisher()
        }
        
        public var body: some View {
            if #available(iOS 15.0, *) {
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
                        .font(.system(size: 20))
                        .bold()
                    Spacer()
                    Button {
                        closeClosure()
                    } label: {
                        Image("closeImage", bundle: .resourceBundle)
                    }
                }
                VStack {
                    Text("Enter your email")
                        .font(.system(size: 18))
                    TextField("", text: $email)
                        .font(.system(size: 17))
                        .keyboardType(.emailAddress)
                        .padding(11)
                        .background(Rectangle().fill(.white))
                        .cornerRadius(cornerRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .stroke(OwnID.Colors.instantConnectViewEmailFiendBorderColor, lineWidth: 1.5)
                        )
                        .padding(.bottom, 6)
                    AuthButton(visualConfig: visualConfig,
                               actionHandler: { resultPublisher.send(()) },
                               isLoading: viewModel.state.isLoadingBinding,
                               buttonState: viewModel.state.buttonStateBinding)
                    
                    Text("")
                    Text("")
                    Text("")
                    Text("")
                }
            }
            .padding()
        }
    }
}
