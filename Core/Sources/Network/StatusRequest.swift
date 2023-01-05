import Foundation
import Combine

extension OwnID.CoreSDK {
    enum Status {}
}

extension OwnID.CoreSDK.Status {
    struct RequestBody: Encodable {
        let sessionVerifier: OwnID.CoreSDK.SessionVerifier
        let context: OwnID.CoreSDK.Context
        let nonce: OwnID.CoreSDK.Nonce
    }
}

extension OwnID.CoreSDK.Status {
    typealias PayloadDictionary = [String: Any]
    
    struct Response {
        let context: String
        let metadata: String
        let payload: PayloadDictionary
    }
}

extension OwnID.CoreSDK.Status {
    class Request {
        let url: OwnID.CoreSDK.ServerURL
        let context: OwnID.CoreSDK.Context
        let nonce: OwnID.CoreSDK.Nonce
        let provider: APIProvider
        let sessionVerifier: OwnID.CoreSDK.SessionVerifier
        let type: OwnID.CoreSDK.RequestType
        let webLanguages: OwnID.CoreSDK.Languages
        let origin: String?
        
        internal init(url: OwnID.CoreSDK.ServerURL,
                      context: OwnID.CoreSDK.Context,
                      nonce: OwnID.CoreSDK.Nonce,
                      sessionVerifier: OwnID.CoreSDK.SessionVerifier,
                      type: OwnID.CoreSDK.RequestType,
                      origin: String?,
                      webLanguages: OwnID.CoreSDK.Languages,
                      provider: APIProvider = URLSession.shared) {
            self.context = context
            self.nonce = nonce
            self.url = url
            self.origin = origin
            self.sessionVerifier = sessionVerifier
            self.provider = provider
            self.type = type
            self.webLanguages = webLanguages
        }
        
        func perform() -> AnyPublisher<OwnID.CoreSDK.Payload, OwnID.CoreSDK.Error> {
            let input = Just(RequestBody(sessionVerifier: sessionVerifier, context: context, nonce: nonce))
                .setFailureType(to: OwnID.CoreSDK.Error.self)
                .eraseToAnyPublisher()
                .encode(encoder: JSONEncoder())
                .mapError { OwnID.CoreSDK.Error.statusRequestBodyEncodeFailed(underlying: $0) }
                .map { [self] body -> URLRequest in
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.httpBody = body
                    request.addUserAgent()
                    request.addAPIVersion()
                    if let origin {
                        request.add(origin: origin)
                    }
                    return request
                }
                .eraseToAnyPublisher()
            let dataParsingPublisher = OwnID.CoreSDK.EndOfFlowHandler.handle(inputPublisher: input.eraseToAnyPublisher(),
                                                                             context: context,
                                                                             nonce: nonce,
                                                                             requestLanguage: webLanguages.rawValue.first,
                                                                             provider: provider,
                                                                             shouldIgnoreResponseBody: false)
            return dataParsingPublisher.eraseToAnyPublisher()
        }
    }
}

