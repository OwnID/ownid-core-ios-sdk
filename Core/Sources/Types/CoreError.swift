import Foundation
import AuthenticationServices

public extension OwnID.CoreSDK {
    enum FlowType: String {
        case instantConnect = "InstantConnect"
        case idCollect = "IdCollect"
        case fidoRegister = "FIDORegister"
        case fidoLogin = "FIDOLogin"
        case otp = "OTP"
        case webApp = "WebApp"
    }
}

extension OwnID.CoreSDK {
    enum ErrorMessage {
        static let SDKConfigurationError = "No OwnID instance available. Check if OwnID instance created"
        static let redirectParameterFromURLCancelledOpeningSDK = "In redirection URL \"redirect=false\" has been found and opening of SDK cancelled. This is most likely due to app has been opened in screensets mode."
        static let notValidRedirectionURLOrNotMatchingFromConfiguration = "Error returning value from browser"
        static let noServerConfig = "No server configuration available"
        static let noLocalConfig = "No local configuration available"
        static let dataIsMissing = "Data is missing"
        static let payloadMissing = "Payload missing"
        static let emptyResponseData = "Response data is empty"
        static let requestError = "Error while performing action"
        
        static func encodingError(description: String) -> String {
            return "Encoding Failed \(description)"
        }
        
        static func decodingError(description: String) -> String {
            return "Decoding Failed \(description)"
        }
    }
}

public extension OwnID.CoreSDK {
    enum Error: Swift.Error {
        case flowCancelled(flow: FlowType)
        case integrationError(underlying: Swift.Error)
        case userError(errorModel: UserErrorModel)
    }
    
    struct UserErrorModel: Equatable {
        public let code: ErrorTypeCode
        public let message: String
        public let userMessage: String
    
        public init(code: String?, message: String?, userMessage: String?) {
            self.code = ErrorTypeCode(rawValue: code ?? "") ?? .unknown
            self.message = message ?? ""
            self.userMessage = userMessage ?? ""
        }
        
        public init(message: String) {
            self.message = message
            self.code = .unknown
            self.userMessage = OwnID.CoreSDK.TranslationsSDK.TranslationKey.stepsError.localized()
        }
        
        var isGeneralError: Bool {
            code == .unknown || code == .userAlreadyExists || code == .flowIsFinished
        }
    }
    
    enum ErrorTypeCode: String {
        case accountNotFound = "AccountNotFound"
        case requiresBiometricInput = "RequiresBiometricInput"
        case accountIsBlocked = "AccountIsBlocked"
        case userAlreadyExists = "UserAlreadyExists"
        case userNotFound = "UserNotFound"
        case wrongCodeLimitReached = "WrongCodeLimitReached"
        case flowIsFinished = "FlowIsFinished"
        case invalidCode = "WrongCodeEntered"
        case sendCodeLimitReached = "SendCodeLimitReached"
        case unknown
    }
}

extension OwnID.CoreSDK.Error: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .flowCancelled(let flow):
            return "User canceled OwnID flow \(flow)"

        case .integrationError(let error):
            return error.localizedDescription
            
        case .userError(let model):
            return model.userMessage
        }
    }
}

extension OwnID.CoreSDK.Error: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .flowCancelled,
                .integrationError,
                .userError:
            return errorDescription ?? ""
        }
    }
}
