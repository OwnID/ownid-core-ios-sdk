import Foundation

enum SDKAction {
    case configureFromDefaultConfiguration(userFacingSDK: OwnID.CoreSDK.SDKInformation, underlyingSDKs: [OwnID.CoreSDK.SDKInformation])
    case configureFrom(plistUrl: URL, userFacingSDK: OwnID.CoreSDK.SDKInformation, underlyingSDKs: [OwnID.CoreSDK.SDKInformation])
    case configure(appID: String,
                   redirectionURL: String,
                   userFacingSDK: OwnID.CoreSDK.SDKInformation,
                   underlyingSDKs: [OwnID.CoreSDK.SDKInformation],
                   isTestingEnvironment: Bool,
                   environment: String?)
    case configurationCreated(configuration: OwnID.CoreSDK.Configuration,
                              userFacingSDK: OwnID.CoreSDK.SDKInformation,
                              underlyingSDKs: [OwnID.CoreSDK.SDKInformation],
                              isTestingEnvironment: Bool)
    case startDebugLogger(logLevel: OwnID.CoreSDK.LogLevel)
    case configureForTests
    case save(clientCongfig: OwnID.CoreSDK.ClientConfiguration)
}
