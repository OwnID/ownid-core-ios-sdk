import Foundation
import AuthenticationServices

/// Designed to be used in plugin SDKs and emit all errors in single format.
public protocol PluginError: Swift.Error { }

public extension OwnID.CoreSDK {
    enum Error: Swift.Error {
        case unsecuredHttpPassed
        case redirectParameterFromURLCancelledOpeningSDK
        case notValidRedirectionURLOrNotMatchingFromConfiguration
        case emailIsInvalid
        case tokenDataIsMissing
        case contextIsMissing
        case loadJWTTokenFailed(underlying: Swift.Error)
        case flowCancelled
        case payloadMissing(underlying: String?)
        
        case initRequestNetworkFailed(underlying: URLError)
        case initRequestBodyEncodeFailed(underlying: Swift.Error)
        case initRequestResponseDecodeFailed(underlying: Swift.Error)
        case initRequestResponseIsEmpty
        
        case authRequestResponseIsEmpty
        case authRequestResponseDecodeFailed(underlying: Swift.Error)
        case authRequestNetworkFailed(underlying: URLError)
        case authRequestBodyEncodeFailed(underlying: Swift.Error)
        
        case statusRequestNetworkFailed(underlying: URLError)
        case statusRequestBodyEncodeFailed(underlying: Swift.Error)
        case statusRequestResponseDecodeFailed(underlying: Swift.Error)
        case statusRequestResponseIsEmpty
        case statusRequestFail(underlying: Swift.Error)
        
        case statusRequestTypeIsMissing
        case statusRequestResponseContextMismatch
        case serverError(serverError: ServerError)
        case plugin(error: PluginError)
        
        case authorizationManagerGeneralError(error: Swift.Error)
        case authorizationManagerAuthError(userInfo: [String : Any])
        case authorizationManagerDataMissing
        case authorizationManagerUnknownAuthType
    }
}

extension OwnID.CoreSDK.Error: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .unsecuredHttpPassed:
            return "Link uses HTTP. Only HTTPS supported"
            
        case .notValidRedirectionURLOrNotMatchingFromConfiguration:
            return "Error returning value from browser"
            
        case .emailIsInvalid:
            return "The email address is badly formatted"
            
        case .initRequestBodyEncodeFailed,
             .initRequestResponseDecodeFailed,
             .initRequestResponseIsEmpty,
             .statusRequestBodyEncodeFailed,
             .statusRequestResponseDecodeFailed,
             .authRequestResponseDecodeFailed,
             .statusRequestResponseIsEmpty,
             .authRequestResponseIsEmpty,
             .statusRequestFail,
             .statusRequestResponseContextMismatch,
             .tokenDataIsMissing,
             .authRequestBodyEncodeFailed,
             .statusRequestTypeIsMissing:
            return "Error while performing request"
            
        case .initRequestNetworkFailed(let underlying),
                .statusRequestNetworkFailed(let underlying),
                .authRequestNetworkFailed(let underlying):
            return underlying.localizedDescription

        case .plugin(error: let error):
            return error.localizedDescription
            
        case .loadJWTTokenFailed(let underlying):
            return underlying.localizedDescription
            
        case .serverError(let underlying):
            return underlying.error
            
        case .contextIsMissing:
            return "Context is missing"
            
        case .flowCancelled:
            return "Flow cancelled"
            
        case let .payloadMissing(underlying):
            return "Payload missing \(String(describing: underlying))"
            
        case .redirectParameterFromURLCancelledOpeningSDK:
            return "In redirection URL \"redirect=false\" has been found and opening of SDK cancelled. This is most likely due to app has been opened in screensets mode."
            
        case .authorizationManagerAuthError,
                .authorizationManagerGeneralError,
                .authorizationManagerDataMissing,
                .authorizationManagerUnknownAuthType:
            return "Error while performing action"
        }
    }
}
