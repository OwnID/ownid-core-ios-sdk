import Foundation
import Combine

public extension OwnID.CoreSDK {
    enum Auth {}
}

public extension OwnID.CoreSDK.Auth {
    struct RequestBody: Encodable {
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(type, forKey: .type)
            try container.encode(context, forKey: .context)
            try container.encode(nonce, forKey: .nonce)
            if let fido2Payload = fido2Payload as? OwnID.CoreSDK.Fido2LoginPayload {
                try container.encode(fido2Payload, forKey: .fido2Payload)
            }
            if let fido2Payload = fido2Payload as? OwnID.CoreSDK.Fido2RegisterPayload {
                try container.encode(fido2Payload, forKey: .fido2Payload)
            }
        }
        
        let type: OwnID.CoreSDK.RequestType
        let context: OwnID.CoreSDK.Context
        let nonce: OwnID.CoreSDK.Nonce
        let fido2Payload: Encodable
        
        enum CodingKeys: CodingKey {
            case type
            case context
            case nonce
            case sessionVerifier
            case fido2Payload
        }
    }
}

extension OwnID.CoreSDK.Auth {
    class Request {
        let type: OwnID.CoreSDK.RequestType
        let url: OwnID.CoreSDK.ServerURL
        let provider: APIProvider
        let context: OwnID.CoreSDK.Context
        let nonce: OwnID.CoreSDK.Nonce
        var fido2LoginPayload: Encodable
        let supportedLanguages: OwnID.CoreSDK.Languages
        
        internal init(type: OwnID.CoreSDK.RequestType,
                      url: OwnID.CoreSDK.ServerURL,
                      context: OwnID.CoreSDK.Context,
                      nonce: OwnID.CoreSDK.Nonce,
                      fido2LoginPayload: Encodable,
                      supportedLanguages: OwnID.CoreSDK.Languages,
                      provider: APIProvider = URLSession.shared) {
            self.type = type
            self.url = url
            self.provider = provider
            self.supportedLanguages = supportedLanguages
            self.context = context
            self.nonce = nonce
            self.fido2LoginPayload = fido2LoginPayload
        }
        
        func perform() -> AnyPublisher<OwnID.CoreSDK.Payload, OwnID.CoreSDK.CoreErrorLogWrapper> {
            let inputPublisher = Just(RequestBody(type: type,
                             context: context,
                             nonce: nonce,
                             fido2Payload: fido2LoginPayload))
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
                .encode(encoder: JSONEncoder())
                .mapError { [self] in OwnID.CoreSDK.CoreErrorLogWrapper.coreLog(entry: .errorEntry(context: context, Self.self), error: .authRequestBodyEncodeFailed(underlying: $0)) }
                .map { [self] body -> URLRequest in
                    URLRequest.defaultPostRequest(url: url, body: body, supportedLanguages: supportedLanguages)
                }
                .eraseToAnyPublisher()
            let dataParsingPublisher = OwnID.CoreSDK.EndOfFlowHandler.handle(inputPublisher: inputPublisher.eraseToAnyPublisher(),
                                                                             context: context,
                                                                             nonce: nonce,
                                                                             requestLanguage: supportedLanguages.rawValue.first,
                                                                             provider: provider,
                                                                             shouldIgnoreResponseBody: true,
                                                                             emptyResponseError: { .authRequestResponseIsEmpty },
                                                                             typeMissingError: { .authRequestTypeIsMissing },
                                                                             contextMismatchError: { .authRequestResponseContextMismatch },
                                                                             networkFailError: { .authRequestNetworkFailed(underlying: $0) })
            return dataParsingPublisher.eraseToAnyPublisher()
        }
    }
}
