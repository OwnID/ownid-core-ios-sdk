import Foundation

extension OwnID.CoreSDK {
    final class DefaultsLoginIdSaver {
        private static let loginIdKey = "email_saver_key"
        static func save(loginId: String) { UserDefaults.standard.set(loginId, forKey: loginIdKey) }
        
        static func getLoginId() -> String? { UserDefaults.standard.value(forKey: loginIdKey) as? String }
    }
}
