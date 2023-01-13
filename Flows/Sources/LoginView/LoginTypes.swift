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
    
    struct LinkOnLoginConfiguration {
        public init(email: OwnID.CoreSDK.Email,
                    payload: OwnID.CoreSDK.Payload,
                    password: OwnID.FlowsSDK.Password) {
            self.email = email
            self.payload = payload
            self.password = password
        }
        
        public let email: OwnID.CoreSDK.Email
        public let password: OwnID.FlowsSDK.Password
        public let payload: OwnID.CoreSDK.Payload
    }
}

public protocol LoginPerformer {
    func login(payload: OwnID.CoreSDK.Payload, email: String) -> OwnID.LoginResultPublisher
}
