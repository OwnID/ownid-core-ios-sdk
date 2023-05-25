import Foundation
import Combine

extension OwnID.UISDK.OneTimePassword {
    enum CodeLength: Int {
        case six = 6
        case four = 4
    }
}
extension OwnID.UISDK {
    enum OneTimePassword { }
}

extension OwnID.UISDK.OneTimePassword {
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
    
    struct ViewState: LoggingEnabled {
        let isLoggingEnabled: Bool
        var isLoading = false
        var isDisplayingDidNotGetCode = false
        var attempts = 0
    }
    
    enum Action {
        case viewLoaded
        case codeEntered(String)
        case cancel
        case cancelCodeOperation
        case emailIsNotRecieved
        case codeRestarted
        case displayDidNotGetCode
        case nonTerminalError
        case error
        case success
        case stopLoading
    }
}

extension OwnID.UISDK.OneTimePassword {
    static func viewModelReducer(state: inout OwnID.UISDK.OneTimePassword.ViewState, action: OwnID.UISDK.OneTimePassword.Action) -> [Effect<OwnID.UISDK.OneTimePassword.Action>] {
        switch action {
        case .viewLoaded:
            return [Just(OwnID.UISDK.OneTimePassword.Action.displayDidNotGetCode)
                .delay(for: 10, scheduler: DispatchQueue.main)
                .eraseToEffect()]
        case .codeRestarted:
            return []
        case .codeEntered:
            if state.isLoading {
                return [Just(.stopLoading).eraseToEffect(),
                        Just(OwnID.UISDK.OneTimePassword.Action.cancelCodeOperation).eraseToEffect()]
            }
            state.isLoading = true
            return []
        case .cancel:
            return [Just(.stopLoading) .eraseToEffect()]
            
        case .emailIsNotRecieved:
            return [Just(.stopLoading) .eraseToEffect()]
            
        case .cancelCodeOperation:
            return []
        case .nonTerminalError:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            state.attempts += 1
            return [
                Just(.stopLoading)
                    .delay(for: 1, scheduler: DispatchQueue.main)
                    .eraseToEffect()
            ]
        case .error:
            state.isLoading = false
            OwnID.UISDK.PopupManager.dismiss()
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
        case .codeRestarted:
            return "codeRestarted"
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
