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

        case idCollectTitle(type: String)
        case idCollectContinue(type: String)
        case idCollectMessage(type: String)
        case idCollectError(type: String)
        case idCollectPlaceholder(type: String)
        case idCollectNoBiometricsTitle(type: String)
        case idCollectNoBiometricsMessage(type: String)
        
        case otpTitle(operationType: String, verificationType: String)
        case otpMessage(operationType: String, verificationType: String)
        case otpDescription(operationType: String, verificationType: String)
        case otpResend(operationType: String, verificationType: String)
        case otpNotYou(operationType: String, verificationType: String)

        var defaultValue: String {
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
            case .idCollectPlaceholder(let loginId):
                return "steps.login-id-collect.\(loginId).placeholder"
            case .idCollectNoBiometricsTitle(let loginId):
                return "steps.login-id-collect.\(loginId).no-biometrics.title-ios"
            case .idCollectNoBiometricsMessage(let loginId):
                return "steps.login-id-collect.\(loginId).no-biometrics.message"
            case .otpTitle(let operationType, let verificationType):
                if operationType == "sign" {
                    return "steps.otp.sign.title-ios"
                }
                return "steps.otp.verify.\(verificationType).title-ios"
            case .otpMessage(_, let type):
                return "steps.otp.\(type).message"
            case .otpDescription:
                return "steps.otp.description"
            case .otpResend(_, let type):
                return "steps.otp.\(type).resend"
            case .otpNotYou:
                return "steps.otp.not-you"
            }
        }
        
        var value: String? {
            switch self {
            case .skipPassword:
                return OwnID.CoreSDK.shared.translationsModule.localizedString(for: "widgets", "sbs-button", "skipPassword")
            case .tooltip:
                return OwnID.CoreSDK.shared.translationsModule.localizedString(for: "widgets", "sbs-button", "tooltip")
            case .or:
                return OwnID.CoreSDK.shared.translationsModule.localizedString(for: "widgets", "sbs-button", "or")
            case .`continue`:
                return OwnID.CoreSDK.shared.translationsModule.localizedString(for: "widgets", "auth-button", "message")
            case .stepsContinue:
                return OwnID.CoreSDK.shared.translationsModule.localizedString(for: "steps", "continue")
            case .stepsCancel:
                return OwnID.CoreSDK.shared.translationsModule.localizedString(for: "steps", "cancel")
            case .stepsError:
                return OwnID.CoreSDK.shared.translationsModule.localizedString(for: "steps", "error")
            case .idCollectTitle(let loginId):
                return OwnID.CoreSDK.shared.translationsModule.localizedString(for: "steps", "login-id-collect", loginId, "title")
            case .idCollectContinue(let loginId):
                return OwnID.CoreSDK.shared.translationsModule.localizedString(for: "steps", "login-id-collect", loginId, "cta")
            case .idCollectMessage(let loginId):
                return OwnID.CoreSDK.shared.translationsModule.localizedString(for: "steps", "login-id-collect", loginId, "message")
            case .idCollectError(let loginId):
                return OwnID.CoreSDK.shared.translationsModule.localizedString(for: "steps", "login-id-collect", loginId, "error")
            case .idCollectPlaceholder(let loginId):
                return OwnID.CoreSDK.shared.translationsModule.localizedString(for: "steps", "login-id-collect", loginId, "no-biometrics", "placeholder")
            case .idCollectNoBiometricsTitle(let loginId):
                return OwnID.CoreSDK.shared.translationsModule.localizedString(for: "steps", "login-id-collect", loginId, "no-biometrics", "title")
            case .idCollectNoBiometricsMessage(let loginId):
                return OwnID.CoreSDK.shared.translationsModule.localizedString(for: "steps", "login-id-collect", loginId, "no-biometrics", "message")
            case .otpTitle(let operationType, let verificationType):
                return OwnID.CoreSDK.shared.translationsModule.localizedString(for: "steps", "otp", operationType, verificationType, "title")
            case .otpMessage(let operationType, let verificationType):
                return OwnID.CoreSDK.shared.translationsModule.localizedString(for: "steps", "otp", verificationType, operationType, "message")
            case .otpDescription(let operationType, let verificationType):
                return OwnID.CoreSDK.shared.translationsModule.localizedString(for: "steps", "otp", verificationType, operationType, "description")
            case .otpResend(let operationType, let verificationType):
                return OwnID.CoreSDK.shared.translationsModule.localizedString(for: "steps", "otp", verificationType, operationType, "resend")
            case .otpNotYou(let operationType, let verificationType):
                return OwnID.CoreSDK.shared.translationsModule.localizedString(for: "steps", "otp", verificationType, operationType, "not-you")
            }
        }

        public func localized() -> String {
            if let localizedString = value {
                return localizedString
            }
            return NSLocalizedString(defaultValue, bundle: Bundle.resourceBundle, comment: "")
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
        
        private let localizableSaver = RuntimeLocalizableSaver()
        private let downloader = Downloader()
        private var notificationCenterCancellable: AnyCancellable?
        private var downloaderCancellable: AnyCancellable?
        private var supportedLanguages: OwnID.CoreSDK.Languages = .init(rawValue: [])
        
        init() {
            notificationCenterCancellable = NotificationCenter.default.publisher(for: NSLocale.currentLocaleDidChangeNotification)
                .sink { [weak self] notification in
                    let message = "Recieve notification about language change \(notification)"
                    OwnID.CoreSDK.logger.log(level: .debug, message: message, OwnID.CoreSDK.TranslationsSDK.Downloader.self)
                    if let value = self?.supportedLanguages.shouldChangeLanguageOnSystemLanguageChange, value {
                        self?.initializeLanguagesIfNeeded(supportedLanguages: .init(rawValue: Locale.preferredLanguages), shouldNotify: true)
                    }
                }
        }
        
        public func localizedString(for keys: String...) -> String? {
            if CacheManager.isExpired() {
                initializeLanguagesIfNeeded(supportedLanguages: .init(rawValue: Locale.preferredLanguages), shouldNotify: false)
            }

            return localizableSaver.localizedString(for: keys)
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
                .tryMap { try self.localizableSaver.save(languageKey: $0.systemLanguage, languageJson: $0.languageJson) }
                .sink { completion in
                    switch completion {
                    case .finished:
                        self.requestsTagsInProgress.removeAll()
                        break
                    case .failure(let error):
                        OwnID.CoreSDK.logger.log(level: .error, message: error.localizedDescription, OwnID.CoreSDK.TranslationsSDK.Manager.self)
                    }
                } receiveValue: {
                    if shouldNotify {
                        self.translationsChange.send(())
                    }
                    let message = "Translations downloaded and saved"
                    OwnID.CoreSDK.logger.log(level: .debug, message: message, OwnID.CoreSDK.TranslationsSDK.Manager.self)
                }
        }
    }
}
