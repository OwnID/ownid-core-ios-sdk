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
        case localConfigIsNotPresent
        case tokenDataIsMissing
        case contextIsMissing
        case flowCancelled
        case emailMismatch
        case payloadMissing(underlying: String?)
        
        case initRequestNetworkFailed(underlying: URLError)
        case initRequestBodyEncodeFailed(underlying: Swift.Error)
        case initRequestResponseDecodeFailed(underlying: Swift.Error)
        case initRequestResponseIsEmpty
        
        case authRequestResponseIsEmpty
        case authRequestTypeIsMissing
        case authRequestResponseContextMismatch
        case authRequestResponseDecodeFailed(underlying: Swift.Error)
        case authRequestNetworkFailed(underlying: URLError)
        case authRequestBodyEncodeFailed(underlying: Swift.Error)
        
        case settingRequestResponseNotCompliantResponse
        case settingRequestResponseIsEmpty
        case settingRequestResponseDecodeFailed(underlying: Swift.Error)
        case settingRequestNetworkFailed(underlying: URLError)
        case settingRequestBodyEncodeFailed(underlying: Swift.Error)
        
        case statusRequestNetworkFailed(underlying: URLError)
        case statusRequestBodyEncodeFailed(underlying: Swift.Error)
        case statusRequestResponseDecodeFailed(underlying: Swift.Error)
        case statusRequestResponseIsEmpty
        case statusRequestFail(underlying: Swift.Error)
        
        case statusRequestTypeIsMissing
        case statusRequestResponseContextMismatch
        case serverError(serverError: ServerError)
        case plugin(underlying: PluginError)
        
        case authorizationManagerGeneralError(underlying: Swift.Error)
        case authorizationManagerCredintialsNotFoundOrCanlelledByUser(underlying: ASAuthorizationError)
        case authorizationManagerAuthError(userInfo: [String : Any])
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
            
        case .emailIsInvalid:
            return "The email address is badly formatted"
            
        case .initRequestBodyEncodeFailed,
                .settingRequestResponseIsEmpty,
                .initRequestResponseDecodeFailed,
                .initRequestResponseIsEmpty,
                .statusRequestBodyEncodeFailed,
                .statusRequestResponseDecodeFailed,
                .authRequestResponseDecodeFailed,
                .statusRequestResponseIsEmpty,
                .authRequestResponseIsEmpty,
                .statusRequestFail,
                .authRequestResponseContextMismatch,
                .statusRequestResponseContextMismatch,
                .tokenDataIsMissing,
                .authRequestBodyEncodeFailed,
                .localizationDownloader,
                .statusRequestTypeIsMissing,
                .authRequestTypeIsMissing,
                .settingRequestResponseDecodeFailed,
                .settingRequestNetworkFailed,
                .settingRequestBodyEncodeFailed,
                .settingRequestResponseNotCompliantResponse:
            return "Error while performing request"
            
        case .initRequestNetworkFailed(let underlying),
                .statusRequestNetworkFailed(let underlying),
                .authRequestNetworkFailed(let underlying):
            return underlying.localizedDescription

        case .plugin(let error):
            return error.localizedDescription
            
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
                .emailIsInvalid,
                .authorizationManagerAuthError,
                .authorizationManagerGeneralError,
                .authorizationManagerDataMissing,
                .authorizationManagerUnknownAuthType,
                .contextIsMissing,
                .flowCancelled,
                .redirectParameterFromURLCancelledOpeningSDK,
                .initRequestNetworkFailed,
                .statusRequestNetworkFailed,
                .authRequestNetworkFailed,
                .plugin,
                .serverError,
                .emailMismatch,
                .payloadMissing:
            return errorDescription ?? ""
            
        case .tokenDataIsMissing:
            return "tokenDataIsMissing"
            
        case .initRequestBodyEncodeFailed(underlying: let underlying):
            return "initRequestBodyEncodeFailed \(underlying)"
            
        case .initRequestResponseDecodeFailed(underlying: let underlying):
            return "initRequestResponseDecodeFailed \(underlying)"
            
        case .initRequestResponseIsEmpty:
            return "initRequestResponseIsEmpty"
            
        case .authRequestResponseIsEmpty:
            return "authRequestResponseIsEmpty"
            
        case .authRequestResponseDecodeFailed(underlying: let underlying):
            return "authRequestResponseDecodeFailed \(underlying)"
            
        case .authRequestBodyEncodeFailed(underlying: let underlying):
            return "authRequestBodyEncodeFailed \(underlying)"
            
        case .settingRequestResponseNotCompliantResponse:
            return "settingRequestResponseNotCompliantResponse"
            
        case .settingRequestResponseIsEmpty:
            return "settingRequestResponseIsEmpty"
            
        case .settingRequestResponseDecodeFailed(underlying: let underlying):
            return "settingRequestResponseDecodeFailed \(underlying)"
            
        case .settingRequestNetworkFailed(underlying: let underlying):
            return "settingRequestNetworkFailed \(underlying)"
            
        case .settingRequestBodyEncodeFailed(underlying: let underlying):
            return "settingRequestBodyEncodeFailed \(underlying)"
            
        case .statusRequestBodyEncodeFailed(underlying: let underlying):
            return "statusRequestBodyEncodeFailed \(underlying)"
            
        case .statusRequestResponseDecodeFailed(underlying: let underlying):
            return "statusRequestResponseDecodeFailed \(underlying)"
            
        case .statusRequestResponseIsEmpty:
            return "statusRequestResponseIsEmpty"
            
        case .statusRequestFail(underlying: let underlying):
            return "statusRequestFail \(underlying)"
            
        case .statusRequestTypeIsMissing:
            return "statusRequestTypeIsMissing"
            
        case .authRequestTypeIsMissing:
            return "authRequestTypeIsMissing"
            
        case .statusRequestResponseContextMismatch:
            return "statusRequestResponseContextMismatch"
            
        case .authRequestResponseContextMismatch:
            return "authRequestResponseContextMismatch"
            
        case .authorizationManagerCredintialsNotFoundOrCanlelledByUser(let underlying):
            return "authorizationManagerCredintialsNotFoundOrCanlelledByUser \(underlying)"
            
        case .localizationManager(underlying: let underlying):
            return "localizationManager \(underlying)"
            
        case .localizationDownloader(underlying: let underlying):
            return "localizationDownloader \(underlying)"
        }
    }
}
