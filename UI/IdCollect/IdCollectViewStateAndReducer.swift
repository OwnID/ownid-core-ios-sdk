import Foundation
import Combine

extension OwnID.UISDK.IdCollect {
    struct ViewState: LoggingEnabled {
        var isLoggingEnabled: Bool
        var isLoading = false
    }
    
    enum Action {
        case cancel
        case loginIdEntered(loginId: String)
        case error
    }
}

extension OwnID.UISDK.IdCollect {
    static func viewModelReducer(state: inout ViewState, action: Action) -> [Effect<Action>] {
        switch action {
        case .cancel:
            return []
        case .loginIdEntered:
            var isLoading = true
            return []
        case .error:
            var isLoading = false
            OwnID.UISDK.PopupManager.dismiss()
            return []
        }
    }
}

@available(iOS 15.0, *)
extension OwnID.UISDK.IdCollect.Action: CustomDebugStringConvertible {
    var debugDescription: String {
        switch self {
        case .cancel:
            return "cancel"
        case .loginIdEntered(let loginId):
            return "loginIdEntered \(loginId)"
        case .error:
            return "error"
        }
    }
}
