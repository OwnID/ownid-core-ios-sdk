import Foundation

extension OwnID.CoreSDK {
    // MARK: - ServerConfiguration
    struct ServerConfiguration: Codable {
        let supportedLocales: [String]
        let logLevel: LogLevel
        let fidoSettings: FidoSettings
        let passkeysAutofillEnabled: Bool
        let serverURL: ServerURL
        let cacheTTL: Int
        let redirectURLString: RedirectionURLString?
        let platformSettings: PlatformSettings?

        enum CodingKeys: String, CodingKey {
            case supportedLocales, logLevel, fidoSettings, passkeysAutofillEnabled
            case serverURL = "serverUrl"
            case cacheTTL = "cacheTtl"
            case redirectURLString = "redirectUrl"
            case platformSettings = "iosSettings"
        }
    }

    // MARK: - FidoSettings
    struct FidoSettings: Codable {
        let rpID, rpName: String

        enum CodingKeys: String, CodingKey {
            case rpID = "rpId"
            case rpName
        }
    }
    
    // MARK: - PlatformSettings
    struct PlatformSettings: Codable {
        let redirectUrlOverride: RedirectionURLString?
    }
}
