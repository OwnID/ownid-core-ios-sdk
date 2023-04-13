import SwiftUI
import UIKit
import Combine

extension OwnID.UISDK.OneTimePasswordView {
    struct ViewState: LoggingEnabled {
        let isLoggingEnabled: Bool
    }
    
    enum Action {
        case codeEntered(String)
        case cancel
        case emailIsNotRecieved
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
    struct OneTimePasswordView: Popup {
        
        enum CodeSize: Int {
            case six = 6
            case four = 4
        }
        
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
        
        private var visualConfig: VisualLookConfig
        @State private var error = ""
        private let store: Store<ViewState, Action>
        private let titleState = TitleState.emailVerification
        
        init(store: Store<ViewState, Action>,
             visualConfig: VisualLookConfig) {
            self.visualConfig = visualConfig
            self.store = store
        }
        
        func createContent() -> some View {
            if #available(iOS 15.0, *) {
                return VStack {
                    topSection()
                    OTPTextFieldView()
                    errorView()
                    TextButton(visualConfig: visualConfig,
                               actionHandler: { store.send(.codeEntered("1111")) },
                               isLoading: .constant(false),
                               buttonState: .constant(.enabled))
                    .padding(.top)
                    .padding(.bottom)
                    Button {
                        OwnID.UISDK.PopupManager.dismiss()
                        store.send(.emailIsNotRecieved)
                    } label: {
                        Text("I didn’t get the email")
                    }
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
    }
}

@available(iOS 15.0, *)
extension OwnID.UISDK.OneTimePasswordView {
    static func viewModelReducer(state: inout OwnID.UISDK.OneTimePasswordView.ViewState, action: OwnID.UISDK.OneTimePasswordView.Action) -> [Effect<OwnID.UISDK.OneTimePasswordView.Action>] {
        switch action {
        case .codeEntered(_):
            return []
        case .cancel:
            return []
        case .emailIsNotRecieved:
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
        }
    }
}