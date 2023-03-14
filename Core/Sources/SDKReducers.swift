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
            let numberOfConfigurations = state.configurations.count
            return [
                fetchServerConfiguration(config: configuration,
                                         numberOfConfigurations: numberOfConfigurations,
                                         userFacingSDK: userFacingSDK),
                startLoggerIfNeeded(numberOfConfigurations: numberOfConfigurations,
                                    userFacingSDK: userFacingSDK,
                                    underlyingSDKs: underlyingSDKs,
                                    isTestingEnvironment: isTestingEnvironment),
                startTranslationsDownloader(supportedLanguages: state.supportedLanguages)
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
            
        case .save(let config, let userFacingSDK):
            state.configurationLoadedPublisher.send(config)
            state.configurations[userFacingSDK.name] = config
            return []
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
    
    private static func startLoggerIfNeeded(numberOfConfigurations: Int,
                                            userFacingSDK: SDKInformation,
                                            underlyingSDKs: [SDKInformation],
                                            isTestingEnvironment: Bool) -> Effect<SDKAction> {
        return .fireAndForget {
            if numberOfConfigurations == 1 {
                OwnID.CoreSDK.UserAgentManager.shared.registerUserFacingSDKName(userFacingSDK, underlyingSDKs: underlyingSDKs)
                if !isTestingEnvironment {
                    OwnID.CoreSDK.logger.add(OwnID.CoreSDK.MetricsLogger())
                }
            }
            OwnID.CoreSDK.logger.logCore(.entry(OwnID.CoreSDK.self))
        }
    }
    
    private static func fetchServerConfiguration(config: LocalConfiguration,
                                                 numberOfConfigurations: Int,
                                                 userFacingSDK: OwnID.CoreSDK.SDKInformation) -> Effect<SDKAction> {
        guard numberOfConfigurations == 1 else { return .fireAndForget { } }
        let effect = Deferred { URLSession.shared.dataTaskPublisher(for: config.ownIDServerConfigurationURL)
                .map { data, _ in return data }
                .eraseToAnyPublisher()
                .decode(type: ServerConfiguration.self, decoder: JSONDecoder())
                .eraseToAnyPublisher()
                .replaceError(with: ServerConfiguration(isFailed: true, supportedLocales: [], logLevel: .error, fidoSettings: .none, passkeysAutofillEnabled: false, serverURL: URL(string: "https://ownid.com")!, cacheTTL: 0, redirectURLString: .none, platformSettings: .none))
                .eraseToAnyPublisher()
                .flatMap { serverConfiguration -> AnyPublisher<SDKAction, Never> in
                    if serverConfiguration.isFailed {
                        return Just(.save(config: local, userFacingSDK: userFacingSDK)).eraseToAnyPublisher()
                    }
                    Logger.shared.logLevel = serverConfiguration.logLevel
                    var local = config
                    local.serverURL = serverConfiguration.serverURL
                    looo
                    return Just(.save(config: local, userFacingSDK: userFacingSDK)).eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
        }
        return effect.eraseToEffect()
    }
    
    private static func startTranslationsDownloader(supportedLanguages: OwnID.CoreSDK.Languages) -> Effect<SDKAction> {
        .fireAndForget {
            OwnID.CoreSDK.shared.translationsModule.SDKConfigured(supportedLanguages: supportedLanguages)
            OwnID.CoreSDK.logger.logCore(.entry(OwnID.CoreSDK.self))
        }
    }
}
