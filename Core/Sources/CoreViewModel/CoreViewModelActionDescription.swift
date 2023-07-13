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
        case .idCollect:
            return "idCollect"
        case .webApp:
            return "webApp"
        case .fido2Authorize:
            return "fido2Authorize"
        case .error(let error):
            return "error \(error.localizedDescription)"
        case .sendStatusRequest:
            return "sendStatusRequest"
        case .statusRequestLoaded:
            return "statusRequestLoaded"
        case .browserVM:
            return "browserVM"
        case .success:
            return "success"
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
        case .oneTimePasswordView:
            return "oneTimePasswordView"
        case .idCollectView:
            return "idCollectView"
        case .codeResent:
            return "codeResent"
        case .stopRequestLoaded:
            return "stopRequestLoaded"
        case .sameStep:
            return "sameStep"
        }
    }
}
