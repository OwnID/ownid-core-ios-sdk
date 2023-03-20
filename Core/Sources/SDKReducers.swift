import Foundation
import Combine

extension OwnID.CoreSDK {
    static func coreReducer(state: inout SDKState, action: SDKAction) -> [Effect<SDKAction>] {
        switch action {
        case let .configure(appID,
                            redirectionURL,
                            userFacingSDK,
                            underlyingSDKs,
                            isTestingEnvironment,
                            environment,
                            supportedLanguages):
            state.supportedLanguages = supportedLanguages
            return [createConfiguration(appID: appID,
                                        redirectionURL: redirectionURL,
                                        userFacingSDK: userFacingSDK,
                                        underlyingSDKs: underlyingSDKs,
                                        isTestingEnvironment: isTestingEnvironment,
                                        environment: environment)]
            
        case let .configurationCreated(configuration, userFacingSDK, underlyingSDKs, isTestingEnvironment):
            return [
                fetchServerConfiguration(config: configuration,
                                         userFacingSDK: userFacingSDK),
                startLoggerIfNeeded(userFacingSDK: userFacingSDK,
                                    underlyingSDKs: underlyingSDKs,
                                    isTestingEnvironment: isTestingEnvironment),
                translationsDownloaderSDKConfigured(with: state.supportedLanguages)
            ]
            
        case .startDebugLogger(let level):
            Logger.shared.logLevel = level
            state.isLoggingEnabled = true
            return []
            
        case .configureForTests:
            OwnID.startDebugConsoleLogger()
            return [testConfiguration()]
            
        case let .configureFromDefaultConfiguration(userFacingSDK, underlyingSDKs, supportedLanguages):
            let url = Bundle.main.url(forResource: "OwnIDConfiguration", withExtension: "plist")!
            return [Just(.configureFrom(plistUrl: url, userFacingSDK: userFacingSDK, underlyingSDKs: underlyingSDKs, supportedLanguages: supportedLanguages)).eraseToEffect()]
            
        case let .configureFrom(plistUrl, userFacingSDK, underlyingSDKs, supportedLanguages):
            state.supportedLanguages = supportedLanguages
            return [getDataFrom(plistUrl: plistUrl,
                                userFacingSDK: userFacingSDK,
                                underlyingSDKs: underlyingSDKs,
                                isTestingEnvironment: false)]
            
        case .save(let configurationLoadingEvent, let userFacingSDK):
            switch configurationLoadingEvent {
            case .loaded(let config):
                state.configurations[userFacingSDK.name] = config
                
            case .error:
                break
            }
            state.configurationLoadingEventPublisher.send(configurationLoadingEvent)
            return [
                translationsDownloaderSDKConfigured(with: state.supportedLanguages),
                sendLoggerSDKConfigured()
            ]
        }
    }
    
    private static func getDataFrom(plistUrl: URL,
                                    userFacingSDK: SDKInformation,
                                    underlyingSDKs: [SDKInformation],
                                    isTestingEnvironment: Bool) -> Effect<SDKAction> {
        let data = try! Data(contentsOf: plistUrl)
        let decoder = PropertyListDecoder()
        let config = try! decoder.decode(OwnID.CoreSDK.LocalConfiguration.self, from: data)
        let action = SDKAction.configurationCreated(configuration: config,
                                                    userFacingSDK: userFacingSDK,
                                                    underlyingSDKs: underlyingSDKs,
                                                    isTestingEnvironment: isTestingEnvironment)
        return Just(action).eraseToEffect()
    }
    
    private static func testConfiguration() -> Effect<SDKAction> {
        let action = SDKAction.configure(appID: "gephu5k2dnff2v",
                                         redirectionURL: "com.ownid.demo.gigya://ownid/redirect/",
                                         userFacingSDK: (OwnID.CoreSDK.sdkName, OwnID.CoreSDK.version),
                                         underlyingSDKs: [],
                                         isTestingEnvironment: true,
                                         environment: .none,
                                         supportedLanguages: .init(rawValue: Locale.preferredLanguages))
        return Just(action).eraseToEffect()
    }
    
    private static func createConfiguration(appID: OwnID.CoreSDK.AppID,
                                            redirectionURL: RedirectionURLString,
                                            userFacingSDK: SDKInformation,
                                            underlyingSDKs: [SDKInformation],
                                            isTestingEnvironment: Bool,
                                            environment: String?) -> Effect<SDKAction> {
        let config = try! OwnID.CoreSDK.LocalConfiguration(appID: appID,
                                                      redirectionURL: redirectionURL,
                                                      environment: environment)
        return Just(.configurationCreated(configuration: config,
                                          userFacingSDK: userFacingSDK,
                                          underlyingSDKs: underlyingSDKs,
                                          isTestingEnvironment: isTestingEnvironment))
        .eraseToEffect()
    }
    
    private static func startLoggerIfNeeded(userFacingSDK: SDKInformation,
                                            underlyingSDKs: [SDKInformation],
                                            isTestingEnvironment: Bool) -> Effect<SDKAction> {
        return .fireAndForget {
            OwnID.CoreSDK.UserAgentManager.shared.registerUserFacingSDKName(userFacingSDK, underlyingSDKs: underlyingSDKs)
            if !isTestingEnvironment {
                OwnID.CoreSDK.logger.add(OwnID.CoreSDK.MetricsLogger())
            }
            OwnID.CoreSDK.logger.logCore(.entry(OwnID.CoreSDK.self))
        }
    }
    
    private static func fetchServerConfiguration(config: LocalConfiguration,
                                                 userFacingSDK: OwnID.CoreSDK.SDKInformation) -> Effect<SDKAction> {
        let effect = Deferred { URLSession.shared.dataTaskPublisher(for: config.ownIDServerConfigurationURL)
                .retry(2)
                .map { data, _ in return data }
                .eraseToAnyPublisher()
                .decode(type: ServerConfiguration.self, decoder: JSONDecoder())
                .eraseToAnyPublisher()
                .replaceError(with: ServerConfiguration(isFailed: true, supportedLocales: [], logLevel: .error, fidoSettings: .none, passkeysAutofillEnabled: false, serverURL: URL(string: "https://ownid.com")!, redirectURLString: .none, platformSettings: .none))
                .eraseToAnyPublisher()
                .flatMap { serverConfiguration -> AnyPublisher<SDKAction, Never> in
                    if serverConfiguration.isFailed {
                        return Just(.save(configurationLoadingEvent: .error, userFacingSDK: userFacingSDK)).eraseToAnyPublisher()
                    }
                    Logger.shared.logLevel = serverConfiguration.logLevel
                    var local = config
                    local.serverURL = serverConfiguration.serverURL
                    local.redirectionURL = (serverConfiguration.platformSettings?.redirectUrlOverride ?? serverConfiguration.redirectURLString) ?? local.redirectionURL
                    local.fidoSettings = serverConfiguration.fidoSettings
                    local.passkeysAutofillEnabled = serverConfiguration.passkeysAutofillEnabled
                    local.supportedLocales = serverConfiguration.supportedLocales
                    return Just(.save(configurationLoadingEvent: .loaded(local), userFacingSDK: userFacingSDK)).eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
        }
        return effect.eraseToEffect()
    }
    
    private static func translationsDownloaderSDKConfigured(with supportedLanguages: OwnID.CoreSDK.Languages) -> Effect<SDKAction> {
        .fireAndForget {
            OwnID.CoreSDK.shared.translationsModule.SDKConfigured(supportedLanguages: supportedLanguages)
            OwnID.CoreSDK.logger.logCore(.entry(OwnID.CoreSDK.self))
        }
    }
    
    private static func sendLoggerSDKConfigured() -> Effect<SDKAction> {
        .fireAndForget {
            OwnID.CoreSDK.logger.sdkConfigured()
        }
    }
}
