import Foundation

extension OwnID.CoreSDK.LocalConfiguration {
    enum Error: Swift.Error {
        case redirectURLSchemeNotComplete
        case serverURLIsNotComplete
    }
}

extension OwnID.CoreSDK {
    
    struct LocalConfiguration: Decodable {
        init(appID: OwnID.CoreSDK.AppID, redirectionURL: OwnID.CoreSDK.RedirectionURLString, environment: String?) throws {
            self.environment = environment
            self.ownIDServerConfigurationURL = try Self.prepare(serverURL: Self.buildServerConfigurationURL(for: appID, env: environment))
            self.redirectionURL = redirectionURL
            try performPropertyChecks()
        }
        
        private enum CodingKeys: String, CodingKey {
            case appID = "OwnIDAppID"
            case redirectionURL = "OwnIDRedirectionURL"
            case env = "OwnIDEnv"
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let appID = try container.decode(String.self, forKey: .appID)
            let env = try container.decodeIfPresent(String.self, forKey: .env)
            self.environment = env
            self.redirectionURL = try container.decode(String.self, forKey: .redirectionURL)
            
            let serverURL = Self.buildServerConfigurationURL(for: appID, env: env)
            self.ownIDServerConfigurationURL = try Self.prepare(serverURL: serverURL)
            
            try performPropertyChecks()
        }
        
        let ownIDServerConfigurationURL: ServerURL
        let redirectionURL: RedirectionURLString
        let environment: String?
        
        var statusURL: ServerURL {
            var url = ownIDServerConfigurationURL
            url.appendPathComponent("status")
            url.appendPathComponent("final")
            return url
        }
        
        var settingURL: ServerURL {
            var url = ownIDServerConfigurationURL
            url.appendPathComponent("passkeys")
            url.appendPathComponent("fido2")
            url.appendPathComponent("settings")
            return url
        }
        
        var authURL: ServerURL {
            var url = ownIDServerConfigurationURL
            url.appendPathComponent("passkeys")
            url.appendPathComponent("fido2")
            url.appendPathComponent("auth")
            return url
        }
    }
}

private extension OwnID.CoreSDK.LocalConfiguration {
    static func buildServerConfigurationURL(for appID: OwnID.CoreSDK.AppID, env: String?) -> URL {
        var serverConfigURLString = "https://cdn.ownid.com/sdk/\(appID)/mobile"
        if let env {
            serverConfigURLString = "https://cdn.\(env).ownid.com/sdk/\(appID)/mobile"
        }
        let serverConfigURL = URL(string: serverConfigURLString)!
        return serverConfigURL
    }
    
    static func prepare(serverURL: URL) throws -> URL {
        var ownIDServerURL = serverURL
        var components = URLComponents(url: ownIDServerURL, resolvingAgainstBaseURL: false)!
        components.path = ""
        ownIDServerURL = components.url!
        ownIDServerURL = ownIDServerURL.appendingPathComponent("ownid")
        return ownIDServerURL
    }
    
    func check(redirectionURL: String) throws {
        let parts = redirectionURL.components(separatedBy: ":")
        if parts.count < 2 {
            throw OwnID.CoreSDK.LocalConfiguration.Error.redirectURLSchemeNotComplete
        }
        let secondPart = parts[1]
        if secondPart.isEmpty {
            throw OwnID.CoreSDK.LocalConfiguration.Error.redirectURLSchemeNotComplete
        }
    }
    
    func check(ownIDServerURL: URL) throws {
        guard ownIDServerURL.scheme == "https" else { throw OwnID.CoreSDK.LocalConfiguration.Error.serverURLIsNotComplete }
        
        let domain = "ownid.com"
        guard let hostName = ownIDServerURL.host else { throw OwnID.CoreSDK.LocalConfiguration.Error.serverURLIsNotComplete }
        let subStrings = hostName.components(separatedBy: ".")
        var domainName = ""
        let count = subStrings.count
        if count > 2 {
            domainName = subStrings[count - 2] + "." + subStrings[count - 1]
        } else if count == 2 {
            domainName = hostName
        }
        guard domain == domainName else { throw OwnID.CoreSDK.LocalConfiguration.Error.serverURLIsNotComplete }
        
        guard ownIDServerURL.lastPathComponent == "ownid" else { throw OwnID.CoreSDK.LocalConfiguration.Error.serverURLIsNotComplete }
    }
    
    func performPropertyChecks() throws {
        try check(ownIDServerURL: ownIDServerConfigurationURL)
        try check(redirectionURL: redirectionURL)
    }
}
