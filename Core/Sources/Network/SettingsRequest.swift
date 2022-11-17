import Foundation
import Combine

public extension OwnID.CoreSDK {
    enum Setting {}
}

public extension OwnID.CoreSDK.Setting {
    struct RequestBody: Encodable {
        let loginID: String
        let context: String
        let nonce: String
    }
}

public extension OwnID.CoreSDK.Setting {
    struct Response: Decodable {
        public let url: String
        public let context: String?
        public let nonce: String?
    }
}

extension OwnID.CoreSDK.Setting {
    class Request {
        let url: OwnID.CoreSDK.ServerURL
        let provider: APIProvider
        let loginID: String
        let context: String
        let nonce: String
        let webLanguages: OwnID.CoreSDK.Languages
        
        internal init(url: OwnID.CoreSDK.ServerURL,
                      loginID: String,
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
