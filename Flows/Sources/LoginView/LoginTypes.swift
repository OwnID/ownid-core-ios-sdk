import Combine

public extension OwnID {
    typealias LoginPublisher = AnyPublisher<Result<OwnID.FlowsSDK.LoginEvent, OwnID.CoreSDK.Error>, Never>
    typealias LoginResultPublisher = AnyPublisher<OwnID.LoginResult, OwnID.CoreSDK.CoreErrorLogWrapper>
    
    struct LoginResult {
        public init(operationResult: OperationResult, authType: OwnID.CoreSDK.AuthType? = .none) {
            self.operationResult = operationResult
            self.authType = authType
        }
        
        public let operationResult: OperationResult
        public let authType: OwnID.CoreSDK.AuthType?
    }
}

public extension OwnID.FlowsSDK {
    enum LoginEvent {
        case loading
        case loggedIn(loginResult: OperationResult, authType: OwnID.CoreSDK.AuthType?)
    }
}

public protocol LoginPerformer {
    func login(payload: OwnID.CoreSDK.Payload, loginId: String) -> OwnID.LoginResultPublisher
}
