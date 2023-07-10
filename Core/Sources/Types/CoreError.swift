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
        case internalError(message: String)
        case usageError(message: String)
        case integrationError(underlying: Swift.Error)

        //created spearate serverErrorWithCode because serverError produced unexpected EXC_BAD_ACCESS error
        //TODO: change it in scope of KYIV-2356
        case serverErrorWithCode(message: String, code: String)
        case serverError(serverError: ServerError)
    }
}

extension OwnID.CoreSDK.Error: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .flowCancelled(let flow):
            return "User canceled OwnID flow \(flow)"
            
        case .internalError(let message):
            return message
            
        case .usageError(let message):
            return message

        case .integrationError(let error):
            return error.localizedDescription
            
        case .serverError(let underlying):
            return underlying.error
            
        case .serverErrorWithCode(let message, _):
            return message
            
        }
    }
}

extension OwnID.CoreSDK.Error: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .flowCancelled,
                .internalError,
                .usageError,
                .integrationError,
                .serverError,
                .serverErrorWithCode:
            return errorDescription ?? ""
        }
    }
}
