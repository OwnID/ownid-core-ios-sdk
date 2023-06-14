import Foundation
import Combine

extension OwnID.CoreSDK.TranslationsSDK {
    enum TranslationKey: String {
        case skipPassword
        case tooltip = "tooltip-ios"
        case or
        case `continue`
        case verifyEmail = "steps.otp.title-verify"
        case signInWithOneTimeCode = "steps.otp.title-sign"
        case didNotGetEmail = "steps.otp.no-email"
        case otpDescription = "steps.otp.description"
        case otpSentEmail = "steps.otp.message"
        case emailCollectTitle = "steps.email-collect.title-ios"
        case emailCollectMessage = "steps.email-collect.message"
        case stepsContinue = "steps.continue"
        
        public func localized() -> String {
            if let bundle = OwnID.CoreSDK.shared.translationsModule.localizationBundle {
                let localizedString = bundle.localizedString(forKey: rawValue, value: rawValue, table: nil)
                return localizedString
            }
            return rawValue
        }
    }
}

extension OwnID.CoreSDK.TranslationsSDK {
    public final class Manager {
        public var localizationBundle: Bundle? {
            bundleManager.translationBundle
        }
        private let translationsChange = PassthroughSubject<Void, Never>()
        public var translationsChangePublisher: AnyPublisher<Void, Never> {
            translationsChange
                .receive(on: RunLoop.main)
                .eraseToAnyPublisher()
        }
        
        private let bundleManager = RuntimeLocalizableSaver()
        private let downloader = Downloader()
        private var notificationCenterCancellable: AnyCancellable?
        private var downloaderCancellable: AnyCancellable?
        private var supportedLanguages: OwnID.CoreSDK.Languages = .init(rawValue: [])
        
        init() {
            notificationCenterCancellable = NotificationCenter.default.publisher(for: NSLocale.currentLocaleDidChangeNotification)
                .sink { [weak self] notification in
                    let message = "Recieve notification about language change \(notification)"
                    OwnID.CoreSDK.logger.log(.entry(level: .debug, message: message, OwnID.CoreSDK.TranslationsSDK.Downloader.self))
                    if let value = self?.supportedLanguages.shouldChangeLanguageOnSystemLanguageChange, value {
                        self?.initializeLanguages(supportedLanguages: .init(rawValue: Locale.preferredLanguages))
                    }
                }
        }
        
        
        func SDKConfigured(supportedLanguages: OwnID.CoreSDK.Languages) {
            self.supportedLanguages = supportedLanguages
            initializeLanguages(supportedLanguages: supportedLanguages)
        }
        
        private func initializeLanguages(supportedLanguages: OwnID.CoreSDK.Languages) {
            downloaderCancellable = downloader.downloadTranslations(supportedLanguages: supportedLanguages)
                .tryMap { try self.bundleManager.save(languageKey: $0.systemLanguage, language: $0.language) }
                .sink { completion in
                    switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        OwnID.CoreSDK.logger.log(.entry(level: .error, message: error.localizedDescription, OwnID.CoreSDK.TranslationsSDK.Manager.self))
                    }
                } receiveValue: {
                    self.translationsChange.send(())
                    let message = "Translations downloaded and saved"
                    OwnID.CoreSDK.logger.log(.entry(level: .debug, message: message, OwnID.CoreSDK.TranslationsSDK.Manager.self))
                }
        }
    }
}
