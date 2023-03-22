import Combine

extension OwnID.CoreSDK {
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
        let effect = Deferred {
            
            .replaceError(with: .mock(true))
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
