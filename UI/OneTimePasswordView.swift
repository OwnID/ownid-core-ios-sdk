import SwiftUI
import UIKit
import Combine

extension OwnID.UISDK.OneTimePasswordView {
    struct ViewState: LoggingEnabled {
        let isLoggingEnabled: Bool
        var isLoading = false
        var isDisplayingDidNotGetCode = false
        var attempts = 0
    }
    
    enum Action {
        case codeEntered(String)
        case cancel
        case cancelCodeOperation
        case emailIsNotRecieved
        case displayDidNotGetCode
        case error(String)
        case stopLoading
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
        private let titleType: TitleType
        
        @State private var emailSentText: String
        private let emailSentTextChangedClosure: (() -> String)
        @State private var isTranslationChanged = false
        
        init(store: Store<ViewState, Action>,
             visualConfig: OTPViewConfig,
             titleType: TitleType = .oneTimePasswordSignIn,
             codeLength: OneTimePasswordCodeLength = .six,
             email: String = "fecemi9888@snowlash.com") {
            self.visualConfig = visualConfig
            self.store = store
            self.codeLength = codeLength
            self.viewModel = OTPViewModel(codeLength: codeLength, store: store)
            
            self.titleType = titleType
            
            let emailSentTextChangedClosure = {
                var text = OwnID.CoreSDK.TranslationsSDK.TranslationKey.otpSentEmail.localized()
                let codeLengthReplacement = "%CODE_LENGTH%"
                let emailReplacement = "%LOGIN_ID%"
                text = text.replacingOccurrences(of: codeLengthReplacement, with: String(codeLength.rawValue))
                text = text.replacingOccurrences(of: emailReplacement, with: email)
                return text
            }
            self.emailSentTextChangedClosure = emailSentTextChangedClosure
            _emailSentText = State(initialValue: emailSentTextChangedClosure())
        }
        
        @ViewBuilder
        private func didNotGetEmail() -> some View {
            if store.value.isDisplayingDidNotGetCode {
                Button {
                    OwnID.UISDK.PopupManager.dismiss()
                    store.send(.emailIsNotRecieved)
                } label: {
                    Text(localizedKey: .didNotGetEmail)
                }
                .padding(.top)
            }
        }
        
        func createContent() -> some View {
            if #available(iOS 15.0, *) {
                return VStack {
                    topSection()
                        OTPTextFieldView(viewModel: viewModel)
                        .shake(animatableData: store.value.attempts)
                        .padding(.bottom)
                    if store.value.isLoading {
                        OwnID.UISDK.SpinnerLoaderView(spinnerColor: visualConfig.loaderViewConfig.color,
                                                      spinnerBackgroundColor: visualConfig.loaderViewConfig.backgroundColor,
                                                      viewBackgroundColor: .clear)
                        .frame(width: 28, height: 28)
                    }
                    didNotGetEmail()
                }
                .overlay(alignment: .topTrailing) {
                    Button {
                        OwnID.UISDK.PopupManager.dismiss()
                        store.send(.cancel)
                    } label: {
                        Image("closeImage", bundle: .resourceBundle)
                    }
                }
                .padding()
                .onReceive(OwnID.CoreSDK.shared.translationsModule.translationsChangePublisher) {
                    emailSentText = emailSentTextChangedClosure()
                    isTranslationChanged.toggle()
                }
            } else {
                return EmptyView()
            }
        }
        
        @available(iOS 15.0, *)
        @ViewBuilder
        private func topSection() -> some View {
            VStack {
                Text(localizedKey: .signInWithOneTimeCode)
                    .font(.system(size: 20))
                    .bold()
                    .padding(.bottom)
                    .padding(.trailing, 18)
                    .padding(.leading, 18)
                
                Text(verbatim: emailSentText)
                    .multilineTextAlignment(.center)
                    .foregroundColor(OwnID.Colors.otpContentMessageColor)
                    .font(.system(size: 16))
                    .padding(.bottom)
                
                Text(localizedKey: .otpDescription)
                    .font(.system(size: 16))
                    .fontWeight(.semibold)
            }
            .padding()
            .overlay {
                if isTranslationChanged {
                    EmptyView()
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
                return [Just(.stopLoading) .eraseToEffect(),
                        Just(OwnID.UISDK.OneTimePasswordView.Action.cancelCodeOperation).eraseToEffect()]
            }
            state.isLoading = true
            return [
                Just(OwnID.UISDK.OneTimePasswordView.Action.displayDidNotGetCode)
                    .delay(for: 10, scheduler: DispatchQueue.main)
                    .eraseToEffect()
            ]
        case .cancel:
            return [ Just(.stopLoading) .eraseToEffect() ]
            
        case .emailIsNotRecieved:
            return [ Just(.stopLoading) .eraseToEffect() ]
            
        case .cancelCodeOperation:
            return []
            
        case .error(let message):
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            state.attempts += 1
            return [
                Just(.stopLoading)
                    .delay(for: 1, scheduler: DispatchQueue.main)
                    .eraseToEffect()
            ]
            
        case .stopLoading:
            state.isLoading = false
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
        case .stopLoading:
            return "stopLoading"
        }
    }
}

@available(iOS 15.0, *)
extension OwnID.UISDK.OneTimePasswordView {
    struct ShakeVeiwModifier: GeometryEffect {
        var amount: CGFloat = 10
        var shakesPerUnit = 3
        var animatableData: CGFloat
        
        func effectValue(size: CGSize) -> ProjectionTransform {
            ProjectionTransform(
                CGAffineTransform(translationX: amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)),
                                  y: 0)
            )
        }
    }
}

@available(iOS 15.0, *)
extension View {
    func shake(animatableData: Int) -> some View {
        self.modifier(OwnID.UISDK.OneTimePasswordView.ShakeVeiwModifier(animatableData: CGFloat(animatableData))).animation(.default, value: animatableData)
    }
}
