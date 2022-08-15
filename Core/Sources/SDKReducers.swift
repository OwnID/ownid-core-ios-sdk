
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
                            environment):
            return [createConfiguration(appID: appID,
                                        redirectionURL: redirectionURL,
                                        userFacingSDK: userFacingSDK,
                                        underlyingSDKs: underlyingSDKs,
                                        isTestingEnvironment: isTestingEnvironment,
                                        environment: environment)]
            
        case let .configurationCreated(configuration, userFacingSDK, underlyingSDKs, isTestingEnvironment):
            state.configurations[userFacingSDK.name] = configuration
            let numberOfConfigurations = state.configurations.count
            return [
                fetchLogLevel(serverURL: configuration.ownIDServerURL, numberOfConfigurations: numberOfConfigurations),
                startLoggerIfNeeded(numberOfConfigurations: numberOfConfigurations,
                                    userFacingSDK: userFacingSDK,
                                    underlyingSDKs: underlyingSDKs,
                                    isTestingEnvironment: isTestingEnvironment),
                startTranslationsDownloader()
            ]
            
        case .startDebugLogger:
            state.isLoggingEnabled = true
            OwnID.startDebugConsoleLogger()
            return []
            
        case .configureForTests:
            return [testConfiguration(), Just(.startDebugLogger).eraseToEffect()]
            
        case let .configureFromDefaultConfiguration(userFacingSDK, underlyingSDKs):
            let url = Bundle.main.url(forResource: "OwnIDConfiguration", withExtension: "plist")!
            return [Just(.configureFrom(plistUrl: url, userFacingSDK: userFacingSDK, underlyingSDKs: underlyingSDKs)).eraseToEffect()]
            
        case let .configureFrom(plistUrl, userFacingSDK, underlyingSDKs):
            return [getDataFrom(plistUrl: plistUrl,
                                userFacingSDK: userFacingSDK,
                                underlyingSDKs: underlyingSDKs,
                                isTestingEnvironment: false)]
        }
    }
    
    private static func getDataFrom(plistUrl: URL, userFacingSDK: SDKInformation, underlyingSDKs: [SDKInformation], isTestingEnvironment: Bool) -> Effect<SDKAction> {
        let data = try! Data(contentsOf: plistUrl)
        let decoder = PropertyListDecoder()
        let config = try! decoder.decode(OwnID.CoreSDK.Configuration.self, from: data)
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
                                         environment: .none)
        return Just(action).eraseToEffect()
    }
    
    private static func createConfiguration(appID: String,
                                            redirectionURL: String,
                                            userFacingSDK: SDKInformation,
                                            underlyingSDKs: [SDKInformation],
                                            isTestingEnvironment: Bool,
                                            environment: String?) -> Effect<SDKAction> {
        let config = try! OwnID.CoreSDK.Configuration(appID: appID,
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
    
    private static func fetchLogLevel(serverURL: URL, numberOfConfigurations: Int) -> Effect<SDKAction> {
        guard numberOfConfigurations == 1 else { return .fireAndForget { } }
        let url = serverURL.appendingPathComponent("client-config")
        let effect = Deferred { URLSession.shared.dataTaskPublisher(for: url)
                .map { data, _ in  return data }
                .eraseToAnyPublisher()
                .decode(type: ServerLogLevel.self, decoder: JSONDecoder())
                .eraseToAnyPublisher()
                .replaceError(with: ServerLogLevel(logLevel: 4))
                .flatMap { serverLogLevel -> Empty<SDKAction, Never> in
                    Logger.shared.logLevel = LogLevel(rawValue: serverLogLevel.logLevel) ?? .error
                    return Empty(completeImmediately: true)
                }
                .eraseToAnyPublisher()
        }
        return  effect.eraseToEffect()
    }
                          
    struct ServerLogLevel: Decodable {
        let logLevel: Int
    }
    
    private static func startTranslationsDownloader() -> Effect<SDKAction> {
        .fireAndForget {
            OwnID.CoreSDK.shared.translationsModule.SDKConfigured()
            OwnID.CoreSDK.logger.logCore(.entry(OwnID.CoreSDK.self))
        }
    }
}
