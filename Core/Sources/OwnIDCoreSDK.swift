import SwiftUI
import Combine

public extension OwnID.CoreSDK {
    static let sdkName = String(describing: OwnID.CoreSDK.self)
    static let version = "2.2.0"
    static let APIVersion = "1"
}

/// OwnID class represents core part of SDK. It performs initialization and creates views. It reads OwnIDConfiguration from disc, parses it and loads to memory for later usage. It is a singleton so the URL returned from browser can be linked to corresponding view.
public extension OwnID {
    
    static func startDebugConsoleLogger(logLevel: OwnID.CoreSDK.LogLevel = .error) {
        OwnID.CoreSDK.logger.add(OwnID.CoreSDK.OSLogger())
        OwnID.CoreSDK.shared.enableLogging(logLevel: logLevel)
    }
    
    final class CoreSDK {
        public var serverURL: ServerURL {
            getConfiguration(for: configurationName).ownIDServerURL
        }
        
        func enableLogging(logLevel: OwnID.CoreSDK.LogLevel) {
            store.send(.startDebugLogger(logLevel: logLevel))
        }
        
        public static let shared = CoreSDK()
        public let translationsModule = TranslationsSDK.Manager()
        
        public var currentMetricInformation = OwnID.CoreSDK.StandardMetricLogEntry.CurrentMetricInformation()
        
        @ObservedObject var store: Store<SDKState, SDKAction>
        
        private let urlPublisher = PassthroughSubject<Void, OwnID.CoreSDK.CoreErrorLogWrapper>()
        private let configurationLoadedPublisher = PassthroughSubject<ClientConfiguration, Never>()
        
        private init() {
            let store = Store(
                initialValue: SDKState(configurationLoadedPublisher: configurationLoadedPublisher),
                reducer: with(
                    OwnID.CoreSDK.coreReducer,
                    logging
                )
            )
            self.store = store
        }
        
        public var isSDKConfigured: Bool { !store.value.configurations.isEmpty }
        
        var configurationName: String { store.value.configurationName }
        
        public static var logger: LoggerProtocol { Logger.shared }
        
        public func configureForTests() {
            store.send(.configureForTests)
        }
        
        public func configure(userFacingSDK: SDKInformation, underlyingSDKs: [SDKInformation]) {
            store.send(.configureFromDefaultConfiguration(userFacingSDK: userFacingSDK, underlyingSDKs: underlyingSDKs))
        }
        
        func subscribeForURL(coreViewModel: CoreViewModel) {
            coreViewModel.subscribeToURL(publisher: urlPublisher.eraseToAnyPublisher())
        }
        
        public func configure(appID: String,
                              redirectionURL: String,
                              userFacingSDK: SDKInformation,
                              underlyingSDKs: [SDKInformation],
                              environment: String? = .none) {
            store.send(.configure(appID: appID,
                                  redirectionURL: redirectionURL,
                                  userFacingSDK: userFacingSDK,
                                  underlyingSDKs: underlyingSDKs,
                                  isTestingEnvironment: false,
                                  environment: environment))
        }
        
        public func configureFor(plistUrl: URL, userFacingSDK: SDKInformation, underlyingSDKs: [SDKInformation]) {
            store.send(.configureFrom(plistUrl: plistUrl, userFacingSDK: userFacingSDK, underlyingSDKs: underlyingSDKs))
        }
        
        func getConfiguration(for sdkConfigurationName: String) -> Configuration {
            store.value.getConfiguration(for: sdkConfigurationName)
        }
        
        /// Starts registration flow
        /// - Parameters:
        ///   - email: Used in plugin SDKs to find identity in web app FIDO2 storage and to display it for login
        ///   - sdkConfigurationName: Name of current running SDK
        ///   - supportedLanguages: Languages for web view. List of well-formed [IETF BCP 47 language tag](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Accept-Language) .
        /// - Returns: View that is presented in sheet
        func createCoreViewModelForRegister(email: Email? = .none,
                                            sdkConfigurationName: String,
                                            supportedLanguages: OwnID.CoreSDK.Languages) -> CoreViewModel {
            let session = apiSession(configurationName: sdkConfigurationName, supportedLanguages: supportedLanguages)
            let viewModel = CoreViewModel(type: .register,
                                          email: email,
                                          token: .none,
                                          session: session,
                                          sdkConfigurationName: sdkConfigurationName,
                                          isLoggingEnabled: store.value.isLoggingEnabled,
                                          clientConfiguration: store.value.clientConfiguration)
            viewModel.subscribeToURL(publisher: urlPublisher.eraseToAnyPublisher())
            viewModel.subscribeToConfiguration(publisher: configurationLoadedPublisher.eraseToAnyPublisher())
            return viewModel
        }
        
        /// Starts login flow
        /// - Parameters:
        ///   - email: Used in plugin SDKs to find identity in web app FIDO2 storage and to display it for login
        ///   - sdkConfigurationName: Name of current running SDK
        ///   - supportedLanguages: Languages for web view. List of well-formed [IETF BCP 47 language tag](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Accept-Language) .
        /// - Returns: View that is presented in sheet
        func createCoreViewModelForLogIn(email: Email? = .none,
                                         sdkConfigurationName: String,
                                         supportedLanguages: OwnID.CoreSDK.Languages) -> CoreViewModel {
            let session = apiSession(configurationName: sdkConfigurationName, supportedLanguages: supportedLanguages)
            let viewModel = CoreViewModel(type: .login,
                                          email: email,
                                          token: .none,
                                          session: session,
                                          sdkConfigurationName: sdkConfigurationName,
                                          isLoggingEnabled: store.value.isLoggingEnabled,
                                          clientConfiguration: store.value.clientConfiguration)
            viewModel.subscribeToURL(publisher: urlPublisher.eraseToAnyPublisher())
            viewModel.subscribeToConfiguration(publisher: configurationLoadedPublisher.eraseToAnyPublisher())
            return viewModel
        }
        
        func apiSession(configurationName: String, supportedLanguages: OwnID.CoreSDK.Languages) -> APISessionProtocol {
            APISession(serverURL: serverURL(for: configurationName),
                       statusURL: statusURL(for: configurationName),
                       settingsURL: settingURL(for: configurationName),
                       authURL: authURL(for: configurationName),
                       supportedLanguages: supportedLanguages)
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
            
            guard url
                .absoluteString
                .lowercased()
                .starts(with: getConfiguration(for: sdkConfigurationName)
                    .redirectionURL
                    .lowercased())
            else {
                urlPublisher.send(completion: .failure(.coreLog(entry: .errorEntry(Self.self), error: .notValidRedirectionURLOrNotMatchingFromConfiguration)))
                return
            }
            urlPublisher.send(())
        }
    }
}

extension OwnID.CoreSDK {
    func statusURL(for sdkConfigurationName: String) -> ServerURL {
        getConfiguration(for: sdkConfigurationName).statusURL
    }
    
    func settingURL(for sdkConfigurationName: String) -> ServerURL {
        getConfiguration(for: sdkConfigurationName).settingURL
    }
    
    func authURL(for sdkConfigurationName: String) -> ServerURL {
        getConfiguration(for: sdkConfigurationName).authURL
    }
}

public extension OwnID.CoreSDK {
    var environment: String? {
        getConfiguration(for: configurationName).environment
    }
    
    var metricsURL: ServerURL {
        serverURL.deletingLastPathComponent().appendingPathComponent("events")
    }
}
