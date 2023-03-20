import SwiftUI
import Combine

public extension OwnID.CoreSDK {
    static let sdkName = String(describing: OwnID.CoreSDK.self)
    static let version = "2.2.0"
    static let APIVersion = "1"
}

extension OwnID.CoreSDK {
    enum ConfigurationLoadingEvent {
        case loaded(LocalConfiguration)
        case error
    }
}

/// OwnID class represents core part of SDK. It performs initialization and creates views. It reads OwnIDConfiguration from disk, parses it and loads to memory for later usage. It is a singleton, so the URL returned from outside can be linked to corresponding flow.
public extension OwnID {
    
    /// Turns on logs to console app & console
    static func startDebugConsoleLogger(logLevel: OwnID.CoreSDK.LogLevel = .error) {
        OwnID.CoreSDK.logger.add(OwnID.CoreSDK.OSLogger())
        OwnID.CoreSDK.shared.enableLogging(logLevel: logLevel)
    }
    
    final class CoreSDK {
        public var serverConfigurationURL: ServerURL? { store.value.firstConfiguration?.ownIDServerConfigurationURL }
        
        func enableLogging(logLevel: OwnID.CoreSDK.LogLevel) {
            store.send(.startDebugLogger(logLevel: logLevel))
        }
        
        public static let shared = CoreSDK()
        public let translationsModule = TranslationsSDK.Manager()
        
        public var currentMetricInformation = OwnID.CoreSDK.StandardMetricLogEntry.CurrentMetricInformation()
        
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
        
        public func configureForTests() {
            store.send(.configureForTests)
        }
        
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
        
        func createCoreViewModelForRegister(email: Email? = .none,
                                            sdkConfigurationName: String) -> CoreViewModel {
            let viewModel = CoreViewModel(type: .register,
                                          email: email,
                                          supportedLanguages: store.value.supportedLanguages,
                                          sdkConfigurationName: sdkConfigurationName,
                                          isLoggingEnabled: store.value.isLoggingEnabled,
                                          clientConfiguration: store.value.getOptionalConfiguration(for: sdkConfigurationName))
            viewModel.subscribeToURL(publisher: urlPublisher.eraseToAnyPublisher())
            viewModel.subscribeToConfiguration(publisher: configurationLoadingEventPublisher.eraseToAnyPublisher())
            return viewModel
        }
        
        func createCoreViewModelForLogIn(email: Email? = .none,
                                         sdkConfigurationName: String) -> CoreViewModel {
            let viewModel = CoreViewModel(type: .login,
                                          email: email,
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
            OwnID.CoreSDK.logger.logCore(.entry(message: "\(url.absoluteString)", Self.self))
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

public extension OwnID.CoreSDK {
    var environment: String? {
        store.value.firstConfiguration?.environment
    }
    
    var metricsURL: ServerURL? {
        store.value.firstConfiguration?.metricsURL
    }
    
    var supportedLocales: [String]? {
        store.value.firstConfiguration?.supportedLocales
    }
}
