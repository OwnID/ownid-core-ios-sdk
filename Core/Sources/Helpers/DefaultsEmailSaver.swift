import Foundation

extension OwnID.CoreSDK {
    final class DefaultsLoginIdSaver {
        private static let emailKey = "email_saver_key"
        static func save(loginId: String) { UserDefaults.standard.set(loginId, forKey: emailKey) }
        
        static func getLoginId() -> String? { UserDefaults.standard.value(forKey: emailKey) as? String }
    }
}
