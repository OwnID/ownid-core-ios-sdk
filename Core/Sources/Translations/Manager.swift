import Foundation
import Combine

extension OwnID.CoreSDK.TranslationsSDK {
    enum TranslationKey {
        case skipPassword
        case tooltip
        case or
        case `continue`

        case stepsContinue
        case stepsCancel
        case stepsError

        case idCollectTitle
        case idCollectContinue
        case idCollectMessage(type: String)
        case idCollectError(type: String)
        case idCollectNoBiometricsTitle(type: String)
        case idCollectNoBiometricsMessage(type: String)
        
        case otpVerifyTitle(type: String)
        case otpDescription
        case otpMessage(type: String)
        case otpNo(type: String)
        case otpSignTitle

        var value: String {
            switch self {
            case .skipPassword:
                return "widgets.sbs-button.skipPassword"
            case .tooltip:
                return "widgets.sbs-button.tooltip-ios"
            case .or:
                return "widgets.sbs-button.or"
            case .`continue`:
                return "widgets.auth-button.message"
            case .stepsContinue:
                return "steps.continue"
            case .stepsCancel:
                return "steps.cancel"
            case .stepsError:
                return "steps.error"
            case .idCollectTitle:
                return "steps.login-id-collect.title-ios"
            case .idCollectContinue:
                return "steps.login-id-collect.cta"
            case .idCollectMessage(let loginId):
                return "steps.login-id-collect.\(loginId).message"
            case .idCollectError(let loginId):
                return "steps.login-id-collect.\(loginId).error"
            case .idCollectNoBiometricsTitle(let loginId):
                return "steps.login-id-collect.\(loginId).no-biometrics.title"
            case .idCollectNoBiometricsMessage(let loginId):
                return "steps.login-id-collect.\(loginId).no-biometrics.message"
            case .otpVerifyTitle(let type):
                return "steps.otp.verify.\(type).title"
            case .otpDescription:
                return "steps.otp.description"
            case .otpMessage(let type):
                return "steps.otp.\(type).message"
            case .otpNo(let type):
                return "steps.otp.\(type).no"
            case .otpSignTitle:
                return "steps.otp.sign.title"
            }
        }

        public func localized() -> String {
            if let bundle = OwnID.CoreSDK.shared.translationsModule.localizationBundle(for: self.value) {
                let localizedString = bundle.localizedString(forKey: value, value: value, table: nil)
                return localizedString
            }
            return value
        }
    }
}

extension OwnID.CoreSDK.TranslationsSDK {
    final class CacheManager {
        private enum Constants {
            static let lastWriteDateKey = "lastWriteDate"
            static let expirationInterval = 10.0 * 60.0
        }
        
        private static var lastWriteDate: Date? {
            get {
                UserDefaults.standard.value(forKey: Constants.lastWriteDateKey) as? Date
            } set {
                UserDefaults.standard.set(newValue, forKey: Constants.lastWriteDateKey)
            }
        }
        
        static func isExpired() -> Bool {
            if let date = lastWriteDate {
                if (Date().timeIntervalSinceReferenceDate - date.timeIntervalSinceReferenceDate) > Constants.expirationInterval {
                    lastWriteDate = Date()
                    return true
                } else {
                    return false
                }
            } else {
                lastWriteDate = Date()
                return false
            }
        }
    }
}

extension OwnID.CoreSDK.TranslationsSDK {
    public final class Manager {
        private var requestsTagsInProgress: Set<String> = []
                
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
                        self?.initializeLanguagesIfNeeded(supportedLanguages: .init(rawValue: Locale.preferredLanguages), shouldNotify: true)
                    }
                }
        }
        
        public func localizationBundle(for key: String) -> Bundle? {
            if CacheManager.isExpired() {
                initializeLanguagesIfNeeded(supportedLanguages: .init(rawValue: Locale.preferredLanguages), shouldNotify: false)
            }
            
            return bundleManager.translationBundle(for: key)
        }
        
        func SDKConfigured(supportedLanguages: OwnID.CoreSDK.Languages) {
            self.supportedLanguages = supportedLanguages
            initializeLanguagesIfNeeded(supportedLanguages: supportedLanguages, shouldNotify: true)
        }
        
        private func initializeLanguagesIfNeeded(supportedLanguages: OwnID.CoreSDK.Languages, shouldNotify: Bool) {
            guard !requestsTagsInProgress.contains(supportedLanguages.rawValue.first ?? "") else {
                return
            }
            requestsTagsInProgress.insert(supportedLanguages.rawValue.first ?? "")
            
            downloaderCancellable = downloader.downloadTranslations(supportedLanguages: supportedLanguages)
                .tryMap { try self.bundleManager.save(languageKey: $0.systemLanguage, language: $0.language) }
                .sink { completion in
                    switch completion {
                    case .finished:
                        self.requestsTagsInProgress.removeAll()
                        break
                    case .failure(let error):
                        OwnID.CoreSDK.logger.log(.entry(level: .error, message: error.localizedDescription, OwnID.CoreSDK.TranslationsSDK.Manager.self))
                    }
                } receiveValue: {
                    if shouldNotify {
                        self.translationsChange.send(())
                    }
                    let message = "Translations downloaded and saved"
                    OwnID.CoreSDK.logger.log(.entry(level: .debug, message: message, OwnID.CoreSDK.TranslationsSDK.Manager.self))
                }
        }
    }
}
