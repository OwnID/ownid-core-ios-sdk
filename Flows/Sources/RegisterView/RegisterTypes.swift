import Combine
import Foundation

extension OwnID.FlowsSDK.RegisterError: LocalizedError {
    public var errorDescription: String? {
        switch self {
            
        case .emailIsMissing:
            return "No email provided"
        }
    }
}

public extension OwnID {
    typealias RegistrationPublisher = OwnID.FlowsSDK.RegistrationPublisher
    struct RegisterResult {
        public init(operationResult: OperationResult, authType: OwnID.CoreSDK.AuthType?) {
            self.operationResult = operationResult
            self.authType = authType
        }
        
        let operationResult: OperationResult
        let authType: OwnID.CoreSDK.AuthType?
    }
}

public extension OwnID.FlowsSDK {
    
    enum RegisterError: PluginError {
        case emailIsMissing
    }
    
    enum RegistrationEvent {
        case loading
        case resetTapped
        case readyToRegister(usersEmailFromWebApp: String?, authType: OwnID.CoreSDK.AuthType?)
        case userRegisteredAndLoggedIn(registrationResult: OperationResult, authType: OwnID.CoreSDK.AuthType?)
    }
    
    typealias RegistrationPublisher = AnyPublisher<Result<RegistrationEvent, OwnID.CoreSDK.Error>, Never>
    
    struct RegistrationConfiguration {
        public init(payload: OwnID.CoreSDK.Payload,
                    email: OwnID.CoreSDK.Email) {
            self.payload = payload
            self.email = email
        }
        
        public let payload: OwnID.CoreSDK.Payload
        public let email: OwnID.CoreSDK.Email
    }
}

public protocol OperationResult { }

public struct VoidOperationResult: OperationResult {
    public init () { }
}

public protocol RegistrationPerformer {
    func register(configuration: OwnID.FlowsSDK.RegistrationConfiguration, parameters: RegisterParameters) -> AnyPublisher<OwnID.RegisterResult, OwnID.CoreSDK.Error>
}
