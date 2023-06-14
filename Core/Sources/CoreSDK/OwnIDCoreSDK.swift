import SwiftUI
import Combine

/// OwnID class represents core part of SDK. It performs initialization and creates views. It reads OwnIDConfiguration from disk, parses it and loads to memory for later usage. It is a singleton, so the URL returned from outside can be linked to corresponding flow.
public extension OwnID {
    
    /// Turns on logs to console app & console
    static func startDebugConsoleLogger(logLevel: OwnID.CoreSDK.LogLevel = .error) {
        OwnID.CoreSDK.logger.add(OwnID.CoreSDK.OSLogger(level: logLevel))
        OwnID.CoreSDK.shared.enableLogging()
    }
    
    final class CoreSDK {
        public var serverConfigurationURL: ServerURL? { store.value.firstConfiguration?.ownIDServerConfigurationURL }
        
        func enableLogging() {
            store.send(.startDebugLogger)
        }
        
        public static let shared = CoreSDK()
        public let translationsModule = TranslationsSDK.Manager()
        
        public var currentMetricInformation = OwnID.CoreSDK.CurrentMetricInformation()
        
        @ObservedObject var store: Store<SDKState, SDKAction>
        
        private let urlPublisher = PassthroughSubject<Void, OwnID.CoreSDK.CoreErrorLogWrapper>()
        private let configurationLoadingEventPublisher = PassthroughSubject<ConfigurationLoadingEvent, Never>()
        
        private init() {
            let store = Store(
                initialValue: SDKState(configurationLoadingEventPublisher: configurationLoadingEventPublisher),
                reducer: with(
                    OwnID.CoreSDK.coreReducer,
                    logging
                )
            )
            self.store = store
        }
        
        public var isSDKConfigured: Bool { !store.value.configurations.isEmpty }
        
        public static var logger: LoggerProtocol { Logger.shared }
        public static var eventService: EventService { EventService.shared }
        
        public func configureForTests() { store.send(.configureForTests) }
        
        public func requestConfiguration() { store.send(.fetchServerConfiguration) }
        
        public func configure(userFacingSDK: SDKInformation,
                              underlyingSDKs: [SDKInformation],
                              supportedLanguages: OwnID.CoreSDK.Languages) {
            store.send(.configureFromDefaultConfiguration(userFacingSDK: userFacingSDK,
                                                          underlyingSDKs: underlyingSDKs,
                                                          supportedLanguages: supportedLanguages))
        }
        
        func subscribeForURL(coreViewModel: CoreViewModel) {
            coreViewModel.subscribeToURL(publisher: urlPublisher.eraseToAnyPublisher())
        }
        
        public func configure(appID: OwnID.CoreSDK.AppID,
                              redirectionURL: RedirectionURLString,
                              userFacingSDK: SDKInformation,
                              underlyingSDKs: [SDKInformation],
                              environment: String? = .none,
                              supportedLanguages: OwnID.CoreSDK.Languages) {
            store.send(.configure(appID: appID,
                                  redirectionURL: redirectionURL,
                                  userFacingSDK: userFacingSDK,
                                  underlyingSDKs: underlyingSDKs,
                                  isTestingEnvironment: false,
                                  environment: environment,
                                  supportedLanguages: supportedLanguages))
        }
        
        public func configureFor(plistUrl: URL,
                                 userFacingSDK: SDKInformation,
                                 underlyingSDKs: [SDKInformation],
                                 supportedLanguages: OwnID.CoreSDK.Languages) {
            store.send(.configureFrom(plistUrl: plistUrl,
                                      userFacingSDK: userFacingSDK,
                                      underlyingSDKs: underlyingSDKs,
                                      supportedLanguages: supportedLanguages))
        }
        
        func createCoreViewModelForRegister(loginId: String,
                                            sdkConfigurationName: String) -> CoreViewModel {
            let viewModel = CoreViewModel(type: .register,
                                          loginId: loginId,
                                          supportedLanguages: store.value.supportedLanguages,
                                          sdkConfigurationName: sdkConfigurationName,
                                          isLoggingEnabled: store.value.isLoggingEnabled,
                                          clientConfiguration: store.value.getOptionalConfiguration(for: sdkConfigurationName))
            viewModel.subscribeToURL(publisher: urlPublisher.eraseToAnyPublisher())
            viewModel.subscribeToConfiguration(publisher: configurationLoadingEventPublisher.eraseToAnyPublisher())
            return viewModel
        }
        
        func createCoreViewModelForLogIn(loginId: String,
                                         sdkConfigurationName: String) -> CoreViewModel {
            let viewModel = CoreViewModel(type: .login,
                                          loginId: loginId,
                                          supportedLanguages: store.value.supportedLanguages,
                                          sdkConfigurationName: sdkConfigurationName,
                                          isLoggingEnabled: store.value.isLoggingEnabled,
                                          clientConfiguration: store.value.getOptionalConfiguration(for: sdkConfigurationName))
            viewModel.subscribeToURL(publisher: urlPublisher.eraseToAnyPublisher())
            viewModel.subscribeToConfiguration(publisher: configurationLoadingEventPublisher.eraseToAnyPublisher())
            return viewModel
        }
        
        /// Used to handle the redirects from browser after webapp is finished
        /// - Parameter url: URL returned from webapp after it has finished
        /// - Parameter sdkConfigurationName: Used to get proper data from configs in case of multiple SDKs
        public func handle(url: URL, sdkConfigurationName: String) {
            OwnID.CoreSDK.logger.log(.entry(level: .debug, message: "\(url.absoluteString)", Self.self))
            let redirectParamKey = "redirect"
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
            let redirectParameterValue = components?.first(where: { $0.name == redirectParamKey })?.value
            if redirectParameterValue == "false" {
                urlPublisher.send(completion: .failure(.coreLog(entry: .errorEntry(Self.self), error: .redirectParameterFromURLCancelledOpeningSDK)))
                return
            }
            
            guard let redirection = store.value.getOptionalConfiguration(for: sdkConfigurationName),
                  url.absoluteString.lowercased().starts(with: redirection.redirectionURL.lowercased())
            else {
                urlPublisher.send(completion: .failure(.coreLog(entry: .errorEntry(Self.self), error: .notValidRedirectionURLOrNotMatchingFromConfiguration)))
                return
            }
            urlPublisher.send(())
        }
    }
}
