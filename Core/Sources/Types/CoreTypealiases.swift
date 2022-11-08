import Foundation
import Combine

public extension OwnID.CoreSDK {
    typealias LoginID = String
    typealias Nonce = String
    typealias Context = String
    typealias SessionChallenge = String
    typealias SessionVerifier = String
    typealias EventPublisher = AnyPublisher<Event, Error>
    typealias ServerURL = URL
    typealias RedirectionURLString = String
    typealias AuthType = String
}

extension OwnID.CoreSDK {
    typealias BrowserURL = URL
    typealias BrowserScheme = String
    typealias BrowserURLString = String
}
