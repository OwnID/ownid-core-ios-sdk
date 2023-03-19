import Foundation

extension OwnID.CoreSDK {
    // MARK: - ServerConfiguration
    struct ServerConfiguration: Codable {
        var isFailed = false
        let supportedLocales: [String]
        let logLevel: LogLevel
        let fidoSettings: FidoSettings?
        let passkeysAutofillEnabled: Bool
        let serverURL: ServerURL
        let redirectURLString: RedirectionURLString?
        let platformSettings: PlatformSettings?

        enum CodingKeys: String, CodingKey {
            case supportedLocales, logLevel, fidoSettings, passkeysAutofillEnabled
            case serverURL = "serverUrl"
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
