import Combine

extension OwnID.CoreSDK {
    struct APIEndpoint {
        var serverConfiguration: (URL) -> AnyPublisher<ServerConfiguration, Swift.Error>
    }
}

extension OwnID.CoreSDK.APIEndpoint {
    static let live = Self { url in
        URLSession.shared.dataTaskPublisher(for: url)
            .retry(2)
            .map { data, _ in return data }
            .eraseToAnyPublisher()
            .decode(type: OwnID.CoreSDK.ServerConfiguration.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
}

extension OwnID.CoreSDK.APIEndpoint {
    static let testMock = Self { _ in
        Just(.mock(isFailed: false))
            .setFailureType(to: Swift.Error.self)
            .eraseToAnyPublisher()
    }
}
