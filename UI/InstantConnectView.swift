import SwiftUI
import UIKit
import Combine

public extension OwnID.UISDK {
    @available(iOS 15.0, *)
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
        @FocusState private var isEmailFocused: Bool
        @State private var email = ""
        @State private var error = ""
        
        private let resultPublisher = PassthroughSubject<Void, Never>()
        private var bag = Set<AnyCancellable>()
        
        public init(viewModel: OwnID.FlowsSDK.LoginView.ViewModel,
                    visualConfig: VisualLookConfig,
                    closeClosure: @escaping () -> Void) {
            self.viewModel = viewModel
            self.visualConfig = visualConfig
            self.closeClosure = closeClosure
            self.visualConfig.authButtonConfig.backgroundColor = OwnID.Colors.instantConnectViewAuthButtonColor
            
            email = OwnID.CoreSDK.DefaultsEmailSaver.getEmail() ?? ""
            
            viewModel.updateEmailPublisher(emailPublisher.eraseToAnyPublisher())
            viewModel.subscribe(to: eventPublisher)
            
            viewModel.eventPublisher.sink { [self] event in
                switch event {
                case .success(_):
                    break
                    
                case .failure(let error):
                    self.error = error.localizedDescription
                }
            }
            .store(in: &bag)
        }
        
        var eventPublisher: OwnID.UISDK.EventPubliser {
            resultPublisher
                .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
                .eraseToAnyPublisher()
        }
        
        public var body: some View {
            viewContent()
                .onChange(of: email) { newValue in emailPublisher.send(newValue) }
        }
        
        @ViewBuilder
        private func topSection() -> some View {
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
        }
        
        @ViewBuilder
        private func errorView() -> some View {
            if !error.isEmpty {
                HStack {
                    Text(error)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.red)
                        .padding(.bottom, 6)
                    Spacer()
                }
            }
        }
        
        @ViewBuilder
        private func viewContent() -> some View {
            VStack {
                topSection()
                VStack {
                    Text("Enter your email")
                        .font(.system(size: 18))
                    TextField("", text: $email)
                        .font(.system(size: 17))
                        .keyboardType(.emailAddress)
                        .focused($isEmailFocused)
                        .padding(11)
                        .background(Rectangle().fill(.white))
                        .cornerRadius(cornerRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .stroke(OwnID.Colors.instantConnectViewEmailFiendBorderColor, lineWidth: 1.5)
                        )
                        .padding(.bottom, 6)
                    errorView()
                    AuthButton(visualConfig: visualConfig,
                               actionHandler: { resultPublisher.send(()) },
                               isLoading: viewModel.state.isLoadingBinding,
                               buttonState: viewModel.state.buttonStateBinding)
                }
            }
            .padding()
            .onAppear() {
                isEmailFocused = true
            }
        }
    }
}

