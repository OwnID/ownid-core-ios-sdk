import Foundation
import Combine
import OwnIDCoreSDK

struct MockAPIRequestBadBodyProvider: APIProvider {
    func apiResponse(for request: URLRequest) -> AnyPublisher<APIResponse, URLError> {
        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: nil)!
        let data = "Not Actually valid JSON, that generates error, event request itself is statusCode: 200"
            .data(using: .utf8)!
        return Result.Publisher((data: data, response: response))
            .eraseToAnyPublisher()
    }
}

struct MockAPIRequestErrorProvider: APIProvider {
    func apiResponse(for request: URLRequest) -> AnyPublisher<APIResponse, URLError> {
        Result.Publisher(URLError(.timedOut))
            .eraseToAnyPublisher()
    }
}

struct MockAPIRequestCorrectBodyProvider: APIProvider {
    let dataString: String
    
    func apiResponse(for request: URLRequest) -> AnyPublisher<APIResponse, URLError> {
        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: nil)!
        let data = dataString.data(using: .utf8)!
        return Result.Publisher((data: data, response: response))
            .eraseToAnyPublisher()
    }
}

public extension APIProvider {
    static var badBodyProvider: APIProvider {
        MockAPIRequestBadBodyProvider()
    }
    
    static var errorProvider: APIProvider {
        MockAPIRequestErrorProvider()
    }
    
    static func correctBody(for string: String) -> APIProvider {
        MockAPIRequestCorrectBodyProvider(dataString: string)
    }
}

public enum MockAPI: APIProvider {
    public func apiResponse(for request: URLRequest) -> AnyPublisher<APIResponse, URLError> {
        fatalError()
    }
}
