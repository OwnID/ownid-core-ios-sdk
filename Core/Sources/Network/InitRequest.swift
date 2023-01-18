import Foundation
import Combine

public extension OwnID.CoreSDK {
    enum Init {}
}

public extension OwnID.CoreSDK.Init {
    struct RequestBody: Encodable {
        let sessionChallenge: OwnID.CoreSDK.SessionChallenge
        let type: OwnID.CoreSDK.RequestType
        let data: String?
        let originUrl: String?
    }
}

public extension OwnID.CoreSDK.Init {
    struct Response: Decodable {
        public let url: String
        public let context: String?
        public let nonce: String?
    }
}

extension OwnID.CoreSDK.Init {
    class Request {
        let type: OwnID.CoreSDK.RequestType
        let url: OwnID.CoreSDK.ServerURL
        let provider: APIProvider
        let sessionChallenge: OwnID.CoreSDK.SessionChallenge
        let token: OwnID.CoreSDK.JWTToken?
        let supportedLanguages: OwnID.CoreSDK.Languages
        let origin: String?
        
        internal init(type: OwnID.CoreSDK.RequestType,
                      url: OwnID.CoreSDK.ServerURL,
                      sessionChallenge: OwnID.CoreSDK.SessionChallenge,
                      token: OwnID.CoreSDK.JWTToken?,
                      origin: String?,
                      supportedLanguages: OwnID.CoreSDK.Languages,
                      provider: APIProvider = URLSession.shared) {
            self.type = type
            self.url = url
            self.sessionChallenge = sessionChallenge
            self.origin = origin
            self.provider = provider
            self.token = token
            self.supportedLanguages = supportedLanguages
        }
        func perform() -> AnyPublisher<Response, OwnID.CoreSDK.CoreErrorLogWrapper> {
            Just(RequestBody(sessionChallenge: sessionChallenge,
                             type: type,
                             data: token?.jwtString,
                             originUrl: origin?.extendHttpsIfNeeded()))
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
                .encode(encoder: JSONEncoder())
                .mapError { OwnID.CoreSDK.Error.initRequestBodyEncodeFailed(underlying: $0) }
                .map { [self] body -> URLRequest in
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.httpBody = body
                    request.addUserAgent()
                    request.addAPIVersion()
                    if let origin {
                        request.add(origin: origin)
                    }
                    request.add(supportedLanguages: supportedLanguages)
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
                    OwnID.CoreSDK.logger.logCore(.entry(context: decoded.context, message: "Finished request", Self.self))
                    return decoded
                }
                .mapError { initError in
                    guard let error = initError as? OwnID.CoreSDK.Error else { return .coreLog(entry: .errorEntry(Self.self), error: .initRequestResponseDecodeFailed(underlying: initError)) }
                    return .coreLog(entry: .errorEntry(Self.self), error: error)
                }
                .eraseToAnyPublisher()
        }
    }
}
