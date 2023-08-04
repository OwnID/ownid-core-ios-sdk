import SwiftUI
import Combine

/// OwnID class represents core part of SDK. It performs initialization and creates views. It reads OwnIDConfiguration from disk, parses it and loads to memory for later usage. It is a singleton, so the URL returned from outside can be linked to corresponding flow.
public extension OwnID {    
    final class CoreSDK {
        public var serverConfigurationURL: ServerURL? { store.value.firstConfiguration?.ownIDServerConfigurationURL }
        
        public func enableLogging() {
            OwnID.CoreSDK.logger.isEnabled = true
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
        
        public static var logger = InternalLogger.shared
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
        
        public static func setSupportedLanguages(_ supportedLanguages: [String]) {
            shared.translationsModule.setSupportedLanguages(supportedLanguages)
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
            OwnID.CoreSDK.logger.log(level: .debug, message: "\(url.absoluteString)", Self.self)
            let redirectParamKey = "redirect"
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
            let redirectParameterValue = components?.first(where: { $0.name == redirectParamKey })?.value
            if redirectParameterValue == "false" {
                let message = OwnID.CoreSDK.ErrorMessage.redirectParameterFromURLCancelledOpeningSDK
                urlPublisher.send(completion: .failure(.coreLog(error: .userError(errorModel: UserErrorModel(message: message)), type: Self.self)))
                return
            }
            
            guard let redirection = store.value.getOptionalConfiguration(for: sdkConfigurationName),
                  let redirectionUrl = redirection.redirectionURL?.lowercased(),
                  url.absoluteString.lowercased().starts(with: redirectionUrl)
            else {
                let message = OwnID.CoreSDK.ErrorMessage.notValidRedirectionURLOrNotMatchingFromConfiguration
                urlPublisher.send(completion: .failure(.coreLog(error: .userError(errorModel: UserErrorModel(message: message)), type: Self.self)))
                return
            }
            urlPublisher.send(())
        }
    }
}
