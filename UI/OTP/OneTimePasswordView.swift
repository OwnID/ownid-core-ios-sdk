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
            let operationType: OwnID.UISDK.OneTimePassword.OperationType = type == .loginIDAuthorization ? .oneTimePasswordSignIn : .verification
            let view = OwnID.UISDK.OneTimePassword.OneTimePasswordView(store: store,
                                                                       visualConfig: PopupManager.shared.visualLookConfig,
                                                                       loginId: loginId,
                                                                       codeLength: otpLength,
                                                                       restartURL: restartUrl,
                                                                       operationType: operationType,
                                                                       verificationType: verificationType)
            view.presentAsPopup()
        }
    }
}

extension OwnID.UISDK.OneTimePassword {
    enum OperationType: String {
        case verification = "verify"
        case oneTimePasswordSignIn = "sign"
    }
    
    @available(iOS 15.0, *)
    struct OneTimePasswordView: Popup {
        static func == (lhs: OwnID.UISDK.OneTimePassword.OneTimePasswordView, rhs: OwnID.UISDK.OneTimePassword.OneTimePasswordView) -> Bool {
            lhs.uuid == rhs.uuid
        }
        
        private enum Constants {
            static let padding = 26.0
            static let closeTopPadding = 12.0
            static let closeTrailingPadding = 10.0
            static let titleTopPadding = 8.0
            static let titleBottomPadding = 16.0
            static let messageBottomPadding = 20.0
            static let descriptionBottomPadding = 12.0
            static let notYouPadding = 8.0
            
            static let spinnerSize = 28.0
            static let resendLoadingSize = 32.0
            static let errorViewHeight = 28.0
            static let errorViewCornerRadius = 4.0
            
            static let titleFontSize = 20.0
            static let messageFontSize = 16.0
            static let buttonFontSize = 14.0
            static let errorFontSize = 12.0
            
            static let closeImageName = "closeImage"
            static let codeLengthReplacement = "%CODE_LENGTH%"
            static let emailReplacement = "%LOGIN_ID%"
        }
        
        private let uuid = UUID().uuidString
        
        private let viewModel: OwnID.UISDK.OTPTextFieldView.ViewModel
        private var visualConfig: OwnID.UISDK.OTPViewConfig
        @ObservedObject var store: Store<ViewState, Action>
        private let codeLength: Int
        private let operationType: OperationType
        private let restartURL: URL
        private let verificationType: OwnID.CoreSDK.Verification.VerificationType

        @State private var emailSentText: String
        private let emailSentTextChangedClosure: (() -> String)
        @State private var isTranslationChanged = false
        
        private var cancel: String {
            OwnID.CoreSDK.TranslationsSDK.TranslationKey.stepsCancel.localized()
        }
        
        init(store: Store<ViewState, Action>,
             visualConfig: OwnID.UISDK.OTPViewConfig,
             loginId: String,
             codeLength: Int,
             restartURL: URL,
             operationType: OperationType = .oneTimePasswordSignIn,
             verificationType: OwnID.CoreSDK.Verification.VerificationType) {
            self.visualConfig = visualConfig
            self.store = store
            self.codeLength = codeLength
            self.restartURL = restartURL
            self.viewModel = OwnID.UISDK.OTPTextFieldView.ViewModel(codeLength: codeLength, store: store)
            self.verificationType = verificationType
            self.operationType = operationType
            
            let emailSentTextChangedClosure = {
                var text = OwnID.CoreSDK.TranslationsSDK.TranslationKey.otpMessage(operationType: operationType.rawValue,
                                                                                   verificationType: verificationType.rawValue).localized()
                let codeLengthReplacement = Constants.codeLengthReplacement
                let emailReplacement = Constants.emailReplacement
                text = text.replacingOccurrences(of: codeLengthReplacement, with: String(codeLength))
                text = text.replacingOccurrences(of: emailReplacement, with: loginId)
                return text
            }
            self.emailSentTextChangedClosure = emailSentTextChangedClosure
            _emailSentText = State(initialValue: emailSentTextChangedClosure())
        }
        
        @ViewBuilder
        private func resendView() -> some View {
            if store.value.isDisplayingDidNotGetCode && !store.value.isLoading && store.value.error == nil {
                Button {
                    store.send(.resendCode)
                } label: {
                    Text(localizedKey: .otpResend(operationType: operationType.rawValue, verificationType: verificationType.rawValue))
                        .font(.system(size: Constants.buttonFontSize))
                        .bold()
                        .foregroundColor(OwnID.Colors.blue)
                }
            }
        }
        
        private func notYouView() -> some View {
            Button {
                store.send(.emailIsNotRecieved)
            } label: {
                Text(localizedKey: .otpNotYou(operationType: operationType.rawValue, verificationType: verificationType.rawValue))
                    .font(.system(size: Constants.buttonFontSize))
                    .bold()
                    .foregroundColor(OwnID.Colors.blue)
            }
        }
        
        @ViewBuilder
        private func errorView() -> some View {
            if store.value.error?.code == .general {
                Text(localizedKey: .stepsError)
                    .font(.system(size: Constants.errorFontSize))
                    .frame(maxWidth: .infinity)
                    .frame(height: Constants.errorViewHeight)
                    .foregroundColor(.white)
                    .background(RoundedRectangle(cornerRadius: Constants.errorViewCornerRadius))
            }
        }
        
        @ViewBuilder
        private func errorText() -> some View {
            if store.value.error?.code == .wrongCodeLimitReached, let message = store.value.error?.message {
                HStack {
                    Text(message)
                        .font(.system(size: Constants.errorFontSize))
                        .multilineTextAlignment(.leading)
                        .foregroundColor(OwnID.Colors.errorColor)
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
                    resendView()
                    errorText()
                }
                .frame(height: Constants.resendLoadingSize)
                notYouView()
                    .padding([.top, .bottom], Constants.notYouPadding)
                errorView()
            }
            .frame(minWidth: 0, maxWidth: .infinity)
            .padding(.all, Constants.padding)
            .overlay(alignment: .topTrailing) {
                Button {
                    dismiss()
                } label: {
                    Image(Constants.closeImageName, bundle: .resourceBundle)
                }
                .modifier(AccessibilityLabelModifier(accessibilityLabel: cancel))
                .padding(.trailing, Constants.closeTrailingPadding)
                .padding(.top, Constants.closeTopPadding)
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
                Text(localizedKey: .otpTitle(operationType: operationType.rawValue, verificationType: verificationType.rawValue))
                    .font(.system(size: Constants.titleFontSize))
                    .bold()
                    .multilineTextAlignment(.center)
                    .padding(.top, Constants.titleTopPadding)
                    .padding(.bottom, Constants.titleBottomPadding)
                Text(verbatim: emailSentText)
                    .multilineTextAlignment(.center)
                    .foregroundColor(OwnID.Colors.popupContentMessageColor)
                    .font(.system(size: Constants.messageFontSize))
                    .padding(.bottom, Constants.messageBottomPadding)
                Text(localizedKey: .otpDescription(operationType: operationType.rawValue, verificationType: verificationType.rawValue))
                    .font(.system(size: Constants.messageFontSize))
                    .padding(.bottom, Constants.descriptionBottomPadding)
            }
            .overlay {
                if isTranslationChanged {
                    EmptyView()
                }
            }
        }
    }
}
