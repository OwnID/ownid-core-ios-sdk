import Foundation

extension OwnID.CoreSDK {
    final class DefaultsEmailSaver {
        private static let emailKey = "email_saver_key"
        static func save(email: String) { UserDefaults.standard.set(email, forKey: emailKey) }
        
        static func getEmail() -> String? { UserDefaults.standard.value(forKey: emailKey) as? String }
    }
}
