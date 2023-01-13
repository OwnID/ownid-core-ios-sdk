import Foundation
import Combine

extension String {
    public func ownIDLocalized() -> String {
        if let bundle = OwnID.CoreSDK.shared.translationsModule.localizationBundle {
            let localizedString = bundle.localizedString(forKey: self, value: self, table: nil)
            return localizedString
        }
        return self
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
        private var bag = Set<AnyCancellable>()
        
        init() {
            NotificationCenter.default.publisher(for: NSLocale.currentLocaleDidChangeNotification)
                .sink { [weak self] notification in
                        let message = "Recieve notification about language change \(notification)"
                        OwnID.CoreSDK.logger.logCore(.entry(message: message, OwnID.CoreSDK.TranslationsSDK.Downloader.self))
                    self?.initializeLanguages()
                }
                .store(in: &bag)
        }
        
        
        func SDKConfigured() {
            initializeLanguages()
        }
        
        private func initializeLanguages() {
            downloader.downloadTranslations()
                .tryMap { try self.bundleManager.save(languageKey: $0.systemLanguage, language: $0.language) }
                .sink { completion in
                    switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        OwnID.CoreSDK.logger.logCore(.errorEntry(message: error.localizedDescription, OwnID.CoreSDK.TranslationsSDK.Manager.self))
                    }
                } receiveValue: {
                    self.translationsChange.send(())
                    let message = "Translations downloaded and saved"
                    OwnID.CoreSDK.logger.logCore(.entry(message: message, OwnID.CoreSDK.TranslationsSDK.Manager.self))
                }
                .store(in: &bag)
        }
    }
}
