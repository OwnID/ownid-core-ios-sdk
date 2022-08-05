import XCTest
import Combine
@testable import OwnIDCoreSDK

public final class APISessionStub: APISessionProtocol {
    private let isInitSuccess: Bool
    private let isStatusSuccess: Bool
    public let context = "dkmd3k3@@@edsd"
    public let nonce = "skdmk3@@defkve__"
    public let login = "dkjdn@gmail.com"
    
    public init(isInitSuccess: Bool = true, isStatusSuccess: Bool = true) {
        self.isInitSuccess = isInitSuccess
        self.isStatusSuccess = isStatusSuccess
    }
    
    public func performInitRequest(type: OwnID.CoreSDK.RequestType, token: OwnID.CoreSDK.JWTToken?) -> AnyPublisher<OwnID.CoreSDK.Init.Response, OwnID.CoreSDK.Error> {
        if isInitSuccess {
            return Result.Publisher(OwnID.CoreSDK.Init.Response(url: "22", context: "22", nonce: "22"))
                .delay(for: 1, scheduler: RunLoop.main)
                .eraseToAnyPublisher()
        } else {
            return Result.failure(OwnID.CoreSDK.Error.initRequestNetworkFailed(underlying: URLError(.badServerResponse)))
                .publisher
                .delay(for: 1, scheduler: RunLoop.main)
                .eraseToAnyPublisher()
        }
    }
    
    public func performStatusRequest() -> AnyPublisher<OwnID.CoreSDK.Payload, OwnID.CoreSDK.Error> {
        if isStatusSuccess {
            let dataContainer = ["uidSignature": "P4RtfVBnYUiJ7zZTFbDgGP0zyqo=", "signatureTimestamp": 1630079025, "uid": "bc7a22f11a514a2ba6f26397d37260b8"] as [String : Any]
            let metadata = ["collectionName": "ownid", "docId": "8lfpmgvoWFZ6x9hng99KsA8", "userIdKey": "userId"]
            return Result.Publisher(OwnID.CoreSDK.Payload(dataContainer: dataContainer,
                                                          metadata: metadata,
                                                          context: context,
                                                          nonce: nonce,
                                                          loginId: login,
                                                          responseType: .session))
                .delay(for: 1, scheduler: RunLoop.main)
                .eraseToAnyPublisher()
        } else {
            return Result.failure(OwnID.CoreSDK.Error.statusRequestNetworkFailed(underlying: URLError(.badServerResponse)))
                .publisher
                .delay(for: 1, scheduler: RunLoop.main)
                .eraseToAnyPublisher()
        }
    }
}

public final class LinkAPISessionStub: APISessionProtocol {
    private let isRequestStarted: Bool
    
    public init(isRequestStarted: Bool = true) {
        self.isRequestStarted = isRequestStarted
    }
    
    public func performInitRequest(type: OwnID.CoreSDK.RequestType, token: OwnID.CoreSDK.JWTToken?) -> AnyPublisher<OwnID.CoreSDK.Init.Response, OwnID.CoreSDK.Error> {
        if isRequestStarted {
            return Result.Publisher(OwnID.CoreSDK.Init.Response(url: "22", context: "22", nonce: "22"))
                .delay(for: 1, scheduler: RunLoop.main)
                .eraseToAnyPublisher()
        } else {
            return Result.Publisher(OwnID.CoreSDK.Init.Response(url: "22", context: .none, nonce: .none))
                .delay(for: 1, scheduler: RunLoop.main)
                .eraseToAnyPublisher()
        }
    }
    
    public func performStatusRequest() -> AnyPublisher<OwnID.CoreSDK.Payload, OwnID.CoreSDK.Error> {
        return Result.failure(OwnID.CoreSDK.Error.statusRequestNetworkFailed(underlying: URLError(.badServerResponse)))
            .publisher
            .delay(for: 1, scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }
}
