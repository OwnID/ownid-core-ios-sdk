import Foundation

extension URLRequest {
    public mutating func addUserAgent() {
        addValue(OwnID.CoreSDK.UserAgentManager.shared.mainSDKUserAgent, forHTTPHeaderField: "User-Agent")
    }
}
