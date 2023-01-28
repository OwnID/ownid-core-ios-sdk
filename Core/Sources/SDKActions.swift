import Foundation

enum SDKAction {
    case configureFromDefaultConfiguration(userFacingSDK: OwnID.CoreSDK.SDKInformation,
                                           underlyingSDKs: [OwnID.CoreSDK.SDKInformation],
                                           supportedLanguages: OwnID.CoreSDK.Languages)
    case configureFrom(plistUrl: URL,
                       userFacingSDK: OwnID.CoreSDK.SDKInformation,
                       underlyingSDKs: [OwnID.CoreSDK.SDKInformation],
                       supportedLanguages: OwnID.CoreSDK.Languages)
    case configure(appID: OwnID.CoreSDK.AppID,
                   redirectionURL: OwnID.CoreSDK.RedirectionURLString,
                   userFacingSDK: OwnID.CoreSDK.SDKInformation,
                   underlyingSDKs: [OwnID.CoreSDK.SDKInformation],
                   isTestingEnvironment: Bool,
                   environment: String?,
                   supportedLanguages: OwnID.CoreSDK.Languages)
    case configurationCreated(configuration: OwnID.CoreSDK.Configuration,
                              userFacingSDK: OwnID.CoreSDK.SDKInformation,
                              underlyingSDKs: [OwnID.CoreSDK.SDKInformation],
                              isTestingEnvironment: Bool)
    case startDebugLogger(logLevel: OwnID.CoreSDK.LogLevel)
    case configureForTests
    case save(clientCongfig: OwnID.CoreSDK.ClientConfiguration)
}
