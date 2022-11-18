import Foundation
import Combine

public extension OwnID.CoreSDK {
    enum Auth {}
}

public extension OwnID.CoreSDK.Auth {
    struct RequestBody: Encodable {
        let type: OwnID.CoreSDK.RequestType
        let context: OwnID.CoreSDK.Context
        let nonce: OwnID.CoreSDK.Nonce
        let sessionVerifier: OwnID.CoreSDK.SessionVerifier
        let fido2Payload: Fido2Payload
    }
//
//    struct Fido2PayloadRegister: Encodable {
//        var credentialId: String
//        var clientDataJSON: String
//        var attestationObject: String
//    }
    
    struct Fido2Payload: Encodable {
        var credentialId: String
        var clientDataJSON: String
        var authenticatorData: String
        var signature: String
    }
}

public extension OwnID.CoreSDK.Auth {
    struct Response: Decodable {
        public let url: String
        public let context: String?
        public let nonce: String?
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
        var fido2Payload: Fido2Payload
        let webLanguages: OwnID.CoreSDK.Languages
        
        internal init(type: OwnID.CoreSDK.RequestType,
                      url: OwnID.CoreSDK.ServerURL,
                      context: OwnID.CoreSDK.Context,
                      nonce: OwnID.CoreSDK.Nonce,
                      sessionVerifier: OwnID.CoreSDK.SessionVerifier,
                      fido2Payload: Fido2Payload = .init(credentialId: "", clientDataJSON: "", authenticatorData: "", signature: ""),
                      webLanguages: OwnID.CoreSDK.Languages,
                      provider: APIProvider = URLSession.shared) {
            self.type = type
            self.url = url
            self.provider = provider
            self.webLanguages = webLanguages
            self.context = context
            self.nonce = nonce
            self.sessionVerifier = sessionVerifier
            self.fido2Payload = fido2Payload
            print("override variables here for ")
        }
        
        func perform() -> AnyPublisher<Response, OwnID.CoreSDK.Error> {
            Just(RequestBody(type: type,
                             context: context,
                             nonce: nonce,
                             sessionVerifier: sessionVerifier,
                             fido2Payload: fido2Payload))
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
                .encode(encoder: JSONEncoder())
                .mapError { OwnID.CoreSDK.Error.initRequestBodyEncodeFailed(underlying: $0) }
                .map { [self] body -> URLRequest in
                    var request = URLRequest(url: url)
                    print("check here if we replaced values for fido2 payload")
                    request.httpMethod = "POST"
                    request.httpBody = body
                    request.addUserAgent()
                    request.addAPIVersion()
                    let languagesString = webLanguages.rawValue.joined(separator: ",")
                    let field = "Accept-Language"
                    request.addValue(languagesString, forHTTPHeaderField: field)
                    return request
                }
                .eraseToAnyPublisher()
                .flatMap { [self] request -> AnyPublisher<URLSession.DataTaskPublisher.Output, OwnID.CoreSDK.Error> in provider.apiResponse(for: request)
                    .mapError { OwnID.CoreSDK.Error.initRequestNetworkFailed(underlying: $0) }
                    .eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
                .tryMap { response -> Data in
                    guard !response.data.isEmpty else { throw OwnID.CoreSDK.Error.initRequestResponseIsEmpty }
                    return response.data
                }
                .eraseToAnyPublisher()
                .decode(type: Response.self, decoder: JSONDecoder())
                .map { decoded in
                    OwnID.CoreSDK.logger.logCore(.entry(context: decoded.context ?? "no_context", message: "Finished request", Self.self))
                    return decoded
                }
                .mapError { initError in
                    OwnID.CoreSDK.logger.logCore(.errorEntry(message: "\(initError.localizedDescription)", Self.self))
                    guard let error = initError as? OwnID.CoreSDK.Error else { return OwnID.CoreSDK.Error.initRequestResponseDecodeFailed(underlying: initError) }
                    return error
                }
                .eraseToAnyPublisher()
        }
    }
}
