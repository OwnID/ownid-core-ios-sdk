import Foundation
import Combine

extension OwnID.CoreSDK.TranslationsSDK.Downloader {
    struct SupportedLanguages: Codable {
        let langs: [String]
    }
}

extension OwnID.CoreSDK.TranslationsSDK {
    final class Downloader {
        typealias DownloaderPublisher = AnyPublisher<(systemLanguage: String, language: [String: String]), OwnID.CoreSDK.CoreErrorLogWrapper>
        
        private let session: URLSession
        
        init() {
            let config = URLSessionConfiguration.default
            config.requestCachePolicy = .returnCacheDataElseLoad
            session = URLSession(configuration: config)
        }
        
        func downloadTranslations(supportedLanguages: OwnID.CoreSDK.Languages) -> DownloaderPublisher {
            Just(OwnID.CoreSDK.shared.supportedLocales ?? [])
                .setFailureType(to: OwnID.CoreSDK.CoreErrorLogWrapper.self)
                .eraseToAnyPublisher()
                .map { serverLanguages in LanguageMapper.matchSystemLanguage(to: serverLanguages, userDefinedLanguages: supportedLanguages.rawValue) }
                .eraseToAnyPublisher()
                .flatMap { currentUserLanguages -> DownloaderPublisher in
                    let message = "Mapped user language to the server languages. serverLanguage: \(currentUserLanguages.serverLanguage), systemLanguage: \(currentUserLanguages.systemLanguage)"
                    OwnID.CoreSDK.logger.log(.entry(level: .debug, message: message, OwnID.CoreSDK.TranslationsSDK.Downloader.self))
                    return self.downloadCurrentLocalizationFile(for: currentUserLanguages.serverLanguage, correspondingSystemLanguage: currentUserLanguages.systemLanguage)
                        .eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
        }
    }
}

private extension OwnID.CoreSDK.TranslationsSDK.Downloader {
    var basei18nURL: URL {
        if let env = OwnID.CoreSDK.shared.environment {
            return URL(string: "https://i18n.\(env).ownid.com")!
        }
        return URL(string: "https://i18n.prod.ownid.com")!
    }
    
    func valuesURL(currentLanguage: String) -> URL {
        basei18nURL.appendingPathComponent(currentLanguage).appendingPathComponent("mobile-sdk.json")
    }

    func downloadCurrentLocalizationFile(for currentBELanguage: String, correspondingSystemLanguage: String) -> DownloaderPublisher {
        return session.dataTaskPublisher(for: valuesURL(currentLanguage: currentBELanguage))
            .eraseToAnyPublisher()
            .map { $0.data }
            .compactMap {
                let result = try? JSONSerialization.jsonObject(with: $0, options: []) as? [String: Any]
                return result
            }
            .map { translationsObject -> [String: String] in
                var flatTranslationDict = [String: String]()
                self.flattenOutObject(translationsObject, &flatTranslationDict)
                return flatTranslationDict
            }
            .map { (correspondingSystemLanguage, $0) }
            .mapError {
                OwnID.CoreSDK.CoreErrorLogWrapper.coreLog(entry: .errorEntry(Self.self), error: .localizationDownloader(underlying: $0))
            }
            .eraseToAnyPublisher()
    }
    
    func flattenOutObject(_ translationsObject: [String : Any], _ flatTranslationDict: inout [String : String]) {
        for topKey in translationsObject.keys {
            if let flatTranslation = translationsObject[topKey] as? String {
                flatTranslationDict[topKey] = flatTranslation
            }
            if var translationObject = translationsObject[topKey] as? [String: Any] {
                for (key, _) in translationObject {
                    translationObject.switchKey(fromKey: key, toKey: "\(topKey).\(key)")
                }
                flattenOutObject(translationObject, &flatTranslationDict)
            }
        }
    }
}

private extension Dictionary {
    mutating func switchKey(fromKey: Key, toKey: Key) {
        if let entry = removeValue(forKey: fromKey) {
            self[toKey] = entry
        }
    }
}
