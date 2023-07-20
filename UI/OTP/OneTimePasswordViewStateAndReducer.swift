import Foundation
import Combine

extension OwnID.UISDK {
    enum OneTimePassword { }
}

extension OwnID.UISDK.OneTimePassword {
    struct ViewState: LoggingEnabled {
        let isLoggingEnabled: Bool
        let type: OwnID.CoreSDK.RequestType
        var error: OwnID.CoreSDK.UserErrorModel?
        var isLoading = false
        var isDisplayingDidNotGetCode = false
        var isFlowFinished = false
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
        case error(OwnID.CoreSDK.UserErrorModel, flowFinished: Bool)
        case success
        case stopLoading
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
        case .error(let errorModel, let flowFinished):
            state.isLoading = false
            state.isFlowFinished = flowFinished
            if errorModel.code == .invalidCode {
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                state.attempts += 1
            } else {
                state.error = errorModel
            }
            return []
        case .success:
            state.isLoading = false
            OwnID.UISDK.PopupManager.dismissPopup()
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
