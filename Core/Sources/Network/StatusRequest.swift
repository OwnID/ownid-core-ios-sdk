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
        let supportedLanguages: OwnID.CoreSDK.Languages
        
        internal init(url: OwnID.CoreSDK.ServerURL,
                      context: OwnID.CoreSDK.Context,
                      nonce: OwnID.CoreSDK.Nonce,
                      sessionVerifier: OwnID.CoreSDK.SessionVerifier,
                      type: OwnID.CoreSDK.RequestType,
                      supportedLanguages: OwnID.CoreSDK.Languages,
                      provider: APIProvider = URLSession.shared) {
            self.context = context
            self.nonce = nonce
            self.url = url
            self.sessionVerifier = sessionVerifier
            self.provider = provider
            self.type = type
            self.supportedLanguages = supportedLanguages
        }
        
        func perform() -> AnyPublisher<OwnID.CoreSDK.Payload, OwnID.CoreSDK.CoreErrorLogWrapper> {
            let input = Just(RequestBody(sessionVerifier: sessionVerifier, context: context, nonce: nonce))
                .setFailureType(to: OwnID.CoreSDK.CoreErrorLogWrapper.self)
                .eraseToAnyPublisher()
                .encode(encoder: JSONEncoder())
                .mapError { [self] in OwnID.CoreSDK.CoreErrorLogWrapper.coreLog(entry: .errorEntry(context: context, Self.self), error: .statusRequestBodyEncodeFailed(underlying: $0)) }
                .map { [self] body -> URLRequest in
                    URLRequest.defaultPostRequest(url: url, body: body, supportedLanguages: supportedLanguages)
                }
                .eraseToAnyPublisher()
            let dataParsingPublisher = OwnID.CoreSDK.EndOfFlowHandler.handle(inputPublisher: input.eraseToAnyPublisher(),
                                                                             context: context,
                                                                             nonce: nonce,
                                                                             requestLanguage: supportedLanguages.rawValue.first,
                                                                             provider: provider,
                                                                             shouldIgnoreResponseBody: false,
                                                                             emptyResponseError: { .statusRequestResponseIsEmpty },
                                                                             typeMissingError: { .statusRequestTypeIsMissing },
                                                                             contextMismatchError: { .statusRequestResponseContextMismatch },
                                                                             networkFailError: { .statusRequestNetworkFailed(underlying: $0) } )
            return dataParsingPublisher.eraseToAnyPublisher()
        }
    }
}

