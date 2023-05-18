import Foundation
import Combine

public extension OwnID.CoreSDK {
    enum Init {}
}

public extension OwnID.CoreSDK.Init {
    struct RequestData {
        let loginId: String
        let type: OwnID.CoreSDK.RequestType
        let supportsFido2: Bool
    }
    
    struct RequestBody: Encodable {
        let sessionChallenge: OwnID.CoreSDK.SessionChallenge
        let type: OwnID.CoreSDK.RequestType
        let loginId: String
        let supportsFido2: Bool
        var qr = false
        var passkeyAutofill = false
        
        static func create(sessionChallenge: OwnID.CoreSDK.SessionChallenge, data: RequestData) -> Self {
            Self(sessionChallenge: sessionChallenge, type: data.type, loginId: data.loginId, supportsFido2: data.supportsFido2)
        }
    }
}

public extension OwnID.CoreSDK {
    struct Step: Decodable {
        enum StepType: String, Decodable {
            case fido2Authorize, starting
        }
        
        let type: StepType
        let data: StepData
    }
    
    struct StepData: Decodable {
        let relyingPartyId: String?
        let relyingPartyName: String?
        let url: String?
        let userDisplayName: String?
        let userName: String?
    }
}

public extension OwnID.CoreSDK.Init {
    struct Response: Decodable {
        public let nonce: String? //TODO: remove
        
        let context: String
        let expiration: Int?
        let stopUrl: String
        let finalStatusUrl: String
        
        let step: OwnID.CoreSDK.Step
    }
}

extension OwnID.CoreSDK.Init {
    class Request {
        let requestData: RequestData
        let url: OwnID.CoreSDK.ServerURL
        let provider: APIProvider
        let sessionChallenge: OwnID.CoreSDK.SessionChallenge
        let supportedLanguages: OwnID.CoreSDK.Languages
        
        internal init(requestData: RequestData,
                      url: OwnID.CoreSDK.ServerURL,
                      sessionChallenge: OwnID.CoreSDK.SessionChallenge,
                      supportedLanguages: OwnID.CoreSDK.Languages,
                      provider: APIProvider = URLSession.shared) {
            self.requestData = requestData
            self.url = url
            self.sessionChallenge = sessionChallenge
            self.provider = provider
            self.supportedLanguages = supportedLanguages
        }
        
        func perform() -> AnyPublisher<Response, OwnID.CoreSDK.CoreErrorLogWrapper> {
            Just(RequestBody.create(sessionChallenge: sessionChallenge, data: requestData))
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
                .encode(encoder: JSONEncoder())
                .mapError { OwnID.CoreSDK.Error.initRequestBodyEncodeFailed(underlying: $0) }
                .map { [self] body -> URLRequest in
                    URLRequest.defaultPostRequest(url: url, body: body, supportedLanguages: supportedLanguages)
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
