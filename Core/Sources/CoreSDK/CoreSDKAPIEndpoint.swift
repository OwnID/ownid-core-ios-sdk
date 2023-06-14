import Combine

extension OwnID.CoreSDK {
    struct APIEndpoint {
        var serverConfiguration: (URL) -> AnyPublisher<ServerConfiguration, Error>
    }
}

extension OwnID.CoreSDK.APIEndpoint {
    static let live = Self { url in
        URLSession.shared.dataTaskPublisher(for: url)
            .eraseToAnyPublisher()
            .mapError { OwnID.CoreSDK.Error.requestNetworkFailed(underlying: $0) }
            .retry(2)
            .map { data, _ in return data }
            .eraseToAnyPublisher()
            .decode(type: OwnID.CoreSDK.ServerConfiguration.self, decoder: JSONDecoder())
            .mapError { OwnID.CoreSDK.Error.requestResponseDecodeFailed(underlying: $0) }
            .eraseToAnyPublisher()
    }
}

extension OwnID.CoreSDK.APIEndpoint {
    static let testMock = Self { _ in
        Just(.mock(isFailed: false))
            .setFailureType(to: OwnID.CoreSDK.Error.self)
            .eraseToAnyPublisher()
    }
}
