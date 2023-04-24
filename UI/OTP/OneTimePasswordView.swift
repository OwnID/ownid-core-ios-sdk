import SwiftUI
import UIKit
import Combine

extension OwnID.UISDK {
    static func showOTPView(store: Store<OwnID.UISDK.OneTimePasswordView.ViewState, OwnID.UISDK.OneTimePasswordView.Action>) {
        let view = OwnID.UISDK.OneTimePasswordView(store: store, visualConfig: PopupManager.shared.visualLookConfig)
        if #available(iOS 15.0, *) {
            view.presentAsPopup()
        }
    }
}

extension OwnID.UISDK {
    struct OneTimePasswordView: Popup {
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
                        .foregroundColor(OwnID.Colors.otpDidNotGetEmail)
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
