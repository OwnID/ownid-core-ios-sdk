import Foundation
import Combine

public extension OwnID.CoreSDK {
    enum Status {}
}

public extension OwnID.CoreSDK.Status {
    struct RequestBody: Encodable {
        let sessionVerifier: OwnID.CoreSDK.SessionVerifier
    }
}

public extension OwnID.CoreSDK.Status {
    struct Response: Decodable {
        let context: String
        let status: String
        let metadata: Metadata?
        let flowInfo: FlowInfo
        
        let payload: PayloadResponse
    }
    
    struct FlowInfo: Decodable {
        let authType: String
        let event: String
    }
    
    struct Metadata: Decodable {
        let collectionName: String?
        let docId: String?
        let userIdKey: String?
    }
    
    struct PayloadResponse: Decodable {
        let data: PayloadData?
        let loginId: String?
        let type: String?
        //TODO: should we put error??
    }
    
    struct PayloadData: Decodable {
        let authType: String?
        let createdTimestamp: String?
        let creationSource: String?
        let fido2CredentialId: String?
        let fido2RpId: String?
        let fido2SignatureCounter: String?
        let isSharable: Bool?
        let os: String?
        let osVersion: String?
        let pubKey: String?
        let source: String?
    }
}

extension OwnID.CoreSDK.Status {
    class Request {
        let url: OwnID.CoreSDK.ServerURL
        let context: OwnID.CoreSDK.Context
        let provider: APIProvider
        let sessionVerifier: OwnID.CoreSDK.SessionVerifier
        let type: OwnID.CoreSDK.RequestType
        let supportedLanguages: OwnID.CoreSDK.Languages
        
        internal init(url: OwnID.CoreSDK.ServerURL,
                      context: OwnID.CoreSDK.Context,
                      sessionVerifier: OwnID.CoreSDK.SessionVerifier,
                      type: OwnID.CoreSDK.RequestType,
                      supportedLanguages: OwnID.CoreSDK.Languages,
                      provider: APIProvider = URLSession.shared) {
            self.context = context
            self.url = url
            self.sessionVerifier = sessionVerifier
            self.provider = provider
            self.type = type
            self.supportedLanguages = supportedLanguages
        }
        
        func perform() -> AnyPublisher<Response, OwnID.CoreSDK.CoreErrorLogWrapper> {
            Just(RequestBody(sessionVerifier: sessionVerifier))
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
                .encode(encoder: JSONEncoder())
                .mapError { OwnID.CoreSDK.Error.statusRequestBodyEncodeFailed(underlying: $0) }
                .map { [self] body -> URLRequest in
                    URLRequest.defaultPostRequest(url: url, body: body, supportedLanguages: supportedLanguages)
                }
                .eraseToAnyPublisher()
                .flatMap { [self] request -> AnyPublisher<URLSession.DataTaskPublisher.Output, OwnID.CoreSDK.Error> in provider.apiResponse(for: request)
                        .mapError { OwnID.CoreSDK.Error.statusRequestNetworkFailed(underlying: $0) }
                        .eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
                .tryMap { response -> Data in
                    guard !response.data.isEmpty else { throw OwnID.CoreSDK.Error.statusRequestResponseIsEmpty }
                    let json = try JSONSerialization.jsonObject(with: response.data, options: []) as? [String : Any]
                    return response.data
                }
                .eraseToAnyPublisher()
                .decode(type: Response.self, decoder: JSONDecoder())
                .map { [self] data in
                    OwnID.CoreSDK.logger.logCore(.entry(context: context, message: "Finished request", Self.self))
                    return data
                }
                .mapError { initError in
                    guard let error = initError as? OwnID.CoreSDK.Error else { return .coreLog(entry: .errorEntry(Self.self), error: .authRequestResponseDecodeFailed(underlying: initError)) }
                    return .coreLog(entry: .errorEntry(Self.self), error: error)
                }
                .eraseToAnyPublisher()
        }
    }
}
