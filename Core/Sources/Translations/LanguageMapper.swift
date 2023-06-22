import Foundation

extension OwnID.CoreSDK.TranslationsSDK {
    final class LanguageMapper {
        private static let i18nToISO639LanguageMappings: [String: [String]] = [
            "no": ["nb"],
            "zh-CN": ["zh-Hant-MO"],
            "zh-TW": ["zh-Hant-TW", "zh-Hant-HK", "zh-Hant", "zh-Hans-TW", "zh-Hant-US"],
        ]
        
        static func matchSystemLanguage(to serverLanguages: [String], userDefinedLanguages: [String]) -> (serverLanguage: String, systemLanguage: String) {
            for userLanguage in userDefinedLanguages {
                if serverLanguages.contains(userLanguage) {
                    return (userLanguage, userLanguage)
                }
                for mapping in i18nToISO639LanguageMappings {
                    for mappingValues in mapping.value {
                        if mappingValues.contains(userLanguage) {
                            return (mapping.key, userLanguage)
                        }
                    }
                }
                if let languageCode = userLanguage.components(separatedBy: "-").first, serverLanguages.contains(languageCode) {
                    return (languageCode, languageCode)
                }
            }
            return ("en", "en")
        }
    }
}
