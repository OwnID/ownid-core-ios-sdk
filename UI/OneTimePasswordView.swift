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
    static func showOTPView(store: Store<OwnID.UISDK.OneTimePasswordView.ViewState, OwnID.UISDK.OneTimePasswordView.Action>,
                            visualConfig: OwnID.UISDK.VisualLookConfig = .init()) {
        let view = OwnID.UISDK.OneTimePasswordView(store: store, visualConfig: visualConfig)
        if #available(iOS 15.0, *) {
            view.presentAsPopup()
        }
    }
}

#warning("need to pass error & loading events from core vm to this view when they occur")
#warning("pass visual config")
extension OwnID.UISDK {
    
    enum OneTimePasswordCodeLength: Int {
        case six = 6
        case four = 4
    }
    
    struct OneTimePasswordView: Popup {
        
        enum TitleState {
            case emailVerification
            case oneTimePasswordSignIn
            
            var titleText: String {
                switch self {
                case .emailVerification:
                    return "Verify Your Email"
                    
                case .oneTimePasswordSignIn:
                    return "Sign In With a One-time Code"
                }
            }
        }
        
        static func == (lhs: OwnID.UISDK.OneTimePasswordView, rhs: OwnID.UISDK.OneTimePasswordView) -> Bool {
            lhs.uuid == rhs.uuid
        }
        private let uuid = UUID().uuidString
        
        private let viewModel = OTPViewModel()
        private var visualConfig: VisualLookConfig
        @ObservedObject var store: Store<ViewState, Action>
        private let titleState = TitleState.emailVerification
        private let codeLength: OneTimePasswordCodeLength
        
        init(store: Store<ViewState, Action>,
             visualConfig: VisualLookConfig,
             codeLength: OneTimePasswordCodeLength = .six) {
            self.visualConfig = visualConfig
            self.store = store
            self.codeLength = codeLength
        }
        
        @ViewBuilder
        private func didNotGetEmail() -> some View {
            if store.value.isDisplayingDidNotGetCode {
                Button {
                    OwnID.UISDK.PopupManager.dismiss()
                    store.send(.emailIsNotRecieved)
                } label: {
                    Text("I didn’t get the email")
                }
            }
        }
        
        func createContent() -> some View {
            if #available(iOS 15.0, *) {
                return VStack {
                    topSection()
                    VStack {
                        OTPTextFieldView(viewModel: viewModel, codeLength: codeLength)
                        errorView()
                            .padding(.leading)
                            .padding(.trailing)
                    }
                    TextButton(visualConfig: visualConfig,
                               actionHandler: {
                        store.send(.codeEntered(viewModel.verificationCode))
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
            } else {
                return EmptyView()
            }
        }
        
        @available(iOS 15.0, *)
        @ViewBuilder
        private func topSection() -> some View {
            VStack {
                Text(titleState.titleText)
                    .font(.system(size: 20))
                    .bold()
                    .padding(.bottom)
                
                Text(verbatim: "We have email you a 4-digit code to\njane_doe@email.com")
                    .multilineTextAlignment(.center)
                    .foregroundColor(OwnID.Colors.otpContentMessageColor)
                    .font(.system(size: 16))
                    .padding(.bottom)
                
                Text("Enter the verification code")
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
