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
        
        internal init(url: OwnID.CoreSDK.ServerURL,
                      context: OwnID.CoreSDK.Context,
                      nonce: OwnID.CoreSDK.Nonce,
                      sessionVerifier: OwnID.CoreSDK.SessionVerifier,
                      type: OwnID.CoreSDK.RequestType,
                      webLanguages: OwnID.CoreSDK.Languages,
                      provider: APIProvider = URLSession.shared) {
            self.context = context
            self.nonce = nonce
            self.url = url
            self.sessionVerifier = sessionVerifier
            self.provider = provider
            self.type = type
            self.webLanguages = webLanguages
        }
        
        func perform() -> AnyPublisher<OwnID.CoreSDK.Payload, OwnID.CoreSDK.Error> {
            Just(RequestBody(sessionVerifier: sessionVerifier, context: context, nonce: nonce))
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
                    return request
                }
                .eraseToAnyPublisher()
                .flatMap { [self] request -> AnyPublisher<URLSession.DataTaskPublisher.Output, OwnID.CoreSDK.Error> in provider.apiResponse(for: request)
                    .mapError { OwnID.CoreSDK.Error.statusRequestNetworkFailed(underlying: $0) }
                    .eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
                .tryMap { response -> [String: Any] in
                    guard !response.data.isEmpty else { throw OwnID.CoreSDK.Error.statusRequestResponseIsEmpty }
                    guard let json = try JSONSerialization.jsonObject(with: response.data, options: []) as? [String: Any] else {
                        throw OwnID.CoreSDK.Error.statusRequestResponseIsEmpty
                    }
                    return json
                }
                .eraseToAnyPublisher()
                .tryMap { [self] response -> OwnID.CoreSDK.Payload in
                    guard let responseContext = response["context"] as? String else { throw OwnID.CoreSDK.Error.statusRequestResponseIsEmpty }
                    guard context == responseContext else { throw OwnID.CoreSDK.Error.statusRequestResponseContextMismatch }
                    guard let responsePayload = response["payload"] as? [String: Any] else { throw OwnID.CoreSDK.Error.statusRequestResponseIsEmpty }
                    
                    if let serverError = responsePayload["error"] as? String {
                        throw OwnID.CoreSDK.Error.serverError(serverError: OwnID.CoreSDK.ServerError(error: serverError))
                    }
                    
                    let responseData = responsePayload["data"]
                    
                    let loginId = responsePayload["loginId"] as? OwnID.CoreSDK.LoginID
                    
                    let metadataDict = responsePayload["metadata"] as? [String: Any]
                    
                    guard let stringType = responsePayload["type"] as? OwnID.CoreSDK.LoginID,
                          let requestResponseType = OwnID.CoreSDK.StatusResponseType(rawValue: stringType) else { throw OwnID.CoreSDK.Error.statusRequestTypeIsMissing }
                    var authTypeValue: String?
                    if let flowInfo = response["flowInfo"] as? [String: Any], let authType = flowInfo["authType"] as? String {
                        authTypeValue = authType
                    }
                    let payload = OwnID.CoreSDK.Payload(dataContainer: responseData,
                                                        metadata: metadataDict,
                                                        context: context,
                                                        nonce: nonce,
                                                        loginId: loginId,
                                                        responseType: requestResponseType,
                                                        authType: authTypeValue,
                                                        requestLanguage: webLanguages.rawValue.first)
                    
                    OwnID.CoreSDK.logger.logCore(.entry(context: context, message: "Finished request", Self.self))
                    return payload
                }
                .eraseToAnyPublisher()
                .mapError { [weak self] initError in
                    OwnID.CoreSDK.logger.logCore(.errorEntry(context: self?.context,
                                                             message: "\(initError.localizedDescription)",
                                                             Self.self))
                    guard let error = initError as? OwnID.CoreSDK.Error else { return OwnID.CoreSDK.Error.statusRequestFail(underlying: initError) }
                    return error
                }
                .eraseToAnyPublisher()
        }
    }
}

