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
        private enum Constants {
            static let textFieldBorderWidth = 1.0
            static let titleFontSize = 20.0
            static let messageFontSize = 16.0
            static let emailFontSize = 18.0
            static let emailPadding = 10.0
            static let bottomPadding = 6.0
            static let publisherDebounce = 500
        }
        
        #warning("as of latest changes, probably needs some redesign, as for now needs somehow a bit redesigned to be inited from core view model")
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
                .debounce(for: .milliseconds(Constants.publisherDebounce), scheduler: DispatchQueue.main)
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
                .overlay(alignment: .topTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image("closeImage", bundle: .resourceBundle)
                    }
                    .padding(.trailing)
                    .padding(.top)
                }
        }
        
        public func backgroundOverlayTapped() {
            dismiss()
        }
        
        private func dismiss() {
            viewModel.resetDataAndState()
            closeClosure()
        }
        
        @ViewBuilder
        private func topSection() -> some View {
            HStack {
                Text(localizedKey: .emailCollectTitle)
                    .font(.system(size: Constants.titleFontSize))
                    .bold()
            }
            .padding(.top)
            .padding(.bottom, Constants.bottomPadding)
        }
        
        @ViewBuilder
        private func errorView() -> some View {
            if !error.isEmpty {
                HStack {
                    Text(error)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(OwnID.Colors.errorColor)
                        .padding(.bottom, Constants.bottomPadding)
                }
            }
        }
        
        @ViewBuilder
        private func viewContent() -> some View {
            VStack {
                topSection()
                VStack {
                    Text(localizedKey: .emailCollectMessage)
                        .font(.system(size: Constants.messageFontSize))
                        .foregroundColor(OwnID.Colors.otpContentMessageColor)
                        .padding(.bottom, Constants.bottomPadding)
                    errorView()
                    TextField("", text: $email)
                        .onChange(of: email) { _ in
                            error = ""
                        }
                        .font(.system(size: Constants.emailFontSize))
                        .keyboardType(.emailAddress)
                        .focused($focusedField, equals: .email)
                        .padding(Constants.emailPadding)
                        .background(Rectangle().fill(.white))
                        .cornerRadius(cornerRadiusValue)
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadiusValue)
                                .stroke(borderColor, lineWidth: Constants.textFieldBorderWidth)
                        )
                        .padding(.bottom, Constants.bottomPadding)
                        .padding(.top)
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
        
        var borderColor: Color {
            if focusedField == .email {
                return OwnID.Colors.blue
            } else {
                return OwnID.Colors.instantConnectViewEmailFiendBorderColor
            }
        }
    }
}

