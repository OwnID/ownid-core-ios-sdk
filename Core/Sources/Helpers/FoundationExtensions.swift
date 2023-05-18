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
    
    #warning("make it more flexible with ability to set httpMethod and headers")
    static func defaultPostRequest(url: OwnID.CoreSDK.ServerURL, body: Data, supportedLanguages: OwnID.CoreSDK.Languages) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        request.addUserAgent()
        request.addAPIVersion()
        request.add(supportedLanguages: supportedLanguages)
        return request
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
