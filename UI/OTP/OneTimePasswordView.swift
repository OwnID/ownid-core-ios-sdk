import SwiftUI
import UIKit
import Combine

extension OwnID.UISDK {
    static func showOTPView(store: Store<OwnID.UISDK.OneTimePassword.ViewState, OwnID.UISDK.OneTimePassword.Action>) {
        if #available(iOS 15.0, *) {
            let view = OwnID.UISDK.OneTimePassword.OneTimePasswordView(store: store, visualConfig: PopupManager.shared.visualLookConfig)
            view.presentAsPopup()
        }
    }
}

extension OwnID.UISDK.OneTimePassword {
    @available(iOS 15.0, *)
    struct OneTimePasswordView: Popup {
        static func == (lhs: OwnID.UISDK.OneTimePassword.OneTimePasswordView, rhs: OwnID.UISDK.OneTimePassword.OneTimePasswordView) -> Bool {
            lhs.uuid == rhs.uuid
        }
        private let uuid = UUID().uuidString
        
        private let viewModel: OwnID.UISDK.OTPViewModel
        private var visualConfig: OwnID.UISDK.OTPViewConfig
        @ObservedObject var store: Store<ViewState, Action>
        private let titleState = TitleType.emailVerification
        private let codeLength: CodeLength
        private let titleType: TitleType
        
        @State private var emailSentText: String
        private let emailSentTextChangedClosure: (() -> String)
        @State private var isTranslationChanged = false
        
        init(store: Store<ViewState, Action>,
             visualConfig: OwnID.UISDK.OTPViewConfig,
             titleType: TitleType = .oneTimePasswordSignIn,
             codeLength: CodeLength = .six,
             email: String = "fecemi9888@snowlash.com") {
            self.visualConfig = visualConfig
            self.store = store
            self.codeLength = codeLength
            self.viewModel = OwnID.UISDK.OTPViewModel(codeLength: codeLength, store: store)
            
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
            return VStack {
                topSection()
                OwnID.UISDK.OTPTextFieldView(viewModel: viewModel)
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
                    dismiss()
                } label: {
                    Image("closeImage", bundle: .resourceBundle)
                }
            }
            .padding()
            .onReceive(OwnID.CoreSDK.shared.translationsModule.translationsChangePublisher) {
                emailSentText = emailSentTextChangedClosure()
                isTranslationChanged.toggle()
            }
        }
        
        func backgroundOverlayTapped() {
            dismiss()
        }
        
        private func dismiss() {
            OwnID.UISDK.PopupManager.dismiss()
            store.send(.cancel)
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
