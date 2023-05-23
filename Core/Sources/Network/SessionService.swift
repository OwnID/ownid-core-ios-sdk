import Foundation
import Combine

extension OwnID.CoreSDK {
    enum HTTPMethod: String {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case patch = "PATCH"
        case delete = "DELETE"
    }
}

extension OwnID.CoreSDK {
    enum ServiceError: Swift.Error {
        case encodeFailed(error: Swift.Error)
        case networkFailed(underlying: URLError)
        case responseIsEmpty
        case decodeFailed(error: Swift.Error)
    }
    
    class SessionService {
        let provider: APIProvider
        let supportedLanguages: OwnID.CoreSDK.Languages
        
        init(provider: APIProvider = URLSession.shared,
             supportedLanguages: OwnID.CoreSDK.Languages) {
            self.provider = provider
            self.supportedLanguages = supportedLanguages
        }
        
        func perform<Body: Encodable, Response: Decodable>(url: OwnID.CoreSDK.ServerURL,
                                                           method: HTTPMethod,
                                                           body: Body,
                                                           with type: Response.Type) -> AnyPublisher<Response, ServiceError> {
            Just(body)
                .setFailureType(to: ServiceError.self)
                .eraseToAnyPublisher()
                .encode(encoder: JSONEncoder())
                .mapError { ServiceError.encodeFailed(error: $0) }
                .map { [self] body -> URLRequest in
                    let headers = URLRequest.defaultHeaders(supportedLanguages: supportedLanguages)
                    return URLRequest.request(url: url, method: method, body: body, headers: headers)
                }
                .eraseToAnyPublisher()
                .flatMap { [self] request -> AnyPublisher<URLSession.DataTaskPublisher.Output, ServiceError> in
                    return provider.apiResponse(for: request)
                        .mapError { ServiceError.networkFailed(underlying: $0) }
                        .eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
                .tryMap { [self] response -> Data in
                    guard !response.data.isEmpty else { throw ServiceError.responseIsEmpty }
                    self.printResponse(data: response.data)
                    return response.data
                }
                .eraseToAnyPublisher()
                .decode(type: type, decoder: JSONDecoder())
                .mapError { ServiceError.decodeFailed(error: $0) }
                .eraseToAnyPublisher()
        }
        
        private func printResponse(data: Data) {
            let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]
            
            var bodyFields = ""
            json?.forEach({ key, value in
                bodyFields.append("     \(key): \(value)\n")
            })
            print("Response")
            print("----------------\n Body:\n\(bodyFields)----------------\n")
        }
    }
}
