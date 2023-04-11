import Foundation

extension OwnID.CoreSDK.CoreViewModel.Action: CustomDebugStringConvertible {
    var debugDescription: String {
        switch self {
        case .oneTimePassword:
            return "oneTimePassword"
        case .addToState:
            return "addToState"
        case .sendInitialRequest:
            return "sendInitialRequest"
        case .initialRequestLoaded:
            return "initialRequestLoaded"
        case .error(let error):
            return "error \(error.localizedDescription)"
        case .sendStatusRequest:
            return "sendStatusRequest"
        case .browserCancelled:
            return "browserCancelled"
        case .statusRequestLoaded:
            return "statusRequestLoaded"
        case .browserVM:
            return "browserVM"
        case .authRequestLoaded:
            return "authRequestLoaded"
        case .authManager(let action):
            return "authManagerAction \(action.debugDescription)"
        case .authManagerCancelled:
            return "authManagerCancelled"
        case .addToStateConfig:
            return "addToStateConfig"
        case .addToStateShouldStartInitRequest:
            return "addToStateShouldStartInitRequest"
        case .cancelled:
            return "cancelled"
        case .addErrorToInternalStates(let error):
            let message = "addErrorToInternalStates " + error.localizedDescription + " " + error.debugDescription
            return message
        case .authManagerRequestFail(let error, _):
            return "authManagerRequestFail \(error.error.localizedDescription)"
        case .oneTimePasswordCancelled:
            return "oneTimePasswordCancelled"
        case .oneTimePasswordView:
            return "oneTimePasswordView"
        }
    }
}
