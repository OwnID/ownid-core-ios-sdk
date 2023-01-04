import Foundation

extension OwnID.CoreSDK.ViewModelAction: CustomDebugStringConvertible {
    var debugDescription: String {
        switch self {
        case .addToState:
            return "addToState"
        case .sendInitialRequest:
            return "sendInitialRequest"
        case .initialRequestLoaded:
            return "initialRequestLoaded"
        case .browserURLCreated:
            return "browserURLCreated"
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
        case .settingsRequestLoaded:
            return "settingsRequestLoaded"
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
        }
    }
}
