import Foundation

extension URLRequest {
    public mutating func addUserAgent() {
        addValue(OwnID.CoreSDK.UserAgentManager.shared.SDKUserAgent, forHTTPHeaderField: "User-Agent")
    }
    
    public mutating func addAPIVersion() {
        addValue(OwnID.CoreSDK.APIVersion, forHTTPHeaderField: "X-API-Version")
    }
    
    public mutating func add(origin: String) {
        addValue(origin, forHTTPHeaderField: "Origin")
    }
}
