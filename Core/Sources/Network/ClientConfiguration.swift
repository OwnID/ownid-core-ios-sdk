import Foundation

extension OwnID.CoreSDK {
    struct ClientConfiguration: Decodable {
        let logLevel: Int
        let passkeys: Bool
        let rpId: String?
        let passkeysAutofill: Bool
    }
}
