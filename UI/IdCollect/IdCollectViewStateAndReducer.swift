import Foundation
import Combine

extension OwnID.UISDK.IdCollect {
    struct ViewState: LoggingEnabled {
        var isLoggingEnabled: Bool
        var isLoading = false
        var isError = false
    }
    
    enum Action {
        case viewLoaded
        case cancel
        case loginIdEntered(loginId: String)
        case error
    }
}

extension OwnID.UISDK.IdCollect {
    static func viewModelReducer(state: inout ViewState, action: Action) -> [Effect<Action>] {
        switch action {
        case .viewLoaded:
            state.isError = false
            state.isLoading = false
            return []
        case .cancel:
            return []
        case .loginIdEntered:
            state.isLoading = true
            state.isError = false
            return []
        case .error:
            state.isError = true
            state.isLoading = false
            return []
        }
    }
}

@available(iOS 15.0, *)
extension OwnID.UISDK.IdCollect.Action: CustomDebugStringConvertible {
    var debugDescription: String {
        switch self {
        case .viewLoaded:
            return "viewLoaded"
        case .cancel:
            return "cancel"
        case .loginIdEntered(let loginId):
            return "loginIdEntered \(loginId)"
        case .error:
            return "error"
        }
    }
}
