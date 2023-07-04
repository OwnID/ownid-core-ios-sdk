import Foundation
import Combine

extension OwnID.UISDK {
    enum OneTimePassword { }
}

extension OwnID.UISDK.OneTimePassword {
    enum TitleType {
        case verification
        case oneTimePasswordSignIn
        
        func localizationKey(verificationType: OwnID.CoreSDK.Verification.VerificationType) -> OwnID.CoreSDK.TranslationsSDK.TranslationKey {
            switch self {
            case .verification:
                return .otpVerifyTitle(type: verificationType.rawValue)
                
            case .oneTimePasswordSignIn:
                return .otpSignTitle
            }
        }
    }
    
    struct ViewState: LoggingEnabled {
        let isLoggingEnabled: Bool
        let type: OwnID.CoreSDK.RequestType
        var error: Error?
        var isLoading = false
        var isDisplayingDidNotGetCode = false
        var attempts = 0
    }
    
    enum Action {
        case viewLoaded
        case codeEnteringStarted
        case codeEntered(String)
        case cancel
        case cancelCodeOperation
        case emailIsNotRecieved
        case resendCode
        case displayDidNotGetCode
        case nonTerminalError
        case error(message: String, code: String)
        case success
        case stopLoading
    }
    
    struct Error {
        let code: ErrorCode
        let message: String
    }
    
    enum ErrorCode: String {
        case general
        case wrongCodeLimitReached = "WrongCodeLimitReached"
    }
}

extension OwnID.UISDK.OneTimePassword {
    private enum Constants {
        static let didNotGetCodeDelay = 15.0
    }
    
    static func viewModelReducer(state: inout OwnID.UISDK.OneTimePassword.ViewState, action: OwnID.UISDK.OneTimePassword.Action) -> [Effect<OwnID.UISDK.OneTimePassword.Action>] {
        switch action {
        case .viewLoaded:
            state.isLoading = false
            state.isDisplayingDidNotGetCode = false
            state.error = nil
            
            return [Just(OwnID.UISDK.OneTimePassword.Action.displayDidNotGetCode)
                .delay(for: .seconds(Constants.didNotGetCodeDelay), scheduler: DispatchQueue.main)
                .eraseToEffect()]
        case .codeEnteringStarted:
            return []
        case .resendCode:
            return []
        case .codeEntered:
            if state.isLoading {
                return [Just(.stopLoading).eraseToEffect(),
                        Just(OwnID.UISDK.OneTimePassword.Action.cancelCodeOperation).eraseToEffect()]
            }
            state.error = nil
            state.isLoading = true
            return []
        case .cancel:
            return [Just(.stopLoading) .eraseToEffect()]
            
        case .emailIsNotRecieved:
            state.error = nil
            state.isLoading = true
            return []
            
        case .cancelCodeOperation:
            return []
        case .nonTerminalError:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            state.attempts += 1
            return [
                Just(.stopLoading)
                    .eraseToEffect()
            ]
        case .error(let messsage, let code):
            let errorCode = ErrorCode(rawValue: code) ?? .general
            state.error = Error(code: errorCode, message: messsage)
            state.isLoading = false
            return []
        case .success:
            state.isLoading = false
            OwnID.UISDK.PopupManager.dismiss()
            return []
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
extension OwnID.UISDK.OneTimePassword.Action: CustomDebugStringConvertible {
    var debugDescription: String {
        switch self {
        case .viewLoaded:
            return "viewLoaded"
        case .resendCode:
            return "resendCode"
        case .codeEnteringStarted:
            return "codeEnteringStarted"
        case .codeEntered(_):
            return "codeEntered"
        case .cancel:
            return "cancel"
        case .emailIsNotRecieved:
            return "emailIsNotRecieved"
        case .nonTerminalError:
            return "nonTerminalError"
        case .error:
            return "error"
        case .success:
            return "success"
        case .cancelCodeOperation:
            return "cancelCodeOperation"
        case .displayDidNotGetCode:
            return "displayDidNotGetCode"
        case .stopLoading:
            return "stopLoading"
        }
    }
}
