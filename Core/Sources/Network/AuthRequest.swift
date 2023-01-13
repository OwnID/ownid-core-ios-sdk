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
            if type == .register {
                try container.encode(sessionVerifier, forKey: .sessionVerifier)
            }
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
        let sessionVerifier: OwnID.CoreSDK.SessionVerifier
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
        let sessionVerifier: OwnID.CoreSDK.SessionVerifier
        var fido2LoginPayload: Encodable
        let webLanguages: OwnID.CoreSDK.Languages
        let origin: String
        let shouldIgnoreResponseBody: Bool
        
        internal init(type: OwnID.CoreSDK.RequestType,
                      url: OwnID.CoreSDK.ServerURL,
                      context: OwnID.CoreSDK.Context,
                      nonce: OwnID.CoreSDK.Nonce,
                      origin: String,
                      sessionVerifier: OwnID.CoreSDK.SessionVerifier,
                      fido2LoginPayload: Encodable,
                      webLanguages: OwnID.CoreSDK.Languages,
                      shouldIgnoreResponseBody: Bool,
                      provider: APIProvider = URLSession.shared) {
            self.type = type
            self.url = url
            self.provider = provider
            self.webLanguages = webLanguages
            self.context = context
            self.nonce = nonce
            self.sessionVerifier = sessionVerifier
            self.fido2LoginPayload = fido2LoginPayload
            self.origin = origin
            self.shouldIgnoreResponseBody = shouldIgnoreResponseBody
        }
        
        func perform() -> AnyPublisher<OwnID.CoreSDK.Payload, OwnID.CoreSDK.CoreErrorLogWrapper> {
            let inputPublisher = Just(RequestBody(type: type,
                             context: context,
                             nonce: nonce,
                             sessionVerifier: sessionVerifier,
                             fido2Payload: fido2LoginPayload))
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
                .encode(encoder: JSONEncoder())
                .mapError { [self] in OwnID.CoreSDK.CoreErrorLogWrapper.coreLog(entry: .errorEntry(context: context, Self.self), error: .authRequestBodyEncodeFailed(underlying: $0)) }
                .map { [self] body -> URLRequest in
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.httpBody = body
                    request.addUserAgent()
                    request.addAPIVersion()
                    request.add(origin: origin)
                    request.add(webLanguages: webLanguages)
                    return request
                }
                .eraseToAnyPublisher()
            let dataParsingPublisher = OwnID.CoreSDK.EndOfFlowHandler.handle(inputPublisher: inputPublisher.eraseToAnyPublisher(),
                                                                             context: context,
                                                                             nonce: nonce,
                                                                             requestLanguage: webLanguages.rawValue.first,
                                                                             provider: provider,
                                                                             shouldIgnoreResponseBody: shouldIgnoreResponseBody,
                                                                             emptyResponseError: { .authRequestResponseIsEmpty },,
                                                                             typeMissingError: { .authRequestTypeIsMissing }, networkFailError: { .authRequestNetworkFailed(underlying: $0) })
            return dataParsingPublisher.eraseToAnyPublisher()
        }
    }
}
