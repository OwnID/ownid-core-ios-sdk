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
            #warning("do we really need this here or server is just has bug? https://github.com/OwnID/multi-tenant-server/blob/develop/OwnID.MultiTenant.Core/Commands/Fido2/Passkeys/PasskeysFido2AuthCommand.cs#L75")
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

public extension OwnID.CoreSDK.Auth {
    struct Response: Decodable {
        public let status: String
        public let context: String
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
        
        internal init(type: OwnID.CoreSDK.RequestType,
                      url: OwnID.CoreSDK.ServerURL,
                      context: OwnID.CoreSDK.Context,
                      nonce: OwnID.CoreSDK.Nonce,
                      origin: String,
                      sessionVerifier: OwnID.CoreSDK.SessionVerifier,
                      fido2LoginPayload: Encodable,
                      webLanguages: OwnID.CoreSDK.Languages,
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
        }
        
        func perform() -> AnyPublisher<Response, OwnID.CoreSDK.Error> {
            Just(RequestBody(type: type,
                             context: context,
                             nonce: nonce,
                             sessionVerifier: sessionVerifier,
                             fido2Payload: fido2LoginPayload))
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
                .encode(encoder: JSONEncoder())
                .mapError { OwnID.CoreSDK.Error.authRequestBodyEncodeFailed(underlying: $0) }
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
                .flatMap { [self] request -> AnyPublisher<URLSession.DataTaskPublisher.Output, OwnID.CoreSDK.Error> in
                    provider.apiResponse(for: request)
                    .mapError { OwnID.CoreSDK.Error.authRequestNetworkFailed(underlying: $0) }
                    .eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
                .tryMap { response -> Data in
                    guard !response.data.isEmpty else { throw OwnID.CoreSDK.Error.authRequestResponseIsEmpty }
                    return response.data
                }
                .eraseToAnyPublisher()
                .decode(type: Response.self, decoder: JSONDecoder())
                .map { [weak self] decoded in
                    OwnID.CoreSDK.logger.logCore(.entry(context: self?.context, message: "Finished request", Self.self))
                    return decoded
                }
                .mapError { [weak self] topError in
                    OwnID.CoreSDK.logger.logCore(.errorEntry(context: self?.context, message: "\(topError.localizedDescription)", Self.self))
                    guard let error = topError as? OwnID.CoreSDK.Error else { return OwnID.CoreSDK.Error.authRequestResponseDecodeFailed(underlying: topError) }
                    return error
                }
                .eraseToAnyPublisher()
        }
    }
}
