import Combine
import Foundation

extension OwnID.FlowsSDK.RegisterError: LocalizedError {
    public var errorDescription: String? {
        switch self {
            
        case .emailMismatch:
            return "Email changed before registration"
        }
    }
}

public extension OwnID {
    typealias RegistrationPublisher = AnyPublisher<Result<OwnID.FlowsSDK.RegistrationEvent, OwnID.CoreSDK.Error>, Never>
    typealias RegistrationResultPublisher = AnyPublisher<OwnID.RegisterResult, OwnID.CoreSDK.CoreErrorLogWrapper>
    
    struct RegisterResult {
        public init(operationResult: OperationResult, authType: OwnID.CoreSDK.AuthType? = .none) {
            self.operationResult = operationResult
            self.authType = authType
        }
        
        public let operationResult: OperationResult
        public let authType: OwnID.CoreSDK.AuthType?
    }
}

public extension OwnID.FlowsSDK {
    
    enum RegisterError: PluginError {
        case emailMismatch
    }
    
    enum RegistrationEvent {
        case loading
        case resetTapped
        case readyToRegister(usersEmailFromWebApp: String?, authType: OwnID.CoreSDK.AuthType?)
        case userRegisteredAndLoggedIn(registrationResult: OperationResult, authType: OwnID.CoreSDK.AuthType?)
    }
    
    
    struct RegistrationConfiguration {
        public init(payload: OwnID.CoreSDK.Payload,
                    loginId: String) {
            self.payload = payload
            self.loginId = loginId
        }
        
        public let payload: OwnID.CoreSDK.Payload
        public let loginId: String
    }
}

public protocol OperationResult { }

public struct VoidOperationResult: OperationResult {
    public init () { }
}

public protocol RegistrationPerformer {
    func register(configuration: OwnID.FlowsSDK.RegistrationConfiguration, parameters: RegisterParameters) -> OwnID.RegistrationResultPublisher
}
