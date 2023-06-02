import SwiftUI
import UIKit
import Combine

extension OwnID.UISDK {
    static func showOTPView(store: Store<OwnID.UISDK.OneTimePassword.ViewState, OwnID.UISDK.OneTimePassword.Action>,
                            loginId: String,
                            otpLength: Int,
                            restartUrl: URL,
                            type: OwnID.CoreSDK.CoreViewModel.Step.StepType,
                            verificationType: OwnID.CoreSDK.Verification.VerificationType) {
        if #available(iOS 15.0, *) {
            let titleType: OwnID.UISDK.OneTimePassword.TitleType = type == .loginIDAuthorization ? .oneTimePasswordSignIn : .emailVerification
            let codeLength = OneTimePassword.CodeLength(rawValue: otpLength) ?? .four
            let view = OwnID.UISDK.OneTimePassword.OneTimePasswordView(store: store,
                                                                       visualConfig: PopupManager.shared.visualLookConfig,
                                                                       loginId: loginId,
                                                                       codeLength: codeLength,
                                                                       restartURL: restartUrl,
                                                                       titleType: titleType,
                                                                       verificationType: verificationType)
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
        
        private enum Constants {
            static let topPadding = 24.0
            static let titleFontSize = 20.0
            static let titlePadding = 18.0
            static let messageFontSize = 16.0
            static let didNotGetEmailFontSize = 14.0
            static let spinnerSize = 28.0
            static let bottomViewHeight = 40.0
            static let closeImageName = "closeImage"
            static let codeLengthReplacement = "%CODE_LENGTH%"
            static let emailReplacement = "%LOGIN_ID%"
        }
        
        private let uuid = UUID().uuidString
        
        private let viewModel: OwnID.UISDK.OTPTextFieldView.ViewModel
        private var visualConfig: OwnID.UISDK.OTPViewConfig
        @ObservedObject var store: Store<ViewState, Action>
        private let titleState = TitleType.emailVerification
        private let codeLength: CodeLength
        private let titleType: TitleType
        private let restartURL: URL
        
        #warning("maybe move this translations approach to Property wrappers ?")
        @State private var emailSentText: String
        private let emailSentTextChangedClosure: (() -> String)
        @State private var isTranslationChanged = false
        
        init(store: Store<ViewState, Action>,
             visualConfig: OwnID.UISDK.OTPViewConfig,
             loginId: String,
             codeLength: CodeLength = .four,
             restartURL: URL,
             titleType: TitleType = .oneTimePasswordSignIn,
             verificationType: OwnID.CoreSDK.Verification.VerificationType) {
            self.visualConfig = visualConfig
            self.store = store
            self.codeLength = codeLength
            self.restartURL = restartURL
            self.viewModel = OwnID.UISDK.OTPTextFieldView.ViewModel(codeLength: codeLength, store: store)
            
            self.titleType = titleType
            
            let emailSentTextChangedClosure = {
                var text = OwnID.CoreSDK.TranslationsSDK.TranslationKey.otpSentEmail.localized()
                let codeLengthReplacement = Constants.codeLengthReplacement
                let emailReplacement = Constants.emailReplacement
                text = text.replacingOccurrences(of: codeLengthReplacement, with: String(codeLength.rawValue))
                text = text.replacingOccurrences(of: emailReplacement, with: loginId)
                return text
            }
            self.emailSentTextChangedClosure = emailSentTextChangedClosure
            _emailSentText = State(initialValue: emailSentTextChangedClosure())
        }
        
        @ViewBuilder
        private func didNotGetEmail() -> some View {
            if store.value.isDisplayingDidNotGetCode && !store.value.isCodeEnteringStarted {
                Button {
                    store.send(.emailIsNotRecieved)
                } label: {
                    Text(localizedKey: .didNotGetEmail)
                        .font(.system(size: Constants.didNotGetEmailFontSize))
                        .foregroundColor(OwnID.Colors.otpDidNotGetEmail)
                }
            }
        }
        
        func createContent() -> some View {
            return VStack {
                topSection()
                OwnID.UISDK.OTPTextFieldView(viewModel: viewModel)
                    .shake(animatableData: store.value.attempts)
                    .onChange(of: store.value.attempts) { newValue in
                        viewModel.resetCode()
                    }
                ZStack {
                    if store.value.isLoading {
                        OwnID.UISDK.SpinnerLoaderView(spinnerColor: visualConfig.loaderViewConfig.color,
                                                      spinnerBackgroundColor: visualConfig.loaderViewConfig.backgroundColor,
                                                      viewBackgroundColor: .clear)
                        .frame(width: Constants.spinnerSize, height: Constants.spinnerSize)
                    }
                    didNotGetEmail()
                }
                .frame(height: Constants.bottomViewHeight)
            }
            .frame(minWidth: 0, maxWidth: .infinity)
            .overlay(alignment: .topTrailing) {
                Button {
                    dismiss()
                } label: {
                    Image(Constants.closeImageName, bundle: .resourceBundle)
                }
                .padding(.trailing)
                .padding(.top)
            }
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
        private func topSection() -> some View {
            VStack {
                Text(localizedKey: .signInWithOneTimeCode)
                    .font(.system(size: Constants.titleFontSize))
                    .bold()
                    .padding(.bottom)
                    .padding(.trailing, Constants.titlePadding)
                    .padding(.leading, Constants.titlePadding)
                    .padding(.top, Constants.topPadding)
                Text(verbatim: emailSentText)
                    .multilineTextAlignment(.center)
                    .foregroundColor(OwnID.Colors.otpContentMessageColor)
                    .font(.system(size: Constants.messageFontSize))
                    .padding(.bottom)
                
                Text(localizedKey: .otpDescription)
                    .font(.system(size: Constants.messageFontSize))
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
