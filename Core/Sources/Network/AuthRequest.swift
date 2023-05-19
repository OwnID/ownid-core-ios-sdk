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
            if let fido2Payload = fido2Payload as? OwnID.CoreSDK.Fido2LoginPayload {
                try container.encode(fido2Payload, forKey: .result)
            }
            if let fido2Payload = fido2Payload as? OwnID.CoreSDK.Fido2RegisterPayload {
                try container.encode(fido2Payload, forKey: .result)
            }
        }
        
        let type: OwnID.CoreSDK.RequestType
        let fido2Payload: Encodable
        
        enum CodingKeys: CodingKey {
            case type
            case result
        }
    }
}

public extension OwnID.CoreSDK.Auth {
    struct Response: Decodable {
        let step: OwnID.CoreSDK.Step
    }
}

extension OwnID.CoreSDK.Auth {
    class Request {
        let type: OwnID.CoreSDK.RequestType
        let url: OwnID.CoreSDK.ServerURL
        let context: OwnID.CoreSDK.Context
        var fido2LoginPayload: Encodable
        let supportedLanguages: OwnID.CoreSDK.Languages
        let provider: APIProvider
        
        internal init(type: OwnID.CoreSDK.RequestType,
                      url: OwnID.CoreSDK.ServerURL,
                      context: OwnID.CoreSDK.Context,
                      fido2LoginPayload: Encodable,
                      supportedLanguages: OwnID.CoreSDK.Languages,
                      provider: APIProvider = URLSession.shared) {
            self.type = type
            self.url = url
            self.provider = provider
            self.supportedLanguages = supportedLanguages
            self.context = context
            self.fido2LoginPayload = fido2LoginPayload
        }
        
        func perform() -> AnyPublisher<Response, OwnID.CoreSDK.CoreErrorLogWrapper> {
            Just(RequestBody(type: type, fido2Payload: fido2LoginPayload))
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
                .encode(encoder: JSONEncoder())
                .mapError { OwnID.CoreSDK.Error.authRequestBodyEncodeFailed(underlying: $0) }
                .map { [self] body -> URLRequest in
                    URLRequest.defaultPostRequest(url: url, body: body, supportedLanguages: supportedLanguages)
                }
                .eraseToAnyPublisher()
                .flatMap { [self] request -> AnyPublisher<URLSession.DataTaskPublisher.Output, OwnID.CoreSDK.Error> in provider.apiResponse(for: request)
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
                .map { [self] response in
                    OwnID.CoreSDK.logger.logCore(.entry(context: context, message: "Finished request", Self.self))
                    return response
                }
                .mapError { initError in
                    guard let error = initError as? OwnID.CoreSDK.Error else { return .coreLog(entry: .errorEntry(Self.self), error: .authRequestResponseDecodeFailed(underlying: initError)) }
                    return .coreLog(entry: .errorEntry(Self.self), error: error)
                }
                .eraseToAnyPublisher()
        }
    }
}
