import SwiftUI
import UIKit
import Combine

extension OwnID.UISDK.OneTimePasswordView {
    struct ViewState: LoggingEnabled {
        let isLoggingEnabled: Bool
        var error = ""
        var isLoading = false
        var isDisplayingDidNotGetCode = false
    }
    
    enum Action {
        case codeEntered(String)
        case cancel
        case cancelCodeOperation
        case emailIsNotRecieved
        case displayDidNotGetCode
        case error(String)
    }
}

extension OwnID.UISDK {
    static func showOTPView(store: Store<OwnID.UISDK.OneTimePasswordView.ViewState, OwnID.UISDK.OneTimePasswordView.Action>) {
        let view = OwnID.UISDK.OneTimePasswordView(store: store, visualConfig: PopupManager.shared.visualLookConfig)
        if #available(iOS 15.0, *) {
            view.presentAsPopup()
        }
    }
}

extension OwnID.UISDK {
    
    enum OneTimePasswordCodeLength: Int {
        case six = 6
        case four = 4
    }
    
    struct OneTimePasswordView: Popup {
        
        enum TitleType {
            case emailVerification
            case oneTimePasswordSignIn
            
            var localizationKey: OwnID.CoreSDK.TranslationsSDK.TranslationKey {
                switch self {
                case .emailVerification:
                    return .verifyEmail
                    
                case .oneTimePasswordSignIn:
                    return .signInWithOneTimeCode
                }
            }
        }
        
        static func == (lhs: OwnID.UISDK.OneTimePasswordView, rhs: OwnID.UISDK.OneTimePasswordView) -> Bool {
            lhs.uuid == rhs.uuid
        }
        private let uuid = UUID().uuidString
        
        private let viewModel: OTPViewModel
        private var visualConfig: OTPViewConfig
        @ObservedObject var store: Store<ViewState, Action>
        private let titleState = TitleType.emailVerification
        private let codeLength: OneTimePasswordCodeLength
        
        @State private var noEmailText: String
        private let noEmailTextChangedClosure: (() -> String)
        
        @State private var titleText: String
        private let titleTextChangedClosure: (() -> String)
        
        init(store: Store<ViewState, Action>,
             visualConfig: OTPViewConfig,
             titleType: TitleType = .oneTimePasswordSignIn,
             codeLength: OneTimePasswordCodeLength = .six) {
            self.visualConfig = visualConfig
            self.store = store
            self.codeLength = codeLength
            self.viewModel = OTPViewModel(codeLength: codeLength, store: store)
            
            let noEmailTextChangedClosure = { OwnID.CoreSDK.TranslationsSDK.TranslationKey.didNotGetEmail.localized() }
            self.noEmailTextChangedClosure = noEmailTextChangedClosure
            _noEmailText = State(initialValue: noEmailTextChangedClosure())
            
            let titleTextChangedClosure = { titleType.localizationKey.localized() }
            self.titleTextChangedClosure = titleTextChangedClosure
            _titleText = State(initialValue: titleTextChangedClosure())
        }
        
        @ViewBuilder
        private func didNotGetEmail() -> some View {
            if store.value.isDisplayingDidNotGetCode {
                Button {
                    OwnID.UISDK.PopupManager.dismiss()
                    store.send(.emailIsNotRecieved)
                } label: {
                    Text("steps.otp.no-email")
                }
            }
        }
        
        func createContent() -> some View {
            if #available(iOS 15.0, *) {
                return VStack {
                    topSection()
                    VStack {
                        OTPTextFieldView(viewModel: viewModel)
                        errorView()
                            .padding(.leading)
                            .padding(.trailing)
                    }
                    TextButton(visualConfig: visualConfig,
                               actionHandler: {
                        viewModel.submitCode()
                    },
                               isLoading: .constant(store.value.isLoading),
                               buttonState: .constant(.enabled))
                    .padding(.top)
                    .padding(.bottom)
                    didNotGetEmail()
                }
                .overlay(alignment: .topTrailing) {
                    Button {
                        OwnID.UISDK.PopupManager.dismiss()
                        store.send(.cancel)
                    } label: {
                        Image("closeImageOTP", bundle: .resourceBundle)
                    }
                }
                .padding()
                .onReceive(OwnID.CoreSDK.shared.translationsModule.translationsChangePublisher) {
                    noEmailText = noEmailTextChangedClosure()
                    titleText = titleTextChangedClosure()
                }
            } else {
                return EmptyView()
            }
        }
        
        @available(iOS 15.0, *)
        @ViewBuilder
        private func topSection() -> some View {
            VStack {
                Text(titleText)
                    .font(.system(size: 20))
                    .bold()
                    .padding(.bottom)
                
                Text(verbatim: noEmailText)
                    .multilineTextAlignment(.center)
                    .foregroundColor(OwnID.Colors.otpContentMessageColor)
                    .font(.system(size: 16))
                    .padding(.bottom)
                
                Text("steps.otp.description")
                    .font(.system(size: 16))
                    .fontWeight(.semibold)
            }
            .padding()
        }
        
        @ViewBuilder
        private func errorView() -> some View {
            if !store.value.error.isEmpty {
                HStack {
                    Text(store.value.error)
                        .multilineTextAlignment(.leading)
                        .font(.system(size: 11))
                        .foregroundColor(OwnID.Colors.otpContentErrorColor)
                        .padding(.bottom, 6)
                    Spacer()
                }
            }
        }
    }
}

@available(iOS 15.0, *)
extension OwnID.UISDK.OneTimePasswordView {
    static func viewModelReducer(state: inout OwnID.UISDK.OneTimePasswordView.ViewState, action: OwnID.UISDK.OneTimePasswordView.Action) -> [Effect<OwnID.UISDK.OneTimePasswordView.Action>] {
        switch action {
        case .codeEntered:
            if state.isLoading {
                state.isLoading = false
                return [Just(OwnID.UISDK.OneTimePasswordView.Action.cancelCodeOperation).eraseToEffect()]
            }
            state.error = ""
            state.isLoading = true
            return [
                Just(OwnID.UISDK.OneTimePasswordView.Action.displayDidNotGetCode)
                    .delay(for: 10, scheduler: DispatchQueue.main)
                    .eraseToEffect()
            ]
        case .cancel:
            state.isLoading = false
            return []
        case .emailIsNotRecieved:
            state.isLoading = false
            return []
        case .cancelCodeOperation:
            return []
        case .error(let message):
            state.error = message
            return []
        case .displayDidNotGetCode:
            state.isDisplayingDidNotGetCode = true
            return []
        }
    }
}

@available(iOS 15.0, *)
extension OwnID.UISDK.OneTimePasswordView.Action: CustomDebugStringConvertible {
    var debugDescription: String {
        switch self {
        case .codeEntered(_):
            return "codeEntered"
        case .cancel:
            return "cancel"
        case .emailIsNotRecieved:
            return "emailIsNotRecieved"
        case .error(let message):
            return message
        case .cancelCodeOperation:
            return "cancelCodeOperation"
        case .displayDidNotGetCode:
            return "displayDidNotGetCode"
        }
    }
}
