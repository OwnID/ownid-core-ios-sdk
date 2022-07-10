import Foundation
import Combine

extension OwnID.CoreSDK.TranslationsSDK.Downloader {
    struct SupportedLanguages: Codable {
        let langs: [String]
    }
}

extension OwnID.CoreSDK.TranslationsSDK {
    final class Downloader {
        typealias DownloaderPublisher = AnyPublisher<(systemLanguage: String, language: [String: String]), Error>
        
        private let session: URLSession
        
        init() {
            let config = URLSessionConfiguration.default
            config.requestCachePolicy = .useProtocolCachePolicy
            session = URLSession(configuration: config)
        }
        
        func downloadTranslations() -> DownloaderPublisher {
            downloadSupportedTranslationsList()
                .map { serverLanguages in LanguageMapper().matchSystemLanguage(to: serverLanguages) }
                .eraseToAnyPublisher()
                .flatMap { currentUserLanguages -> DownloaderPublisher in
                    let message = "Mapped user language to the server languages. serverLanguage: \(currentUserLanguages.serverLanguage), systemLanguage: \(currentUserLanguages.systemLanguage)"
                    OwnID.CoreSDK.logger.logCore(.entry(message: message, OwnID.CoreSDK.TranslationsSDK.Downloader.self))
                    return self.downloadCurrentLocalizationFile(for: currentUserLanguages.serverLanguage, correspondingSystemLanguage: currentUserLanguages.systemLanguage)
                        .eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
        }
    }
}

private extension OwnID.CoreSDK.TranslationsSDK.Downloader {
    var basei18nURL: URL {
        if OwnID.CoreSDK.shared.environment != nil {
            let dev_staging_uat_envMapper = "dev"
            return URL(string: "https://i18n.\(dev_staging_uat_envMapper).ownid.com")!
        }
        return URL(string: "https://i18n.prod.ownid.com")!
    }
    
    var langsURL: URL {
        basei18nURL.appendingPathComponent("langs.json")
    }
    
    func valuesURL(currentLanguage: String) -> URL {
        basei18nURL.appendingPathComponent(currentLanguage).appendingPathComponent("mobile-sdk.json")
    }
    
    func downloadSupportedTranslationsList() -> AnyPublisher<[String], Error> {
        return session.dataTaskPublisher(for: langsURL)
            .eraseToAnyPublisher()
            .map { $0.data }
            .eraseToAnyPublisher()
            .decode(type: SupportedLanguages.self, decoder: JSONDecoder())
            .map { $0.langs }
            .eraseToAnyPublisher()
    }
    
    func downloadCurrentLocalizationFile(for currentBELanguage: String, correspondingSystemLanguage: String) -> DownloaderPublisher {
        return session.dataTaskPublisher(for: valuesURL(currentLanguage: currentBELanguage))
            .eraseToAnyPublisher()
            .map { $0.data }
            .compactMap { try? JSONSerialization.jsonObject(with: $0, options: []) as? [String: String] }
            .map { (correspondingSystemLanguage, $0) }
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
}
