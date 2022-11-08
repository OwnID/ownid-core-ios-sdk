import Combine

public extension OwnID {
    typealias LoginPublisher = OwnID.FlowsSDK.LoginPublisher
    struct LoginResult {
        public init(operationResult: OperationResult, authType: OwnID.CoreSDK.AuthType?) {
            self.operationResult = operationResult
            self.authType = authType
        }
        
        let operationResult: OperationResult
        let authType: OwnID.CoreSDK.AuthType?
    }
}

public extension OwnID.FlowsSDK {
    enum LoginEvent {
        case loading
        case loggedIn(loginResult: OperationResult, authType: OwnID.CoreSDK.AuthType?)
    }
    
    typealias LoginPublisher = AnyPublisher<Result<LoginEvent, OwnID.CoreSDK.Error>, Never>
    
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
    func login(payload: OwnID.CoreSDK.Payload,
               email: String) -> AnyPublisher<OwnID.LoginResult, OwnID.CoreSDK.Error>
}
