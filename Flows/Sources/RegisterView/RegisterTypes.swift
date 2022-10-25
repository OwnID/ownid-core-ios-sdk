import Combine
import Foundation

extension OwnID.FlowsSDK.RegisterError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .enteredEmailMismatch:
            return "Email does not match to email that is used for OwnID linking"
            
        case .emailIsMissing:
            return "No email provided"
        }
    }
}

public extension OwnID {
    typealias RegistrationPublisher = OwnID.FlowsSDK.RegistrationPublisher
}

public extension OwnID.FlowsSDK {
    
    enum RegisterError: PluginError {
        case enteredEmailMismatch
        case emailIsMissing
    }
    
    enum RegistrationEvent {
        case loading
        case resetTapped
        case readyToRegister(usersEmailFromWebApp: String?)
        case userRegisteredAndLoggedIn(registrationResult: OperationResult)
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
    func register(configuration: OwnID.FlowsSDK.RegistrationConfiguration, parameters: RegisterParameters) -> AnyPublisher<OperationResult, OwnID.CoreSDK.Error>
}
