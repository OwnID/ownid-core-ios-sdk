import Foundation
import Combine

public extension OwnID.CoreSDK {
    typealias LoginID = String
    typealias Nonce = String
    typealias Context = String
    typealias SessionChallenge = String
    typealias SessionVerifier = String
    typealias EventPublisher = AnyPublisher<Event, CoreErrorLogWrapper>
    typealias ServerURL = URL
    
    /// Represents path to open app back when certain flows finished. Example `com.ownid.CustomIntegrationDemo://ownid/redirect/`
    typealias RedirectionURLString = String
    
    /// Represents app console identifier. Example `q4qy97xgj02r37`
    typealias AppID = String
    typealias AuthType = String
}

extension OwnID.CoreSDK {
    typealias BrowserURL = URL
    typealias BrowserScheme = String
    typealias BrowserURLString = String
}
