import Combine
import Foundation

public protocol APIProvider {
    typealias APIResponse = URLSession.DataTaskPublisher.Output
    func apiResponse(for request: URLRequest) -> AnyPublisher<APIResponse, URLError>
}

extension URLSession: APIProvider {
    public func apiResponse(for request: URLRequest) -> AnyPublisher<APIResponse, URLError> {
        dataTaskPublisher(for: request)
            .eraseToAnyPublisher()
    }
}
