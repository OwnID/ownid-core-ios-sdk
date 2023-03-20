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
            self.appID = appID
            self.redirectionURL = redirectionURL
            try buildURLFrom(appID, environment)
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let appID = try container.decode(String.self, forKey: .appID)
            let env = try container.decodeIfPresent(String.self, forKey: .env)
            self.appID = appID
            self.environment = env
            self.redirectionURL = try container.decode(String.self, forKey: .redirectionURL)
            
            try buildURLFrom(appID, env)
        }
        
        private mutating func buildURLFrom(_ appID: String, _ env: String?) throws {
            let serverURL = Self.buildServerConfigurationURL(for: appID, env: env)
            ownIDServerConfigurationURL = serverURL
            
            try performPropertyChecks()
        }
        
        private enum CodingKeys: String, CodingKey {
            case appID = "OwnIDAppID"
            case redirectionURL = "OwnIDRedirectionURL"
            case env = "OwnIDEnv"
        }
        
        private(set) var ownIDServerConfigurationURL: ServerURL = ServerURL(string: "ownid.com")!
        var redirectionURL: RedirectionURLString
        let appID: OwnID.CoreSDK.AppID
        let environment: String?
        var serverURL: ServerURL!
        var fidoSettings: FidoSettings?
        var passkeysAutofillEnabled: Bool!
        
        var finalStatusURL: ServerURL {
            var url = serverURL!
            addBasePathComponents(&url)
            url.appendPathComponent("status")
            url.appendPathComponent("final")
            return url
        }
        
        var statusURL: ServerURL {
            var url = serverURL!
            addBasePathComponents(&url)
            url.appendPathComponent("status")
            return url
        }
        
        var initURL: ServerURL {
            var url = serverURL!
            addBasePathComponents(&url)
            return url
        }
        
        var authURL: ServerURL {
            var url = serverURL!
            addBasePathComponents(&url)
            url.appendPathComponent("fido2")
            url.appendPathComponent("auth")
            return url
        }
        
        var metricsURL: ServerURL {
            var url = URL(string: "https://\(appID).server.ownid.com/events")!
            if let environment {
                url = URL(string: "https://\(appID).server.\(environment).ownid.com/events")!
            }
            return url
        }
        
        private static let mobileSuffix = "mobile"
        private static let mobileVersion = "v1"
        private static let pathComponent = "ownid"
    }
}

private extension OwnID.CoreSDK.LocalConfiguration {
    
    func addBasePathComponents(_ url: inout URL) {
        url.appendPathComponent(Self.mobileSuffix)
        url.appendPathComponent(Self.mobileVersion)
        url.appendPathComponent(Self.pathComponent)
    }
    
    static func buildServerConfigurationURL(for appID: OwnID.CoreSDK.AppID, env: String?) -> URL {
        var serverConfigURLString = "https://cdn.ownid.com/sdk/\(appID)/\(mobileSuffix)"
        if let env {
            serverConfigURLString = "https://cdn.\(env).ownid.com/sdk/\(appID)/\(mobileSuffix)"
        }
        let serverConfigURL = URL(string: serverConfigURLString)!
        return serverConfigURL
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
        
        guard ownIDServerURL.lastPathComponent == Self.mobileSuffix else { throw OwnID.CoreSDK.LocalConfiguration.Error.serverURLIsNotComplete }
    }
    
    func performPropertyChecks() throws {
        try check(ownIDServerURL: ownIDServerConfigurationURL)
        try check(redirectionURL: redirectionURL)
    }
}
