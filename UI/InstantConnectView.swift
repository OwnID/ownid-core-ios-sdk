import SwiftUI
import UIKit
import Combine

public extension OwnID.UISDK {
    static func showInstantConnectView(viewModel: OwnID.FlowsSDK.LoginView.ViewModel,
                                       visualConfig: OwnID.UISDK.VisualLookConfig) {
        if #available(iOS 15.0, *) {
            let view = OwnID.UISDK.InstantConnectView(viewModel: viewModel, visualConfig: visualConfig, closeClosure: {
                OwnID.UISDK.PopupManager.dismiss()
            })
            view.presentAsPopup()
        }
    }
}

public extension OwnID.UISDK {
    @available(iOS 15.0, *)
    struct InstantConnectView: Popup {
        
        enum FocusField: Hashable {
            case email
        }
        
        public static func == (lhs: OwnID.UISDK.InstantConnectView, rhs: OwnID.UISDK.InstantConnectView) -> Bool {
            lhs.uuid == rhs.uuid
        }
        private let uuid = UUID().uuidString
        private let emailPublisher = PassthroughSubject<String, Never>()
        
        private var visualConfig: VisualLookConfig
        private let closeClosure: () -> Void
        private let cornerRadius = 10.0
        private let borderWidth = 1.5
        
        @ObservedObject private var viewModel: OwnID.FlowsSDK.LoginView.ViewModel
        @FocusState private var focusedField: FocusField?
        @State private var email = ""
        @State private var error = ""
        
        private let resultPublisher = PassthroughSubject<Void, Never>()
        private var bag = Set<AnyCancellable>()
        
        @State private var isTranslationChanged = false
        
        public init(viewModel: OwnID.FlowsSDK.LoginView.ViewModel,
                    visualConfig: VisualLookConfig,
                    closeClosure: @escaping () -> Void) {
            self.viewModel = viewModel
            self.visualConfig = visualConfig
            self.closeClosure = closeClosure
            
            viewModel.updateLoginIdPublisher(emailPublisher.eraseToAnyPublisher())
            viewModel.subscribe(to: eventPublisher)
            
            viewModel.eventPublisher.sink { [self] event in
                switch event {
                case .success(let event):
                    switch event {
                    case .loading:
                        break
                        
                    case .loggedIn:
                        closeClosure()
                    }
                    
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
        
        public func createContent() -> some View {
            viewContent()
                .onChange(of: email) { newValue in emailPublisher.send(newValue) }
                .onReceive(OwnID.CoreSDK.shared.translationsModule.translationsChangePublisher) {
                    isTranslationChanged.toggle()
                }
                .overlay {
                    if isTranslationChanged {
                        EmptyView()
                    }
                }
        }
        
        @ViewBuilder
        private func topSection() -> some View {
            HStack {
                Text(localizedKey: .emailCollectTitle)
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
                    Text(localizedKey: .emailCollectMessage)
                        .font(.system(size: 18))
                    TextField("", text: $email)
                        .font(.system(size: 17))
                        .keyboardType(.emailAddress)
                        .focused($focusedField, equals: .email)
                        .padding(11)
                        .background(Rectangle().fill(.white))
                        .cornerRadius(cornerRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .stroke(OwnID.Colors.instantConnectViewEmailFiendBorderColor, lineWidth: borderWidth)
                        )
                        .padding(.bottom, 6)
                    errorView()
                    AuthButton(visualConfig: visualConfig,
                               actionHandler: { resultPublisher.send(()) },
                               isLoading: viewModel.state.isLoadingBinding,
                               buttonState: viewModel.state.buttonStateBinding,
                               translationKey: .stepsContinue)
                }
            }
            .padding()
            .onAppear() {
                let emailValue = OwnID.CoreSDK.DefaultsEmailSaver.getEmail() ?? ""
                email = emailValue
                emailPublisher.send(emailValue)
                focusedField = .email
            }
        }
    }
}

