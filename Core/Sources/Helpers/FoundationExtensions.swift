import Foundation

extension URLRequest {
    public mutating func addUserAgent() {
        addValue(OwnID.CoreSDK.UserAgentManager.shared.SDKUserAgent, forHTTPHeaderField: "User-Agent")
    }
    
    public mutating func addAPIVersion() {
        addValue(OwnID.CoreSDK.APIVersion, forHTTPHeaderField: "X-API-Version")
    }
    
    public mutating func add(supportedLanguages: OwnID.CoreSDK.Languages) {
        let languagesString = supportedLanguages.rawValue.joined(separator: ",")
        addValue(languagesString, forHTTPHeaderField: "Accept-Language")
    }
}

extension String {
    func extendHttpsIfNeeded() -> Self {
        if !contains("https://"), !contains("http://"), !contains("http") {
            return "https://" + self
        }
        return self
    }
}
