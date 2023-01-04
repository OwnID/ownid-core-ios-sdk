import Foundation
import Combine

public extension OwnID.CoreSDK {
    enum Setting {}
}
#warning("remove as we do not use it?")
public extension OwnID.CoreSDK.Setting {
    struct RequestBody: Encodable {
        let loginID: String
        let context: String
        let nonce: String
    }
}

public extension OwnID.CoreSDK.Setting {
    struct Response: Decodable {
        public let credId: String?
        public let relyingPartyId: String?
        public let relyingPartyName: String?
        public let userDisplayName: String?
        public let userName: String?
        public let challengeType: OwnID.CoreSDK.RequestType?
    }
}

extension OwnID.CoreSDK.Setting {
    class Request {
        let url: OwnID.CoreSDK.ServerURL
        let provider: APIProvider
        let loginID: String
        let origin: String
        let context: String
        let nonce: String
        let webLanguages: OwnID.CoreSDK.Languages
        
        internal init(url: OwnID.CoreSDK.ServerURL,
                      loginID: String,
                      origin: String,
                      context: String,
                      nonce: String,
                      webLanguages: OwnID.CoreSDK.Languages,
                      provider: APIProvider = URLSession.shared) {
            self.url = url
            self.provider = provider
            self.webLanguages = webLanguages
            self.loginID = loginID
            self.context = context
            self.nonce = nonce
            self.origin = origin
        }
        
        func perform() -> AnyPublisher<Response, OwnID.CoreSDK.Error> {
            Just(RequestBody(loginID: loginID, context: context, nonce: nonce))
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
                .encode(encoder: JSONEncoder())
                .mapError { OwnID.CoreSDK.Error.initRequestBodyEncodeFailed(underlying: $0) } //fix error here
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
                    OwnID.CoreSDK.logger.logCore(.entry(message: "Finished request, cred id: \(String(describing: decoded.credId?.logValue))", Self.self))
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
