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
        let loginId: LoginIdSettings
        let verification: Verification

        enum CodingKeys: String, CodingKey {
            case supportedLocales, logLevel, fidoSettings, passkeysAutofillEnabled, loginId, verification
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
    
    //MARK: - Login Id
    struct LoginIdSettings: Codable {
        enum LoginIdType: String, Codable {
            case email, phoneNumber, userName
        }
        
        let type: LoginIdType
        let regex: String
        
        init(type: LoginIdType, regex: String) {
            self.type = type
            self.regex = regex
        }
    }
    
    //MARK: - Verification Type
    struct Verification: Codable {
        enum VerificationType: String, Codable {
            case email, sms
        }
        
        let type: VerificationType
        
        init(type: VerificationType) {
            self.type = type
        }
    }
}

extension OwnID.CoreSDK.ServerConfiguration {
    static func mock(isFailed: Bool = false) -> Self {
        Self(isFailed: isFailed, supportedLocales: [], logLevel: .error, fidoSettings: .none, passkeysAutofillEnabled: false, serverURL: URL(string: "https://ownid.com")!, redirectURLString: .none, platformSettings: .none, loginId: OwnID.CoreSDK.LoginIdSettings(type: .email, regex: ""), verification: OwnID.CoreSDK.Verification(type: .email))
    }
}
