import Foundation
import AuthenticationServices

/// Designed to be used in plugin SDKs and emit all errors in single format.
public protocol PluginError: Swift.Error { }

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

public extension OwnID.CoreSDK {
    enum Error: Swift.Error {
        case flowCancelled(flow: FlowType)
        
        case unsecuredHttpPassed
        case redirectParameterFromURLCancelledOpeningSDK
        case notValidRedirectionURLOrNotMatchingFromConfiguration
        
        case localConfigIsNotPresent
        case dataIsMissing
        case emailMismatch
        case payloadMissing(underlying: String?)
        
        case requestNetworkFailed(underlying: URLError)
        case requestBodyEncodeFailed(underlying: Swift.Error)
        case requestResponseDecodeFailed(underlying: Swift.Error)
        case requestResponseIsEmpty

        //created spearate serverErrorWithCode because serverError produced unexpected EXC_BAD_ACCESS error
        case serverErrorWithCode(message: String, code: String)
        case serverError(serverError: ServerError)
        case plugin(underlying: PluginError)
        
        case authorizationManagerGeneralError(underlying: Swift.Error)
        case authorizationManagerCredintialsNotFoundOrCanlelledByUser(underlying: ASAuthorizationError)
        case authorizationManagerAuthError(underlying: Swift.Error)
        case authorizationManagerDataMissing
        case authorizationManagerUnknownAuthType
        
        case localizationManager(underlying: Swift.Error)
        case localizationDownloader(underlying: Swift.Error)
    }
}

extension OwnID.CoreSDK.Error: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .localConfigIsNotPresent:
            return "Local config is missing"
            
        case .unsecuredHttpPassed:
            return "Link uses HTTP. Only HTTPS supported"
            
        case .notValidRedirectionURLOrNotMatchingFromConfiguration:
            return "Error returning value from browser"

        case .requestBodyEncodeFailed,
                .requestResponseDecodeFailed,
                .requestResponseIsEmpty,
                .localizationDownloader:
            return "Error while performing request"
            
        case .requestNetworkFailed(let underlying):
            return underlying.localizedDescription

        case .plugin(let error):
            return error.localizedDescription
            
        case .serverError(let underlying):
            return underlying.error
            
        case .serverErrorWithCode(let message, _):
            return message
            
        case .dataIsMissing:
            return "Data is missing"
            
        case .flowCancelled(let flow):
            return "User canceled OwnID flow \(flow)"
            
        case let .payloadMissing(underlying):
            return "Payload missing \(String(describing: underlying))"
            
        case .redirectParameterFromURLCancelledOpeningSDK:
            return "In redirection URL \"redirect=false\" has been found and opening of SDK cancelled. This is most likely due to app has been opened in screensets mode."
            
        case .authorizationManagerAuthError,
                .authorizationManagerGeneralError,
                .authorizationManagerDataMissing,
                .authorizationManagerUnknownAuthType,
                .authorizationManagerCredintialsNotFoundOrCanlelledByUser:
            return "Error while performing action"
            
        case .localizationManager(underlying: let underlying):
            return underlying.localizedDescription
            
        case .emailMismatch:
            return "Email address mismatch. Email address during OwnID flow differs from email address during registration"
        }
    }
}

extension OwnID.CoreSDK.Error: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .unsecuredHttpPassed,
                .localConfigIsNotPresent,
                .notValidRedirectionURLOrNotMatchingFromConfiguration,
                .authorizationManagerAuthError,
                .authorizationManagerGeneralError,
                .authorizationManagerDataMissing,
                .authorizationManagerUnknownAuthType,
                .dataIsMissing,
                .flowCancelled,
                .redirectParameterFromURLCancelledOpeningSDK,
                .requestNetworkFailed,
                .plugin,
                .serverError,
                .serverErrorWithCode,
                .emailMismatch,
                .payloadMissing:
            return errorDescription ?? ""
            
        case .requestBodyEncodeFailed(underlying: let underlying):
            return "requestBodyEncodeFailed \(underlying)"
            
        case .requestResponseDecodeFailed(underlying: let underlying):
            return "requestResponseDecodeFailed \(underlying)"
            
        case .requestResponseIsEmpty:
            return "requestResponseIsEmpty"
            
        case .authorizationManagerCredintialsNotFoundOrCanlelledByUser(let underlying):
            return "authorizationManagerCredintialsNotFoundOrCanlelledByUser \(underlying)"
            
        case .localizationManager(underlying: let underlying):
            return "localizationManager \(underlying)"
            
        case .localizationDownloader(underlying: let underlying):
            return "localizationDownloader \(underlying)"
        }
    }
}
