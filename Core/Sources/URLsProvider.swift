import Foundation

public protocol URLsProvider {
    func redirectionURL(for sdkConfigurationName: String) -> OwnID.CoreSDK.RedirectionURLString
    func serverURL(for sdkConfigurationName: String) -> OwnID.CoreSDK.ServerURL
}

extension OwnID.CoreSDK: URLsProvider { }

public extension OwnID.CoreSDK {
    func serverURL(for sdkConfigurationName: String) -> ServerURL {
        getConfiguration(for: sdkConfigurationName).ownIDServerURL
    }
    
    
    func redirectionURL(for sdkConfigurationName: String) -> RedirectionURLString {
        getConfiguration(for: sdkConfigurationName).redirectionURL
    }
}
