
import Foundation

extension OwnID.CoreSDK {
    struct SDKState: LoggingEnabled {
        var isLoggingEnabled = false
        var configurations = [String: OwnID.CoreSDK.Configuration]()
    }
}

extension OwnID.CoreSDK.SDKState {
    var configurationName: String {
        configurations.first!.key
    }
    
    func getConfiguration(for sdkConfigurationName: String) -> OwnID.CoreSDK.Configuration {
        guard let config = configurations[sdkConfigurationName] else { fatalError("Configuration does not exist for name") }
        return config
    }
}
