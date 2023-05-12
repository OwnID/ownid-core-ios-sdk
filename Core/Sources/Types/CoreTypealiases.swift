import Foundation
import Combine

public extension OwnID.CoreSDK {
    typealias LoginID = String
    #warning("Nonce is deprecated. Please remove it soon")
    typealias Nonce = String
    typealias Context = String
    typealias SessionChallenge = String
    typealias SessionVerifier = String
    typealias ServerURL = URL
    
    /// Represents path to open app back when certain flows finished. Example `com.ownid.CustomIntegrationDemo://ownid/redirect/`
    typealias RedirectionURLString = String
    
    /// Represents app console identifier. Example `q4qy97xgj02r37`
    typealias AppID = String
    typealias AuthType = String
    
    /// Logs into or creates account for this user ID, passed by symbol
    typealias LoginIdPublisher = AnyPublisher<String, Never>
}

extension OwnID.CoreSDK {
    typealias BrowserURL = URL
    typealias BrowserScheme = String
    typealias BrowserURLString = String
}
